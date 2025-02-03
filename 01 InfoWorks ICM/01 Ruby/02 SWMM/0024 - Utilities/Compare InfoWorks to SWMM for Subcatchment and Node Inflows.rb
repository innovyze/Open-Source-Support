cn = WSApplication.current_network
bn = WSApplication.background_network
puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"
# Retrieve hw_nodes from cn
cn_subcatchments = cn.row_object_collection('hw_subcatchment')

# Retrieve sw_nodes from bn
bn_nodes = bn.row_object_collection('sw_node')

val = WSApplication.prompt "Compare Infoworks HW Subcatchments to SWMM SW Nodes for Inflow",
[
  ['hw_subcatchment population vs sw_node base_flow', 'Boolean', true],
  ['hw_subcatchment trade_flow vs sw_node base_flow', 'Boolean', true],
  ['hw_subcatchment base_flow vs sw_node base_flow', 'Boolean', true],
  ['hw_subcatchment additional_foul_flow vs sw_node base_flow', 'Boolean', true],
  ['hw_subcatchment population vs sw_node inflow_baseline', 'Boolean', true],
  ['hw_subcatchment trade_flow vs sw_node inflow_baseline', 'Boolean', true],
  ['hw_subcatchment base_flow vs sw_node inflow_baseline', 'Boolean', true],
  ['hw_subcatchment additional_foul_flow vs sw_node inflow_baseline', 'Boolean', true],
  ['hw_subcatchment population vs sw_node additional_dwf', 'Boolean', true],
  ['hw_subcatchment trade_flow vs sw_node additional_dwf', 'Boolean', true],
  ['hw_subcatchment base_flow vs sw_node additional_dwf', 'Boolean', true],
  ['hw_subcatchment additional_foul_flow vs sw_node additional_dwf', 'Boolean', true],
  ['Set trade_flow to base_flow', 'Boolean', false],
  ['Set base_flow to inflow_baseline', 'Boolean', false],
  ['Set additional_foul_flow to additional_dwf', 'Boolean', false],
  ["This tool compares selected attributes between", 'String'],
  ["InfoWorks HW Subcatchments and SWMM SW Nodes.", 'String'],
  ["Select the attributes you want to compare", 'String'],
  ["The comparison will be based on Node IDs.", 'String'],
  ["Results will show the values from both networks", 'String'],
  ["and their differences.", 'String']
], false

# Define attribute pairs
attribute_pairs = [
  ['population', 'base_flow'],
  ['trade_flow', 'base_flow'],
  ['base_flow', 'base_flow'],
  ['additional_foul_flow', 'base_flow'],
  ['population', 'inflow_baseline'],
  ['trade_flow', 'inflow_baseline'],
  ['base_flow', 'inflow_baseline'],
  ['additional_foul_flow', 'inflow_baseline'],
  ['population', 'additional_dwf'],
  ['trade_flow', 'additional_dwf'],
  ['base_flow', 'additional_dwf'],
  ['additional_foul_flow', 'additional_dwf']
]

# Loop through each val and perform comparison if true
val.each_with_index do |is_selected, index|
  next unless is_selected

  hw, sw = attribute_pairs[index]

  # Create a hash map for sw attribute by node_id
  bn_attributes = {}
  bn_nodes.each do |node|
    bn_attributes[node.node_id] = node[sw]
  end

  baseline_data = []
  # Collect baseline data from sw_node_additional_dwf
  bn.row_objects('sw_node').each do |ro|
    ro.additional_dwf.each do |additional_dwf|
        baseline_data << additional_dwf.baseline
  end
end

  # Initialize totals
  total_hw = 0.0
  total_sw = 0.0
  # Initialize counters
  below_threshold_count = 0
  total_comparisons = 0

  # Compare hw attribute from cn to sw attribute from bn using conduit_id
  cn_subcatchments.each do |sub|
    node_id = sub.node_id
    hw_value = sub[hw]

    if bn_attributes.key?(node_id)
      sw_value = bn_attributes[node_id]
      # Ensure hw_value and sw_value are not nil
      hw_value = hw_value.nil? ? 0.0 : hw_value
      sw_value = sw_value.nil? ? 0.0 : sw_value

      # Format hw_value and sw_value
      formatted_hw_value = format('%12.7f', hw_value)
      formatted_sw_value = format('%12.7f', sw_value)

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
      puts "Node ID: #{conduit_id.slice(0, 25).ljust(25)} not found in bn"
    end
  end

  # Calculate the percentage of comparisons below 0.1 percent
  percentage_below_threshold = (below_threshold_count.to_f / total_comparisons) * 100

  # Print totals
  puts "CN Subcatchemnt.#{hw}:".ljust(30) + format('%.4f', total_hw).rjust(10)
  puts "BN Node.#{sw}:".ljust(30) + format('%.4f', total_sw).rjust(10)
  puts "Difference:".ljust(30) + format('%.4f', total_hw - total_sw).rjust(10)
  puts

  # Print the count of comparisons below 0.1 percent, total comparisons, and percentage below 0.1 percent
  puts "Number of comparisons below 0.1 percent: #{below_threshold_count}"
  puts "Total number of comparisons: #{total_comparisons}"
  puts "Percentage of comparisons below 0.1 percent: #{format('%.2f', percentage_below_threshold)}%"
end

puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"