# Source https://github.com/chaitanyalakeshri/ruby_scripts 
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection

    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_roc = net.row_object_collection('hw_pump')
    raise "Error: pump not found" if pump_roc.nil?
  
    # Get all the nodes or links or subcatchments as array
    nodes_hash_map={}
    nodes_hash_map = Hash.new { |h, k| h[k] = [] }
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
    nodes_ro.each do |node|
        nodes_hash_map[node.node_id] << node.id
    end   
    printf "%-20s \n", "Name"
    nodes_hash_map.each do |name, id|
        printf "Node %-20s \n", name
    end
      
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
  
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pump_ro.nil?

rescue => e
    puts "Error: #{e.message}"
  end
  

