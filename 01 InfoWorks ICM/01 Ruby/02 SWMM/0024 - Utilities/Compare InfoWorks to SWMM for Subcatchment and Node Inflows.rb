# Access current and background networks
cn = WSApplication.current_network
bn = WSApplication.background_network

puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"

# Retrieve hw_subcatchments from cn
cn_subcatchments = cn.row_object_collection('hw_subcatchment')

# Retrieve sw_nodes from bn (cached for efficiency)
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

unless val
  puts "Prompt canceled. No selection made."
  exit
end

# Define attribute pairs (only for comparison indices 0-11)
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

# Loop through each val and perform comparison if true, skipping non-comparison indices
val.each_with_index do |is_selected, index|
  next unless is_selected && index < attribute_pairs.length # Skip non-comparison indices (12+)

  hw, sw = attribute_pairs[index]

  # Create a hash map for sw attribute by node_id
  bn_attributes = {}
  bn_nodes.each do |node|
    # Handle additional_dwf as a sub-attribute if needed
    value = case sw
            when 'additional_dwf'
              node.additional_dwf&.baseline || node[sw] || 0.0
            else
              node[sw] || 0.0
            end
    bn_attributes[node.node_id] = value
  end

  # Initialize totals
  total_hw = 0.0
  total_sw = 0.0
  below_threshold_count = 0
  total_comparisons = 0

  # Compare hw attribute from cn to sw attribute from bn using node_id
  cn_subcatchments.each do |sub|
    node_id = sub.node_id
    hw_value = sub[hw] || 0.0

    if bn_attributes.key?(node_id)
      sw_value = bn_attributes[node_id]
      formatted_hw_value = format('%12.7f', hw_value)
      formatted_sw_value = format('%12.7f', sw_value)

      difference_percentage = ((hw_value - sw_value).abs / [(hw_value + sw_value) / 2.0, 1e-10].max) * 100

      total_comparisons += 1
      below_threshold_count += 1 if difference_percentage <= 0.1

      if difference_percentage > 0.1
        puts "Node ID: #{node_id.to_s.slice(0, 25).ljust(25)} CN #{hw.capitalize}: #{formatted_hw_value}, BN #{sw.capitalize}: #{formatted_sw_value}, Diff %: #{format('%.2f', difference_percentage)}%"
      end

      total_hw += hw_value
      total_sw += sw_value
    else
      puts "Node ID: #{node_id.to_s.slice(0, 25).ljust(25)} not found in bn"
    end
  end

  percentage_below_threshold = (below_threshold_count.to_f / [total_comparisons, 1].max * 100).round(2)

  puts "\nSummary for #{hw.capitalize} vs #{sw.capitalize}:"
  puts "CN Subcatchment.#{hw}:".ljust(30) + format('%.4f', total_hw).rjust(10)
  puts "BN Node.#{sw}:".ljust(30) + format('%.4f', total_sw).rjust(10)
  puts "Difference:".ljust(30) + format('%.4f', total_hw - total_sw).rjust(10)
  puts "Number of comparisons below 0.1%: #{below_threshold_count}"
  puts "Total comparisons: #{total_comparisons}"
  puts "Percentage below 0.1%: #{percentage_below_threshold}%"
  puts "-" * 60
end

puts "CN is the ICM Infoworks Network and BN is the ICM SWMM Network"