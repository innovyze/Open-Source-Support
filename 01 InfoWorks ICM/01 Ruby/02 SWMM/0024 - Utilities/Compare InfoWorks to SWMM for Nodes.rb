cn = WSApplication.current_network
bn = WSApplication.background_network
puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"
# Retrieve hw_nodes from cn
cn_nodes = cn.row_object_collection('hw_node')

# Retrieve sw_nodes from bn
bn_nodes = bn.row_object_collection('sw_node')
bn_options = bn.row_object_collection('sw_options')

val = WSApplication.prompt "Compare Infoworks HW Nodes to SWMM SW Nodes",
[
['hw_node ground_level    vs  sw_node ground_level','Boolean',false],
['hw_node chamber_floor   vs  sw_node invert_elevation','Boolean',false],
['hw_node flood_level     vs  sw_node surcharge_depth','Boolean',false],
['hw_node maximum_depth   vs  sw_node maximum_depth','Boolean',false],
['hw_node floodable_area  vs  sw_node ponded_area','Boolean',false],
['hw_node chamber_area    vs  sw_node min_surfarea','Boolean',false],
['hw_node shaft_area      vs  sw_node min_surfarea','Boolean',false],
["This tool compares selected attributes between", 'String'],   
["InfoWorks HW Nodes and SWMM SW Nodes.", 'String'],
["Select the attributes you want to compare", 'String'],   
["The comparison will be based on node IDs.", 'String'],   
["Results will show the values from both networks ", 'String'],   
["and their differences.", 'String']
], false

# Define attribute pairs
attribute_pairs = [
  ['ground_level', 'ground_level'],
  ['chamber_floor', 'invert_elevation'],
  ['flood_level', 'surcharge_depth'],
  ['maximum_depth', 'maximum_depth'],
  ['floodable_area', 'ponded_area'],
  ['chamber_area', 'min_surfarea'],
  ['shaft_area', 'min_surfarea']
]

# Loop through each val and perform comparison if true
val.each_with_index do |is_selected, index|
  next unless is_selected

  hw, sw = attribute_pairs[index]

  # Create a hash map for sw attribute by node_id
  bn_attributes = {}
  bn_nodes.each do |node|
    if sw == 'min_surfarea'
      bn_attributes[node.node_id] = 12.566
    elsif sw == 'surcharge_depth'
      surcharge_depth = node.surcharge_depth
      if surcharge_depth > 0.0
        bn_attributes[node.node_id] = surcharge_depth + node.invert_elevation
      else
        bn_attributes[node.node_id] = node.ground_level
      end
    else
      bn_attributes[node.node_id] = node[sw]
    end
  end

  # Initialize totals
  total_hw = 0.0
  total_sw = 0.0
  # Initialize counters
  below_threshold_count = 0
  total_comparisons = 0

  # Compare hw attribute from cn to sw attribute from bn using node_id
  cn_nodes.each do |node|
  node_id = node.node_id
  if hw == 'maximum_depth'
    hw_value = node.ground_level - node.chamber_floor
  else
    hw_value = node[hw]
  end

  if bn_attributes.key?(node_id)
    sw_value = bn_attributes[node_id]
    # Ensure hw_value and sw_value are not nil
    hw_value = hw_value.nil? ? 0.0 : hw_value
    sw_value = sw_value.nil? ? 0.0 : sw_value

    # Format hw_value and sw_value
    formatted_hw_value = format('%10.4f', hw_value)
    formatted_sw_value = format('%10.4f', sw_value)

    # Calculate the absolute difference percentage
    difference_percentage = ((hw_value - sw_value).abs / ((hw_value + sw_value) / 2.0)) * 100

    # Increment total comparisons counter
    total_comparisons += 1

    # Increment counter if the absolute difference percentage is below 0.1 percent
    if difference_percentage <= 0.1
      below_threshold_count += 1
    end

    # Print only if the absolute difference percentage is more than 0.1 percent
    if difference_percentage > 0.1
      puts "Node ID: #{node_id.slice(0, 25).ljust(25)} CN #{hw.capitalize}: #{formatted_hw_value}, BN #{sw.capitalize}: #{formatted_sw_value}"
    end

    # Update totals with nil checks
    total_hw += hw_value unless hw_value.nil?
    total_sw += sw_value unless sw_value.nil?
  else
    puts "Node ID: #{node_id.slice(0, 25).ljust(25)} not found in bn"
  end
end

# Calculate the percentage of comparisons below 0.1 percent
percentage_below_threshold = (below_threshold_count.to_f / total_comparisons) * 100

# Print totals
puts "CN node.#{hw}:".ljust(30) + format('%.4f', total_hw).rjust(10)
puts "BN node.#{sw}:".ljust(30) + format('%.4f', total_sw).rjust(10)
puts "Difference:".ljust(30) + format('%.4f', total_hw - total_sw).rjust(10)

# Print the count of comparisons below 0.1 percent, total comparisons, and percentage below 0.1 percent
puts "Number of comparisons below 0.1 percent    : #{below_threshold_count}"
puts "Total number of comparisons                : #{total_comparisons}"
puts "Percentage of comparisons below 0.1 percent: #{format('%.2f', percentage_below_threshold)}%"
puts
end
puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"