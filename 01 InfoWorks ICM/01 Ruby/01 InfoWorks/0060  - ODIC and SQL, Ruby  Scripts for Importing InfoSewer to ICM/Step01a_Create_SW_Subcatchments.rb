# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
  # Access the current network
  net = WSApplication.current_network
  # Raise an error if the current network is not found
  raise "Error: current network not found" if net.nil?
  
  # Get all the nodes as a collection of row objects for the current network
  nodes_roc = net.row_object_collection('sw_node')
  # Raise an error if the nodes are not found
  raise "Error: nodes not found" if nodes_roc.nil?

  # Get all the nodes and subcatchments as arrays in the current network
  nodes_hash_map = {}
  subcatchments_hash_map = {}
  nodes_ro = net.row_objects('sw_node')
  subcatchments_ro = net.row_objects('sw_subcatchment')
  # Raise an error if the nodes or subcatchments are not found
  raise "Error: nodes or subcatchments not found" if nodes_ro.nil? || subcatchments_ro.nil?

  # Build a hash map of nodes using x, y coordinates as keys
  nodes_ro.each do |node|
      nodes_hash_map[[node.x, node.y]] ||= []
      nodes_hash_map[[node.x, node.y]] << node
  end

  # Start a transaction to create new subcatchments
  net.transaction_begin
  # For each unique x, y coordinate pair in the nodes hash map, create a new subcatchment
  nodes_hash_map.each do |coordinates, nodes|
      subcatchment = net.new_row_object('sw_subcatchment')
      subcatchment.subcatchment_id = nodes.first.id
      subcatchment.x = nodes.first.x
      subcatchment.y = nodes.first.y
      subcatchment.area = 0.10
      subcatchment.write
  end
  # Commit the transaction, making all changes permanent
  net.transaction_commit

  # Print the number of nodes and new subcatchments created
  printf "%-30s %-d\n", "Number of SW Nodes...", nodes_ro.count
  printf "%-30s %-d\n", "Number of SW Subcatchments...", subcatchments_ro.count
  printf "%-30s %-d\n", "Number of New Subcatchments...", nodes_hash_map.size

rescue => e
  # Print any errors that occur
  puts "Error: #{e.message}"
end