cn = WSApplication.current_network
bn = WSApplication.background_network

# Retrieve hw_subcatchments from cn
cn_subcatchments = cn.row_object_collection('hw_subcatchment')
cn.transaction_begin

# Retrieve hw_node from bn
bn_nodes = bn.row_object_collection('sw_node')

val = WSApplication.prompt "Compare Infoworks HW Subcatchments to SWMM SW Nodes for Inflow",
[
  ['Set trade_flow to base_flow', 'Boolean', false],
  ['Make ICM Subcatchments from ICM SWMM Nodes', 'Boolean', false],
  ["This tool compares selected attributes between", 'String'],
  ["InfoWorks HW Subcatchments and SWMM SW Nodes.", 'String'],
  ["Select the attributes you want to compare", 'String'],
  ["The comparison will be based on Node IDs.", 'String'],
  ["Results will show the values from both networks", 'String'],
  ["and their differences.", 'String']
], false

# Remember the flags
set_trade_flow_to_base_flow = val[0]
make_subcatchments_from_nodes = val[1]

# Create a hash map for bn base_flow by node_id
bn_base_flows = {}
bn_nodes.each do |node|
  bn_base_flows[node.node_id] = node.base_flow
end

# Initialize totals
total_trade_flow = 0.0
total_base_flow = 0.0

# Compare trade_flow from cn to base_flow from bn using node_id
cn_subcatchments.each do |subcatchment|
  node_id = subcatchment.node_id
  trade_flow = subcatchment.trade_flow

  if bn_base_flows.key?(node_id)
    base_flow = bn_base_flows[node_id]
    # Ensure trade_flow and base_flow are not nil
    trade_flow = trade_flow.nil? ? 0.0 : trade_flow
    base_flow = base_flow.nil? ? 0.0 : base_flow

    # Set trade_flow to base_flow if the flag is set
    if set_trade_flow_to_base_flow
      subcatchment.trade_flow = base_flow
      subcatchment.write
    end

    # Print only if the sum of base_flow and trade_flow is not zero
    if base_flow + trade_flow != 0.0
      puts "Node ID: #{node_id.slice(0, 25).ljust(20)} Trade Flow: #{format('%10.5f', trade_flow)}, Base Flow: #{format('%10.5f', base_flow)}"
    end
    
    # Update totals
    total_trade_flow += trade_flow
    total_base_flow += base_flow
  else
    puts "Node ID: #{node_id} not found in bn"
  end
end

# Commit changes if trade_flow was set to base_flow
if set_trade_flow_to_base_flow
  cn.transaction_commit
end

# Print totals
puts "CN subcatchment.trade_flow: #{format('%.4f', total_trade_flow)}"
puts "BN node.base_flow         : #{format('%.4f', total_base_flow)}"

# Make ICM Subcatchments from ICM SWMM Nodes if the flag is set
if make_subcatchments_from_nodes
  cn.transaction_begin
  bn_nodes.each do |node|
    if node.node_type == "Junction"
      # Create new subcatchment
      new_subcatchment = cn.new_row_object('hw_subcatchment')
      new_subcatchment.subcatchment_id = node.node_id
      new_subcatchment.node_id = node.node_id
      new_subcatchment.trade_flow = node.base_flow
      new_subcatchment.x = node.x
      new_subcatchment.y = node.y
      # Set a meaningful default area or calculate based on actual data
      new_subcatchment.total_area = 1.0 # Replace with actual area calculation if possible
      new_subcatchment.write
      puts "Created subcatchment for Node ID: #{node.node_id}"
    end
  end
  cn.transaction_commit
end