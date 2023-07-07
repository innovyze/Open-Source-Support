# the code is from https://github.com/chaitanyalakeshri/ruby_scripts
# modifed by CHATGPT

# Check if there is a network open in the WSApplication
if WSApplication.current_network.nil?
    puts "Error: There is no open network in the WSApplication."
    return
  end
  
  # Get the current network
  net = WSApplication.current_network
  net.clear_selection
  
  # Create an array to store node IDs
  node_ids = []
  
  # Validate if the nodes_oc is not empty
  nodes_oc = net.row_objects('_nodes')
  if nodes_oc.empty?
    puts "Error: _nodes object collection is empty."
    return
  end
  
  # Store node IDs into the array 'node_ids' from the nodes object collection
  nodes_oc.each do |node|
    node_ids << node.node_id
  end
  
  # Create an array to store downstream node IDs
  downstream_node_ids = []
  
  # Validate if the links_oc is not empty
  links_oc = net.row_objects('_links')
  if links_oc.empty?
    puts "Error: _links object collection is empty."
    return
  end
  
  # Store downstream node IDs into the array 'downstream_node_ids' from the links object collection
  links_oc.each do |link|
    downstream_node_ids << link.ds_node_id
  end
  
  # Loop through each node ID
  node_ids.each do |node_id|
    # If the node ID is not in the downstream node IDs array, select it
    if !downstream_node_ids.include?(node_id)
      net.row_object('_nodes', node_id).selected = true
    end
  end
  