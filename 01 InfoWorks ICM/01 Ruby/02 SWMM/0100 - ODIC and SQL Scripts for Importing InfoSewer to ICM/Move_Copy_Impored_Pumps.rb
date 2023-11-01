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
    puts "Total number of nodes: #{nodes_ro.count}"
    
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
    puts "Total number of subcatchments: #{subcatchments_ro.count}"

    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    puts "Total number of links: #{links_ro.count}"
    # Existing code
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    
    pump_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pump_ro.nil?
    puts "Total number of pumps: #{pump_ro.count}"

    # Filter links with the label 'Pump'
    pump_links = links_ro.select { |link| link.user_text_10 == 'Pump' }

    # Check if any pump links are found
    if pump_links.any?
    # Display the total number of pump links
    puts "-" * 20  # Separator
    puts "Total number of pump links: #{pump_links.count}"

    # Iterate over each pump link and display its details
    net.transaction_begin
    pump_links.each_with_index do |pump_link, index|
        puts "Pump Link #{index + 1} Details:"
        puts "Link ID: #{pump_link.id}"
        puts "Upstream Node ID: #{pump_link.us_node_id}"
        puts "Downstream Node ID: #{pump_link.ds_node_id}"
        puts "-" * 20  # Separator
        # Assuming pump_ro is a pre-defined object for storing/linking pump data
        net.row_objects('hw_pump')
        pump_ro.us_node_id = pump_link.us_node_id.to_s
        pump_ro.ds_node_id = pump_link.ds_node_id
        pump_ro.id = pump_link.id  
        pump_ro.write
    end
    net.transaction_commit
    else
    puts "No pump links found."
    end
  
  rescue => e
    puts "Error: #{e.message}"
  end
  