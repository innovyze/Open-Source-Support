# Source https://github.com/chaitanyalakeshri/ruby_scripts
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?

    # Get all the nodes or links or subcatchments as row object collection
    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?

    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?

    subcatchments_roc = net.row_object_collection('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?

    # Get all the nodes or links or subcatchments as array in an ICM SwMM Network
    nodes_hash_map={}
    nodes_hash_map = Hash.new { |h, k| h[k] = [] }
    nodes_ro = net.row_objects('sw_node')
    raise "Error: nodes not found" if nodes_ro.nil?
    number_nodes = 0
    number_outfalls = 0
    number_storage = 0
    number_junction = 0
    number_inflow_baseline = 0
    number_inflow_scaling = 0
    number_base_flow = 0
    number_additional_dwf = 0
    total_invert = 0.0
    max_invert = -Float::MAX
    min_invert = Float::MAX
    total_ground = 0.0
    max_ground = -Float::MAX
    min_ground = Float::MAX
    total_depth = 0.0
    max_depth = -Float::MAX
    min_depth = Float::MAX
    total_initial_depth = 0.0
    max_initial_depth = -Float::MAX
    min_initial_depth = Float::MAX
    total_surcharge_depth = 0.0
    max_surcharge_depth = -Float::MAX
    min_surcharge_depth = Float::MAX
    total_ponded_area = 0.0
    max_ponded_area = -Float::MAX
    min_ponded_area = Float::MAX
    total_unit_hydrograph_area = 0.0
    max_unit_hydrograph_area = -Float::MAX
    min_unit_hydrograph_area = Float::MAX
    total_flooding_discharge_coeff = 0.0
    max_flooding_discharge_coeff = -Float::MAX
    min_flooding_discharge_coeff = Float::MAX
    
    nodes_ro.each do |node|
        # Check if the node has additional_dwf and it is not nil
        node.additional_dwf.each do |additional_dwf|
            # Increment the counter if baseline is greater than 0
            number_additional_dwf += 1 if additional_dwf.baseline && additional_dwf.baseline > 0
        end
        
        number_inflow_scaling += 1 if node.inflow_scaling > 0
        number_base_flow      += 1 if node.base_flow  > 0     
        number_inflow_baseline += 1 if node.inflow_baseline > 0
        number_nodes += 1
        if node.node_type == 'Outfall'
            number_outfalls += 1
        elsif node.node_type == 'Storage'
            number_storage += 1
        elsif node.node_type == 'Junction'
            number_junction += 1
        end
        total_invert += node.invert_elevation
        max_invert = node.invert_elevation if node.invert_elevation > max_invert
        min_invert = node.invert_elevation if node.invert_elevation < min_invert
        total_ground += node.ground_level
        max_ground = node.ground_level if node.ground_level > max_ground
        min_ground = node.ground_level if node.ground_level < min_ground
        total_depth += node.maximum_depth
        max_depth = node.maximum_depth if node.maximum_depth > max_depth
        min_depth = node.maximum_depth if node.maximum_depth < min_depth
        unless node.initial_depth.nil?
            total_initial_depth += node.initial_depth
            max_initial_depth = node.initial_depth if node.initial_depth > max_initial_depth
            min_initial_depth = node.initial_depth if node.initial_depth < min_initial_depth
        end
        unless node.surcharge_depth.nil?
            total_surcharge_depth += node.surcharge_depth
            max_surcharge_depth = node.surcharge_depth if node.surcharge_depth > max_surcharge_depth
            min_surcharge_depth = node.surcharge_depth if node.surcharge_depth < min_surcharge_depth
        end
        unless node.ponded_area.nil?
            total_ponded_area += node.ponded_area
            max_ponded_area = node.ponded_area if node.ponded_area > max_ponded_area
            min_ponded_area = node.ponded_area if node.ponded_area < min_ponded_area
        end
    end
    
    mean_invert = total_invert / number_nodes
    mean_ground = total_ground / number_nodes
    mean_depth = total_depth / number_nodes
    mean_initial_depth = total_initial_depth / number_nodes
    mean_surcharge_depth = total_surcharge_depth / number_nodes
    mean_ponded_area = total_ponded_area / number_nodes
    
    printf "%-40s %-d\n", "Number of SW Nodes", number_nodes
    printf "%-40s %-d\n", "Number of SW Junctions", number_junction
    printf "%-40s %-d\n", "Number of SW Storage", number_storage
    printf "%-40s %-d\n", "Number of SW Outfalls", number_outfalls
    printf "%-40s %-d\n", "Number of SW Inflow Baseline", number_inflow_baseline
    printf "%-40s %-d\n", "Number of SW Inflow Scaling", number_inflow_scaling
    printf "%-40s %-d\n", "Number of SW Base Flow", number_base_flow
    printf "%-40s %-d\n", "Number_of_additional_dwf", number_additional_dwf
    printf "%-40s %-20s %-20s %-20s\n", "", "Mean", "Max", "Min"
    printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Invert Elevation", mean_invert, max_invert, min_invert
    printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Ground Elevation", mean_ground, max_ground, min_ground
    printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Full Depth", mean_depth, max_depth, min_depth
    printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Initial Depth", mean_initial_depth, max_initial_depth, min_initial_depth
    printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Surcharge Depth", mean_surcharge_depth, max_surcharge_depth, min_surcharge_depth
    printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Ponded Area", mean_ponded_area, max_ponded_area, min_ponded_area
    
    links_hash_map = {}
    links_hash_map = Hash.new { |h, k| h[k] = [] }
    links_ro = net.row_objects('sw_conduit')
    raise "Error: links not found" if links_ro.nil?
    number_links = 0
    number_length = 0.0
    total_conduit_height = 0.0
    max_conduit_height = -Float::MAX
    min_conduit_height = Float::MAX
    total_conduit_width = 0.0
    max_conduit_width = -Float::MAX
    min_conduit_width = Float::MAX
    total_manning_n = 0.0
    max_manning_n = -Float::MAX
    min_manning_n = Float::MAX
    total_downstream_invert = 0.0
    max_downstream_invert = -Float::MAX
    min_downstream_invert = Float::MAX
    total_upstream_invert = 0.0
    max_upstream_invert = -Float::MAX
    min_upstream_invert = Float::MAX
    total_number_of_barrels = 0
    max_number_of_barrels = -Float::MAX
    min_number_of_barrels = Float::MAX
    
    links_ro.each do |link|
        number_links += 1
        number_length += link.length
        unless link.Conduit_height.nil?
            total_conduit_height += link.Conduit_height
            max_conduit_height = link.Conduit_height if link.Conduit_height > max_conduit_height
            min_conduit_height = link.Conduit_height if link.Conduit_height < min_conduit_height
        end
        unless link.Conduit_width.nil?
            total_conduit_width += link.Conduit_width
            max_conduit_width = link.Conduit_width if link.Conduit_width > max_conduit_width
            min_conduit_width = link.Conduit_width if link.Conduit_width < min_conduit_width
        end
        unless link.Mannings_N.nil?
            total_manning_n += link.Mannings_N
            max_manning_n = link.Mannings_N if link.Mannings_N > max_manning_n
            min_manning_n = link.Mannings_N if link.Mannings_N < min_manning_n
        end
        unless link.ds_invert.nil?
            total_downstream_invert += link.ds_invert
            max_downstream_invert = link.ds_invert if link.ds_invert > max_downstream_invert
            min_downstream_invert = link.ds_invert if link.ds_invert < min_downstream_invert
        end
        unless link.us_invert.nil?
            total_upstream_invert += link.us_invert
            max_upstream_invert = link.us_invert if link.us_invert > max_upstream_invert
            min_upstream_invert = link.us_invert if link.us_invert < min_upstream_invert
        end
        unless link.number_of_barrels.nil?
            total_number_of_barrels += link.number_of_barrels
            max_number_of_barrels = link.number_of_barrels if link.number_of_barrels > max_number_of_barrels
            min_number_of_barrels = link.number_of_barrels if link.number_of_barrels < min_number_of_barrels
        end
    end
    
    if number_links != 0
        mean_conduit_height = total_conduit_height / number_links
        mean_conduit_width = total_conduit_width / number_links
        mean_manning_n = total_manning_n / number_links
        mean_downstream_invert = total_downstream_invert / number_links
        mean_upstream_invert = total_upstream_invert / number_links
        mean_number_of_barrels = total_number_of_barrels / number_links
    
        printf "%-40s %-d\n", "Number of SW Links", number_links
        printf "%-40s %-.3f\n", "Total SW Length", number_length
        printf "%-40s %-20s %-20s %-20s\n", "", "Mean", "Max", "Min"
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Conduit Height", mean_conduit_height, max_conduit_height, min_conduit_height
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Conduit Width", mean_conduit_width, max_conduit_width, min_conduit_width
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Manning n", mean_manning_n, max_manning_n, min_manning_n
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Downstream Invert", mean_downstream_invert, max_downstream_invert, min_downstream_invert
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Upstream Invert", mean_upstream_invert, max_upstream_invert, min_upstream_invert
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Number of Barrels", mean_number_of_barrels, max_number_of_barrels, min_number_of_barrels
    end
    
    subcatchments_hash_map = {}
    subcatchments_hash_map = Hash.new { |h, k| h[k] = [] }
    subcatchments_ro = net.row_objects('sw_subcatchment')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?

    number_subcatchments = 0
    total_area = 0.0
    total_imperviousness = 0.0
    max_imperviousness = -Float::MAX
    min_imperviousness = Float::MAX
    total_slope = 0.0
    max_slope = -Float::MAX
    min_slope = Float::MAX
    total_width = 0.0
    max_width = -Float::MAX
    min_width = Float::MAX
    
    subcatchments_ro.each do |subcatchment|
        number_subcatchments += 1
        total_area += subcatchment.area.to_f if subcatchment.area
        if subcatchment.percent_impervious
            total_imperviousness += subcatchment.percent_impervious.to_f
            max_imperviousness = subcatchment.percent_impervious.to_f if subcatchment.percent_impervious.to_f > max_imperviousness
            min_imperviousness = subcatchment.percent_impervious.to_f if subcatchment.percent_impervious.to_f < min_imperviousness
        end
        if subcatchment.catchment_slope
            total_slope += subcatchment.catchment_slope.to_f
            max_slope = subcatchment.catchment_slope.to_f if subcatchment.catchment_slope.to_f > max_slope
            min_slope = subcatchment.catchment_slope.to_f if subcatchment.catchment_slope.to_f < min_slope
        end
        if subcatchment.width
            total_width += subcatchment.width.to_f
            max_width = subcatchment.width.to_f if subcatchment.width.to_f > max_width
            min_width = subcatchment.width.to_f if subcatchment.width.to_f < min_width
        end
    end
    
    if number_subcatchments != 0
        mean_imperviousness = total_imperviousness / number_subcatchments
        mean_slope = total_slope / number_subcatchments
        mean_width = total_width / number_subcatchments
        
        printf "%-40s %-d\n", "Number of SW Subcatchments", number_subcatchments
        printf "%-40s %-.3f\n", "Total SW Subcatchment Area", total_area
        printf "%-40s %-20s %-20s %-20s\n", "", "Mean", "Max", "Min"
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Imperviousness", mean_imperviousness, max_imperviousness, min_imperviousness
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Subcatchment Slope", mean_slope, max_slope, min_slope
        printf "%-40s %-20.3f %-20.3f %-20.3f\n", "Subcatchment Width", mean_width, max_width, min_width
    end
    
    pumps_hash_map = {}
    pumps_hash_map = Hash.new { |h, k| h[k] = [] }
    pumps_ro = net.row_objects('sw_pump')
    raise "Error: pump not found" if pumps_ro.nil?
    number_pumps = 0
    pumps_ro.each do |pump|
        number_pumps += 1
    end
    printf "%-40s %-d\n", "Number of Pumps", number_pumps

    weirs_hash_map = {}
    weirs_hash_map = Hash.new { |h, k| h[k] = [] }
    weirs_ro = net.row_objects('sw_weir')
    raise "Error: weirs not found" if weirs_ro.nil?
    number_weirs = 0
    weirs_ro.each do |weir|
        number_weirs += 1
    end
    printf "%-40s %-d\n", "Number of Weirs", number_weirs
    
    orifices_hash_map = {}
    orifices_hash_map = Hash.new { |h, k| h[k] = [] }
    orifices_ro = net.row_objects('sw_orifice')
    raise "Error: orifices not found" if orifices_ro.nil?
    number_orifices = 0
    orifices_ro.each do |orifice|
        number_orifices += 1
    end
    printf "%-40s %-d\n", "Number of Orifices", number_orifices
    
    channels_hash_map = {}
    channels_hash_map = Hash.new { |h, k| h[k] = [] }
    channels_ro = net.row_objects('sw_outlet')
    raise "Error: outlets not found" if channels_ro.nil?
    number_channels = 0
    channels_ro.each do |channel|
        number_channels += 1
    end
    printf "%-40s %-d\n", "Number of Outlets", number_channels

    printf "%-40s\n", "This was an overview of the elements in an ICM SWMM Network"

rescue => e
    puts "Error: #{e.message}"
end