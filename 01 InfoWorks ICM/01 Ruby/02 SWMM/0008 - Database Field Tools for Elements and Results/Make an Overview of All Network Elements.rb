# Source https://github.com/chaitanyalakeshri/ruby_scripts 
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection for InfoWorks Network

    nodes_roc = net.row_object_collection('hw_node')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('hw_conduit')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('hw_subcatchment')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_roc = net.row_object_collection('hw_pump')
    raise "Error: pump not found" if pump_roc.nil?
  
    # Get all the nodes or links or subcatchments as array in an InfoWorks Network
    nodes_hash_map={}
    nodes_hash_map = Hash.new { |h, k| h[k] = [] }
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
    number_nodes = 0
    nodes_ro.each do |node|
        number_nodes += 1
    end       
    printf "%-30s %-d\n", "Number of HW Nodes...", number_nodes

    links_hash_map = {}
    links_hash_map = Hash.new { |h, k| h[k] = [] }
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    number_links = 0
    links_ro.each do |link|
        number_links += 1
    end          
    printf "%-30s %-d\n", "Number of HW Links...", number_links

    subcatchments_hash_map = {}
    subcatchments_hash_map = Hash.new { |h, k| h[k] = [] }
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
    number_subcatchments = 0
    subcatchments_ro.each do |subcatchment|
        number_subcatchments += 1
    end
    printf "%-30s %-d\n", "Number of HW Subcatchments.", number_subcatchments
   
    pumps_hash_map = {}
    pumps_hash_map = Hash.new { |h, k| h[k] = [] }
    pumps_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pumps_ro.nil?
    number_pumps = 0
    pumps_ro.each do |pump|
        number_pumps += 1
    end
    printf "%-30s %-d\n", "Number of Pumps...", number_pumps

weirs_hash_map = {}
weirs_hash_map = Hash.new { |h, k| h[k] = [] }
weirs_ro = net.row_objects('hw_weir')
raise "Error: weirs not found" if weirs_ro.nil?
number_weirs = 0
weirs_ro.each do |weir|
    number_weirs += 1
end
printf "%-30s %-d\n", "Number of Weirs...", number_weirs

orifices_hash_map = {}
orifices_hash_map = Hash.new { |h, k| h[k] = [] }
orifices_ro = net.row_objects('hw_orifice')
raise "Error: orifices not found" if orifices_ro.nil?
number_orifices = 0
orifices_ro.each do |orifice|
    number_orifices += 1
end
printf "%-30s %-d\n", "Number of Orifices...", number_orifices

channels_hash_map = {}
channels_hash_map = Hash.new { |h, k| h[k] = [] }
channels_ro = net.row_objects('hw_channel')
raise "Error: channels not found" if channels_ro.nil?
number_channels = 0
channels_ro.each do |channel|
    number_channels += 1
end
printf "%-30s %-d\n", "Number of Channels...", number_channels

river_reaches_hash_map = {}
river_reaches_hash_map = Hash.new { |h, k| h[k] = [] }
river_reaches_ro = net.row_objects('hw_river_reach')
raise "Error: river reaches not found" if river_reaches_ro.nil?
number_river_reaches = 0
river_reaches_ro.each do |river_reach|
    number_river_reaches += 1
end
printf "%-30s %-d\n", "Number of River Reaches...", number_river_reaches

hw_storage_areas_hash_map = {}
hw_storage_areas_hash_map = Hash.new { |h, k| h[k] = [] }
hw_storage_areas_ro = net.row_objects('hw_storage_area')
raise "Error: hw storage areas not found" if hw_storage_areas_ro.nil?
number_hw_storage_areas = 0
hw_storage_areas_ro.each do |hw_storage_area|
    number_hw_storage_areas += 1
end
printf "%-30s %-d\n", "Number of HW Storage Areas...", number_hw_storage_areas

hw_culvert_inlets_hash_map = {}
hw_culvert_inlets_hash_map = Hash.new { |h, k| h[k] = [] }
hw_culvert_inlets_ro = net.row_objects('hw_culvert_inlet')
raise "Error: hw culvert inlets not found" if hw_culvert_inlets_ro.nil?
number_hw_culvert_inlets = 0
hw_culvert_inlets_ro.each do |hw_culvert_inlet|
    number_hw_culvert_inlets += 1
end
printf "%-30s %-d\n", "Number of HW Culvert Inlets...", number_hw_culvert_inlets

hw_culvert_outlets_hash_map = {}
hw_culvert_outlets_hash_map = Hash.new { |h, k| h[k] = [] }
hw_culvert_outlets_ro = net.row_objects('hw_culvert_outlet')
raise "Error: hw culvert outlets not found" if hw_culvert_outlets_ro.nil?
number_hw_culvert_outlets = 0
hw_culvert_outlets_ro.each do |hw_culvert_outlet|
number_hw_culvert_outlets += 1
end
printf "%-30s %-d\n", "Number of HW Culvert Outlets..", number_hw_culvert_outlets

hw_flap_valves_hash_map = {}
hw_flap_valves_hash_map = Hash.new { |h, k| h[k] = [] }
hw_flap_valves_ro = net.row_objects('hw_flap_valve')
raise "Error: hw flap valves not found" if hw_flap_valves_ro.nil?
number_hw_flap_valves = 0
hw_flap_valves_ro.each do |hw_flap_valve|
number_hw_flap_valves += 1
end
printf "%-30s %-d\n", "Number of HW Flap Valves...", number_hw_flap_valves

hw_bridges_hash_map = {}
hw_bridges_hash_map = Hash.new { |h, k| h[k] = [] }
hw_bridges_ro = net.row_objects('hw_bridge')
raise "Error: hw bridges not found" if hw_bridges_ro.nil?
number_hw_bridges = 0
hw_bridges_ro.each do |hw_bridge|
number_hw_bridges += 1
end
printf "%-30s %-d\n", "Number of HW Bridges...", number_hw_bridges

hw_flumes_hash_map = {}
hw_flumes_hash_map = Hash.new { |h, k| h[k] = [] }
hw_flumes_ro = net.row_objects('hw_flume')
raise "Error: hw flumes not found" if hw_flumes_ro.nil?
number_hw_flumes = 0
hw_flumes_ro.each do |hw_flume|
number_hw_flumes += 1
end
printf "%-30s %-d\n", "Number of HW Flumes...", number_hw_flumes

hw_polygons_hash_map = {}
hw_polygons_hash_map = Hash.new { |h, k| h[k] = [] }
hw_polygons_ro = net.row_objects('hw_polygon')
raise "Error: hw polygons not found" if hw_polygons_ro.nil?
number_hw_polygons = 0
hw_polygons_ro.each do |hw_polygon|
number_hw_polygons += 1
end
printf "%-30s %-d\n","Number of Polygons...  ", number_hw_polygons

rescue => e
    puts "Error: #{e.message}"
  end
  

