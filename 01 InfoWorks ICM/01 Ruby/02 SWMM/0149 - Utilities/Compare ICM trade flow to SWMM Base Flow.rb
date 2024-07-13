cn = WSApplication.current_network
bn = WSApplication.background_network

# Retrieve hw_subcatchments from cn
cn_subcatchments = cn.row_object_collection('hw_subcatchment')

# Retrieve hw_node from bn
bn_nodes = bn.row_object_collection('sw_node')

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
    if base_flow + trade_flow != 0
      puts "Node ID: #{node_id}, Trade Flow: #{format('%.5f', trade_flow)}, Base Flow: #{format('%.5f', base_flow)}"
    end
    
    # Update totals with nil checks
    total_trade_flow += trade_flow unless trade_flow.nil?
    total_base_flow += base_flow unless base_flow.nil?
  else
    puts "Node ID: #{node_id} not found in bn"
  end
end

# Print totals
puts "Total Trade Flow: #{total_trade_flow}"
puts "Total Base Flow : #{total_base_flow}"