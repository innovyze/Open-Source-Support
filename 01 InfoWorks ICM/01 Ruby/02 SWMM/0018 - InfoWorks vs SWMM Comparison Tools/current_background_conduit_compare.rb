# Access current and background networks
cn = WSApplication.current_network
bn = WSApplication.background_network

unless cn && bn
  puts "Error: Could not access current or background network."
  exit
end

hw_conduits = cn.row_objects('hw_conduit')
sw_conduits = bn.row_objects('sw_conduit')

if hw_conduits.empty? || sw_conduits.empty?
  puts "Error: No conduits found in one or both networks."
  exit
end

# Prompt for parameter selection.
# Note: The prompt includes options for:
#   1. Conduit Length  
#   2. Bottom Roughness N  
#   3. US Invert  
#   4. DS Invert  
#   5. Conduit Height  
#   6. DS Headloss Coeff  
#   7. US Headloss Coeff  
#   8. Compare All Common Parameters
result = WSApplication.prompt "Select a Link Parameter to Compare", [
  ['Conduit Length',         'Boolean', false],
  ['Bottom Roughness N',       'Boolean', false],
  ['US Invert',                'Boolean', false],
  ['DS Invert',                'Boolean', false],
  ['Conduit Height',           'Boolean', false],
  ['DS Headloss Coeff',        'Boolean', false],
  ['US Headloss Coeff',        'Boolean', false],
  ['Compare All Common Parameters', 'Boolean', true]
], false

unless result
  puts "Prompt canceled. No selection made."
  exit
end

# Determine flag from selection:
# The flag value is the 1-based index of the first 'true' value in the result,
# or defaults to 8 (i.e. "Compare All Common Parameters") if none is true.
flag = result.index(true)&.+(1) || 8

# Define parameter mapping for flags 1 through 7.
param_map = {
  1 => [:conduit_length,       :length],
  2 => [:bottom_roughness_N,   :mannings_n],
  3 => [:us_invert,            :us_invert],
  4 => [:ds_invert,            :ds_invert],
  5 => [:conduit_height,       :conduit_height],
  6 => [:ds_headloss_coeff,    :ds_headloss_coeff],
  7 => [:us_headloss_coeff,    :us_headloss_coeff]
}

# Helper method with explicit conversion and nil handling for statistics
def calc_stats(values, label)
  return "#{label}: N/A (no valid data)" if values.empty?
  # Convert values to floats for calculations
  numeric_values = values.map { |v| v.to_f }
  mean = numeric_values.sum / numeric_values.size
  max = numeric_values.max || 'N/A'
  min = numeric_values.min || 'N/A'
  "#{label}: Mean=#{mean.round(3)}, Max=#{max}, Min=#{min}"
end

if flag.between?(1, 7)
  # If one of the single parameter options is selected:
  hw_param, sw_param = param_map[flag]
  # Convert symbols to strings for field access
  hw_param_str = hw_param.to_s
  sw_param_str = sw_param.to_s

  hw_values = hw_conduits.map { |c| c[hw_param_str] }.compact
  sw_values = sw_conduits.map { |c| c[sw_param_str] }.compact

  # Compare parameters for conduits matched by node IDs, converting each value to float
  diffs = hw_conduits.select do |h|
    s = sw_conduits.find { |s| s.us_node_id == h.us_node_id && s.ds_node_id == h.ds_node_id }
    s &&
      h[hw_param_str] && s[sw_param_str] &&
      ((h[hw_param_str].to_f - s[sw_param_str].to_f).abs > 0.01)
  end

  puts "Differences found in #{diffs.count} conduits"
  puts calc_stats(hw_values, "hw_#{hw_param}")
  puts calc_stats(sw_values, "sw_#{sw_param}")

elsif flag == 8
  # Compare all common parameters
  puts "Comparing all common parameters:"
  param_map.each do |f, (hw_p, sw_p)|
    hw_p_str = hw_p.to_s
    sw_p_str = sw_p.to_s

    hw_vals = hw_conduits.map { |c| c[hw_p_str] }.compact
    sw_vals = sw_conduits.map { |c| c[sw_p_str] }.compact

    diffs = hw_conduits.select do |h|
      s = sw_conduits.find { |s| s.us_node_id == h.us_node_id && s.ds_node_id == h.ds_node_id }
      s &&
        h[hw_p_str] && s[sw_p_str] &&
        ((h[hw_p_str].to_f - s[sw_p_str].to_f).abs > 0.01)
    end

    puts "\nFlag #{f} - #{hw_p} vs #{sw_p}:"
    puts "Differences found in #{diffs.count} conduits"
    puts calc_stats(hw_vals, "hw_#{hw_p}")
    puts calc_stats(sw_vals, "sw_#{sw_p}")
  end

else
  puts "Error: Invalid flag value (#{flag}). This should not occur."
end