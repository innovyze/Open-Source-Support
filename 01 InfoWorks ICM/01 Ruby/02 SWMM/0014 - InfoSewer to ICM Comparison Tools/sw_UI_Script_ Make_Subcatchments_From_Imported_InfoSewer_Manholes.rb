# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
    
    # Accessing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
    
    # Get all the nodes or subcatchments as row object collection for InfoWorks Network
    nodes_roc = net.row_object_collection('sw_node')
    raise "Error: nodes not found" if nodes_roc.nil?

    # Get all the nodes and subcatchments as array in an InfoWorks Network
    nodes_hash_map = {}
    subcatchments_hash_map = {}
    nodes_ro = net.row_objects('sw_node')
    subcatchments_ro = net.row_objects('sw_subcatchment')
    raise "Error: nodes or subcatchments not found" if nodes_ro.nil? || subcatchments_ro.nil?

    # Build a hash map of nodes using x, y coordinates as keys
    nodes_ro.each do |node|
    nodes_hash_map[[node.x, node.y]] ||= []
    nodes_hash_map[[node.x, node.y]] << node
    end

    # Create new subcatchments for each unique x, y coordinate pair in the nodes hash map
    net.transaction_begin
    nodes_hash_map.each do |coordinates, nodes|
    subcatchment = net.new_row_object('sw_subcatchment')
    subcatchment.subcatchment_id = nodes.first.id
    subcatchment.x = nodes.first.x
    subcatchment.y = nodes.first.y
    subcatchment.area = 0.10
    subcatchment.write
    end
    net.transaction_commit

    # Print number of nodes and new subcatchments created
    printf "%-30s %-d\n", "Number of SW Nodes...", nodes_ro.count
    printf "%-30s %-d\n", "Number of SW Subcatchments...", subcatchments_ro.count
    printf "%-30s %-d\n", "Number of New Subcatchments...", nodes_hash_map.size

  
  rescue => e
    puts "Error: #{e.message}"
  end
  