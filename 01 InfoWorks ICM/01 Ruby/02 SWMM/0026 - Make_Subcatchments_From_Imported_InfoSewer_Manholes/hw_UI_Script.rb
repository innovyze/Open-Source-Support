# Source: https://github.com/chaitanyalakeshri/ruby_scripts 

begin
  # Accessing the current network from InfoWorks
  net = WSApplication.current_network
  # Raise an error if the current network is not found
  raise "Error: current network not found" if net.nil?
  
  # Accessing Row objects or collection of row objects
  # These can include nodes, links, subcatchments, and others

  # Get all the nodes as a row object collection for the InfoWorks Network
  nodes_roc = net.row_object_collection('hw_node')
  # Raise an error if nodes are not found
  raise "Error: nodes not found" if nodes_roc.nil?

  # Get all the nodes and subcatchments as arrays in an InfoWorks Network
  nodes_hash_map = {}
  subcatchments_hash_map = {}
  nodes_ro = net.row_objects('_nodes')
  subcatchments_ro = net.row_objects('hw_subcatchment')
  # Raise an error if nodes or subcatchments are not found
  raise "Error: nodes or subcatchments not found" if nodes_ro.nil? || subcatchments_ro.nil?

  # Build a hash map of nodes using x, y coordinates as keys
  nodes_ro.each do |node|
    nodes_hash_map[[node.x, node.y]] ||= []
    nodes_hash_map[[node.x, node.y]] << node
  end

  # Begin a transaction to create new subcatchments
  net.transaction_begin
  nodes_hash_map.each do |coordinates, nodes|
    subcatchment = net.new_row_object('hw_subcatchment')
    subcatchment.subcatchment_id = nodes.first.id
    subcatchment.x = nodes.first.x
    subcatchment.y = nodes.first.y
    subcatchment.total_area = 0.10 # Set a default total area for the subcatchment
    subcatchment.write # Write the new subcatchment to the network
  end
  net.transaction_commit # Commit the transaction to finalize the creation of new subcatchments

  # Print the number of nodes, existing subcatchments, and new subcatchments created
  printf "%-30s %-d\n", "Number of HW Nodes...", nodes_ro.count
  printf "%-30s %-d\n", "Number of HW Subcatchments...", subcatchments_ro.count
  printf "%-30s %-d\n", "Number of New Subcatchments...", nodes_hash_map.size

rescue => e
  # Print an error message if an exception is raised
  puts "Error: #{e.message}"
end
