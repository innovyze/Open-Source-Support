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
        total_invert = 0.0
        total_ground = 0.0
        total_depth = 0.0
        total_initial_depth = 0.0
        total_surcharge_depth = 0.0
        total_ponded_area = 0.0
        total_unit_hydrograph_area = 0.0
        total_flooding_discharge_coeff = 0.0
        
        nodes_ro.each do |node|
            number_nodes += 1
            if node.node_type == 'Outfall'
                number_outfalls += 1
            elsif node.node_type == 'Storage'
                number_storage += 1
            elsif node.node_type == 'Junction'
                number_junction += 1
            end
            total_invert += node.invert_elevation
            total_ground += node.ground_level
            total_depth += node.maximum_depth
            total_initial_depth += node.initial_depth unless node.initial_depth.nil?
            total_surcharge_depth += node.surcharge_depth unless node.surcharge_depth.nil?
            total_ponded_area += node.ponded_area unless node.ponded_area.nil?
            total_unit_hydrograph_area += node.unit_hydrograph_area unless node.unit_hydrograph_area.nil?
            total_flooding_discharge_coeff += node.flooding_discharge_coeff unless node.flooding_discharge_coeff.nil?
        end
        
        average_invert = total_invert / number_nodes
        average_ground = total_ground / number_nodes
        average_depth = total_depth / number_nodes
        average_initial_depth = total_initial_depth / number_nodes
        average_surcharge_depth = total_surcharge_depth / number_nodes
        average_ponded_area = total_ponded_area / number_nodes
        average_unit_hydrograph_area = total_unit_hydrograph_area / number_nodes
        average_flooding_discharge_coeff = total_flooding_discharge_coeff / number_nodes
        
        printf "%-40s %-d\n", "Number of SW Nodes", number_nodes
        printf "%-40s %-d\n", "Number of SW Junctions", number_junction
        printf "%-40s %-d\n", "Number of SW Storage", number_storage
        printf "%-40s %-d\n", "Number of SW Outfalls", number_outfalls
        printf "%-40s %-.3f\n", "Average Invert Elevation", average_invert
        printf "%-40s %-.3f\n", "Average Ground Elevation", average_ground
        printf "%-40s %-.3f\n", "Average Full Depth", average_depth
        printf "%-40s %-.3f\n", "Average Initial Depth", average_initial_depth
        printf "%-40s %-.3f\n", "Average Surcharge Depth", average_surcharge_depth
        printf "%-40s %-.3f\n", "Average Ponded Area", average_ponded_area
        printf "%-40s %-.3f\n", "Average Unit Hydrograph Area", average_unit_hydrograph_area
        printf "%-40s %-.3f\n", "Average Flooding Discharge Coeff", average_flooding_discharge_coeff
        

        links_hash_map = {}
        links_hash_map = Hash.new { |h, k| h[k] = [] }
        links_ro = net.row_objects('sw_conduit')
        raise "Error: links not found" if links_ro.nil?
        number_links = 0
        number_length = 0.0
        total_conduit_height = 0.0
        total_conduit_width = 0.0
        total_manning_n = 0.0
        total_downstream_invert = 0.0
        total_upstream_invert = 0.0
        total_number_of_barrels = 0
        total_us_invert = 0.0
        total_ds_invert = 0.0
        total_us_headloss_coeff = 0.0
        total_ds_headloss_coeff = 0.0
        total_bottom_mannings_N = 0.0
        total_roughness_depth_threshold = 0.0
        total_initial_flow = 0.0
        total_max_flow = 0.0
        total_av_headloss_coeff = 0.0
        total_seepage_rate = 0.0
        total_flap_gate = 0
        total_culvert_code = 0
        
        links_ro.each do |link|
            number_links += 1
            number_length += link.length
            total_conduit_height += link.Conduit_height unless link.Conduit_height.nil?
            total_conduit_width += link.Conduit_width unless link.Conduit_width.nil?
            total_manning_n += link.Mannings_N unless link.Mannings_N.nil?
            total_downstream_invert += link.ds_invert unless link.ds_invert.nil?
            total_upstream_invert += link.us_invert unless link.us_invert.nil?
            total_number_of_barrels += link.number_of_barrels unless link.number_of_barrels.nil?
            total_us_invert += link.us_invert unless link.us_invert.nil?
            total_ds_invert += link.ds_invert unless link.ds_invert.nil?
            total_us_headloss_coeff += link.us_headloss_coeff unless link.us_headloss_coeff.nil?
            total_ds_headloss_coeff += link.ds_headloss_coeff unless link.ds_headloss_coeff.nil?
            total_bottom_mannings_N += link.bottom_mannings_N unless link.bottom_mannings_N.nil?
            total_roughness_depth_threshold += link.roughness_depth_threshold unless link.roughness_depth_threshold.nil?
            total_initial_flow += link.initial_flow unless link.initial_flow.nil?
            total_max_flow += link.max_flow unless link.max_flow.nil?
            total_av_headloss_coeff += link.av_headloss_coeff unless link.av_headloss_coeff.nil?
            total_seepage_rate += link.seepage_rate unless link.seepage_rate.nil?
            total_flap_gate ||= link.flap_gate
            total_culvert_code ||= link.culvert_code
        end
          
        average_conduit_height = total_conduit_height / number_links unless number_links == 0
        average_conduit_width = total_conduit_width / number_links unless number_links == 0
        average_manning_n = total_manning_n / number_links unless number_links == 0
        average_downstream_invert = total_downstream_invert / number_links unless number_links == 0
        average_upstream_invert = total_upstream_invert / number_links unless number_links == 0
        average_us_invert = total_us_invert / number_links unless number_links == 0
        average_ds_invert = total_ds_invert / number_links unless number_links == 0
        average_number_of_barrels = total_number_of_barrels / number_links unless number_links == 0
        average_us_headloss_coeff = total_us_headloss_coeff / number_links unless number_links == 0
        average_ds_headloss_coeff = total_ds_headloss_coeff / number_links unless number_links == 0
        average_bottom_mannings_N = total_bottom_mannings_N / number_links unless number_links == 0
        average_roughness_depth_threshold = total_roughness_depth_threshold / number_links unless number_links == 0
        average_initial_flow = total_initial_flow / number_links unless number_links == 0
        average_max_flow = total_max_flow / number_links unless number_links == 0
        average_av_headloss_coeff = total_av_headloss_coeff / number_links unless number_links == 0
        average_seepage_rate = total_seepage_rate / number_links unless number_links == 0
        average_flap_gate = total_flap_gate / number_links unless number_links == 0
        average_culvert_code = total_culvert_code / number_links unless number_links == 0

        
        printf "%-40s %-d\n", "Number of SW Links", number_links
        if number_links != 0
        printf "%-40s %-.3f\n", "Total SW Length", number_length
        printf "%-40s %-.3f\n", "Average Conduit Height", average_conduit_height
        printf "%-40s %-.3f\n", "Average Conduit Width", average_conduit_width
        printf "%-40s %-.3f\n", "Average Manning n", average_manning_n
        printf "%-40s %-.3f\n", "Average Downstream Invert", average_downstream_invert
        printf "%-40s %-.3f\n", "Average Upstream Invert", average_upstream_invert
        printf "%-40s %-.3f\n", "Average Number of Barrels", average_number_of_barrels
        printf "%-40s %-.3f\n", "Average US Invert", average_us_invert
        printf "%-40s %-.3f\n", "Average DS Invert", average_ds_invert
        printf "%-40s %-.3f\n", "Average US Headloss Coefficient", average_us_headloss_coeff
        printf "%-40s %-.3f\n", "Average DS Headloss Coefficient", average_ds_headloss_coeff
        printf "%-40s %-.3f\n", "Average Bottom Mannings N", average_bottom_mannings_N
        printf "%-40s %-.3f\n", "Average Roughness Depth Threshold", average_roughness_depth_threshold
        printf "%-40s %-.3f\n", "Average Initial Flow", average_initial_flow
        printf "%-40s %-.3f\n", "Average Max Flow", average_max_flow
        printf "%-40s %-.3f\n", "Average Average Headloss Coefficient", average_av_headloss_coeff
        printf "%-40s %-.3f\n", "Average Seepage Rate", average_seepage_rate
        printf "%-40s %-.3f\n", "Average Flap Gate", average_flap_gate
        printf "%-40s %-.3f\n", "Average Culvert Code", average_culvert_code
        end        
        
        subcatchments_hash_map = {}
        subcatchments_hash_map = Hash.new { |h, k| h[k] = [] }
        subcatchments_ro = net.row_objects('sw_subcatchment')
        raise "Error: subcatchments not found" if subcatchments_ro.nil?

        number_subcatchments = 0
        total_area = 0.0
        total_imperviousness = 0.0
        total_slope = 0.0
        total_width = 0.0
        total_initial_infiltration = 0.0
        total_limiting_infiltration = 0.0
        total_decay_factor = 0.0
        total_max_infiltration_volume = 0.0
        total_average_capillary_suction = 0.0
        total_saturated_hydraulic_conductivity = 0.0
        total_initial_moisture_deficit = 0.0
        total_curve_number = 0.0
        total_drying_time = 0.0
        total_time_of_concentration = 0.0
        total_hydraulic_length = 0.0
        total_shape_factor = 0.0
        total_initial_abstraction = 0.0
        
        subcatchments_ro.each do |subcatchment|
          number_subcatchments += 1
          total_area += subcatchment.area.to_f if subcatchment.area
          total_imperviousness += subcatchment.percent_impervious.to_f if subcatchment.percent_impervious
          total_slope += subcatchment.catchment_slope.to_f if subcatchment.catchment_slope
          total_width += subcatchment.width.to_f if subcatchment.width
          total_initial_infiltration += subcatchment.initial_infiltration.to_f if subcatchment.initial_infiltration
          total_limiting_infiltration += subcatchment.limiting_infiltration.to_f if subcatchment.limiting_infiltration
          total_decay_factor += subcatchment.decay_factor.to_f if subcatchment.decay_factor
          total_max_infiltration_volume += subcatchment.max_infiltration_volume.to_f if subcatchment.max_infiltration_volume
          total_average_capillary_suction += subcatchment.average_capillary_suction.to_f if subcatchment.average_capillary_suction
          total_saturated_hydraulic_conductivity += subcatchment.saturated_hydraulic_conductivity.to_f if subcatchment.saturated_hydraulic_conductivity
          total_initial_moisture_deficit += subcatchment.initial_moisture_deficit.to_f if subcatchment.initial_moisture_deficit
          total_curve_number += subcatchment.curve_number.to_f if subcatchment.curve_number
          total_drying_time += subcatchment.drying_time.to_f if subcatchment.drying_time
          total_time_of_concentration += subcatchment.time_of_concentration.to_f if subcatchment.time_of_concentration
          total_hydraulic_length += subcatchment.hydraulic_length.to_f if subcatchment.hydraulic_length
          total_shape_factor += subcatchment.shape_factor.to_f if subcatchment.shape_factor
          total_initial_abstraction += subcatchment.initial_abstraction.to_f if subcatchment.initial_abstraction
        end
        
        if number_subcatchments != 0
          average_imperviousness = total_imperviousness / number_subcatchments
          average_slope = total_slope / number_subcatchments
          average_width = total_width / number_subcatchments
          average_initial_infiltration = total_initial_infiltration / number_subcatchments
          average_limiting_infiltration = total_limiting_infiltration / number_subcatchments
          average_decay_factor = total_decay_factor / number_subcatchments
          average_max_infiltration_volume = total_max_infiltration_volume / number_subcatchments
          average_average_capillary_suction = total_average_capillary_suction / number_subcatchments
          average_saturated_hydraulic_conductivity = total_saturated_hydraulic_conductivity / number_subcatchments
          average_initial_moisture_deficit = total_initial_moisture_deficit / number_subcatchments
          average_curve_number = total_curve_number / number_subcatchments
          average_drying_time = total_drying_time / number_subcatchments
          average_time_of_concentration = total_time_of_concentration / number_subcatchments
          average_hydraulic_length = total_hydraulic_length / number_subcatchments
          average_shape_factor = total_shape_factor / number_subcatchments
          average_initial_abstraction = total_initial_abstraction / number_subcatchments
        else
          # handle the divide by zero error here
        end          
        
        printf "%-40s %-d\n", "Number of SW Subcatchments", number_subcatchments   
        if number_subcatchments != 0
            printf "%-40s %-.3f\n", "Total SW Subcatchment Area", total_area
            printf "%-40s %-.3f\n", "Average Imperviousness", average_imperviousness
            printf "%-40s %-.3f\n", "Average Subcatchment Slope", average_slope
            printf "%-40s %-.3f\n", "Average Subcatchment Width", average_width
            printf "%-40s %-.3f\n", "Average Capillary Suction", average_average_capillary_suction
            printf "%-40s %-.3f\n", "Saturated Hydraulic Conductivity", average_saturated_hydraulic_conductivity
            printf "%-40s %-.3f\n", "Initial Infiltration", average_initial_infiltration
            printf "%-40s %-.3f\n", "Limiting Infiltration", average_limiting_infiltration
            printf "%-40s %-.3f\n", "Decay Factor", average_decay_factor
            printf "%-40s %-.3f\n", "Max Infiltration Volume", average_max_infiltration_volume
            printf "%-40s %-.3f\n", "Initial Moisture Deficit", average_initial_moisture_deficit
            printf "%-40s %-.3f\n", "Curve Number", average_curve_number
            printf "%-40s %-.3f\n", "Drying Time", average_drying_time
            printf "%-40s %-.3f\n", "Average Time of Concentration", average_time_of_concentration
            printf "%-40s %-.3f\n", "Average Hydraulic Length", average_hydraulic_length
            printf "%-40s %-.3f\n", "Average Shape Factor", average_shape_factor
            printf "%-40s %-.3f\n", "Average Initial Abstraction", average_initial_abstraction      
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
    raise "Error: outletds not found" if channels_ro.nil?
    number_channels = 0
    channels_ro.each do |channel|
        number_channels += 1
    end
    printf "%-40s %-d\n", "Number of Outlets", number_channels

    printf "%-40s\n", "This was an overview of the elements in an ICM SWMM Network"

    rescue => e
        puts "Error: #{e.message}"
      end
      
    
    