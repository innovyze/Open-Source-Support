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
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
  
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
  
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pump_ro.nil?
  
    # accessing an individual row object
    ro = net.row_object('hw_conduit', '1234567.1')
    raise "Error: row object not found" if ro.nil?
  
    # Getting value of particular field from a specific row object
    ro = net.row_object('hw_conduit', '1234567.1').length
    raise "Error: length not found" if ro.nil?
  
    # selecting a particular object
    ro = net.row_object('hw_conduit', '1234567.1').selected = true
  
    # clear selection
    net.clear_selection
  
  rescue => e
    puts "Error: #{e.message}"
  end
  