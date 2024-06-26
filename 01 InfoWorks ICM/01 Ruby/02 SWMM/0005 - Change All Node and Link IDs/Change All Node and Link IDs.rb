# Source https://github.com/chaitanyalakeshri/ruby_scripts 
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
   # nodes_roc = net.row_object_collection('_nodes')
   # raise "Error: nodes not found" if nodes_roc.nil?  
   # links_roc = net.row_object_collection('sw_conduit')
   # raise "Error: sw_conduit not found" if links_roc.nil?  

    net.transaction_begin
    
    # Get all the nodes or links as array
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    
    node_number = 1
    nodes_ro.each do |node|
      node.node_id = "N#{node_number}"
      node_number += 1
      node.write
    end

    link_number = 1
    links_ro.each do |link|
      link.id = "L#{link_number}"
      link_number += 1
      link.write
    end    
    
    puts "Node IDs Changed", node_number
    puts "Link IDs Changed", link_number
    net.transaction_commit    

rescue => e
    puts "Error: #{e.message}"
  end
