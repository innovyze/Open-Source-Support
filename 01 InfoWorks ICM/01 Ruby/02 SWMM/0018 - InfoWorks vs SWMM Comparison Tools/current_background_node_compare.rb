# Access current and background networks
cn = WSApplication.current_network
bn = WSApplication.background_network

unless cn && bn
  puts "Error: Could not access current or background network."
  exit
end

# Read nodes from the respective tables
hw_nodes = cn.row_objects('hw_node')
sw_nodes = bn.row_objects('sw_node')

if hw_nodes.empty? || sw_nodes.empty?
  puts "Error: No nodes found in one or both networks."
  exit
end

# Prompt for node parameter selection.
# The options now include a new comparison: Chamber Floor vs Invert Elevation.
result = WSApplication.prompt "Select a Node Parameter to Compare", [
  ['X',                        'Boolean', false],
  ['Y',                        'Boolean', false],
  ['Ground Level',             'Boolean', false],
  ['Flooding Discharge Coeff', 'Boolean', false],
  ['Chamber Floor vs Invert Elevation', 'Boolean', false],
  ['Compare All Common Parameters', 'Boolean', true]
], false

unless result
  puts "Prompt canceled. No selection made."
  exit
end

# Determine flag from selection:
# The flag value is the 1-based index of the first true value in the result,
# or defaults to 6 (i.e. "Compare All Common Parameters") if none is true.
flag = result.index(true)&.+(1) || 6

# Define parameter mapping for flags 1 through 5.
# Each mapping is given as a pair: [hw_field, sw_field]
param_map = {
  1 => [:x, :x],
  2 => [:y, :y],
  3 => [:ground_level, :ground_level],
  4 => [:flooding_discharge_coeff, :flooding_discharge_coeff],
  5 => [:chamber_floor, :invert_elevation]
}

# Helper method with explicit conversion and nil handling for statistics.
def calc_stats(values, label)
  return "#{label}: N/A (no valid data)" if values.empty?
  numeric_values = values.map { |v| v.to_f }
  mean = numeric_values.sum / numeric_values.size
  max = numeric_values.max || 'N/A'
  min = numeric_values.min || 'N/A'
  "#{label}: Mean=#{mean.round(3)}, Max=#{max}, Min=#{min}"
end

# For node matching, we'll match nodes by their node_id.
if flag.between?(1, 5)
  hw_param, sw_param = param_map[flag]
  hw_field = hw_param.to_s
  sw_field = sw_param.to_s

  hw_values = hw_nodes.map { |n| n[hw_field] }.compact
  sw_values = sw_nodes.map { |n| n[sw_field] }.compact

  diffs = hw_nodes.select do |h|
    s = sw_nodes.find { |s| s['node_id'].to_s == h['node_id'].to_s }
    s &&
      h[hw_field] && s[sw_field] &&
      ((h[hw_field].to_f - s[sw_field].to_f).abs > 0.01)
  end

  puts "Differences found in #{diffs.count} nodes for parameter #{hw_field}"
  puts calc_stats(hw_values, "hw_#{hw_field}")
  puts calc_stats(sw_values, "sw_#{sw_field}")

elsif flag == 6
  # Compare all common parameters defined in param_map
  puts "Comparing all common parameters:"
  param_map.each do |f, (hw_p, sw_p)|
    hw_field = hw_p.to_s
    sw_field = sw_p.to_s

    hw_vals = hw_nodes.map { |n| n[hw_field] }.compact
    sw_vals = sw_nodes.map { |n| n[sw_field] }.compact

    diffs = hw_nodes.select do |h|
      s = sw_nodes.find { |s| s['node_id'].to_s == h['node_id'].to_s }
      s &&
        h[hw_field] && s[sw_field] &&
        ((h[hw_field].to_f - s[sw_field].to_f).abs > 0.01)
    end

    puts "\nFlag #{f} - Comparing #{hw_field} vs #{sw_field}:"
    puts "Differences found in #{diffs.count} nodes"
    puts calc_stats(hw_vals, "hw_#{hw_field}")
    puts calc_stats(sw_vals, "sw_#{sw_field}")
  end

else
  puts "Error: Invalid flag value (#{flag}). This should not occur."
end