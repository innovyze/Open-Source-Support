begin
    # Accessing the current network
    net = WSApplication.current_network
    raise "Error: Current network not found" if net.nil?
  
    # Define a method to count network elements
    def count_network_elements(network, object_type)
      elements = network.row_objects(object_type)
      raise "Error: #{object_type} not found" if elements.nil?
      elements.count
    end
  
    # Define a helper for formatted output
    def add_line(count, label)
      sprintf("%-10d\t%-s \n", count, label) 
    end
  
    # Collect results in a string
    results = "Network Element Count:\n"
    results += "-----------------------------------\n"
  
    # Add counts for all other HW_ tables
    tables = [
    'hw_sim_parameters', 'hw_manhole_defaults', 'hw_conduit_defaults', 'hw_subcatchment_defaults',
    'hw_large_catchment_parameters', 'hw_snow_parameters', 'hw_wq_params', 'hw_node', 'hw_conduit', 'hw_flap_valve',
    'hw_orifice', 'hw_pump', 'hw_sluice', 'hw_user_control', 'hw_weir', 'hw_flume', 'hw_siphon', 'hw_screen', 'hw_channel',
    'hw_channel_defaults', 'hw_river_reach_defaults', 'hw_culvert_inlet', 'hw_culvert_outlet', 'hw_blockage', 'hw_bridge_blockage',
    'hw_shape', 'hw_head_discharge', 'hw_runoff_surface', 'hw_land_use', 'hw_snow_pack', 'hw_headloss', 'hw_ground_infiltration',
    'hw_subcatchment', 'hw_polygon', 'hw_unit_hydrograph', 'hw_unit_hydrograph_month', 'hw_channel_shape', 'hw_general_line',
    'hw_porous_wall', 'hw_2d_zone', 'hw_mesh_zone', 'hw_roughness_zone', 'hw_2d_ic_polygon', 'hw_2d_point_source', 'hw_2d_boundary_line',
    'hw_irregular_weir', 'hw_river_reach', 'hw_porous_polygon', 'hw_cross_section_survey', 'hw_flow_efficiency', 'hw_bank_survey',
    'hw_bridge', 'hw_bridge_inlet', 'hw_bridge_opening', 'hw_bridge_outlet', 'hw_storage_area', 'hw_2d_zone_defaults', 'hw_rtc',
    'hw_2d_infil_surface', 'hw_2d_infiltration_zone', 'hw_2d_wq_ic_polygon', 'hw_2d_inf_ic_polygon', 'hw_inline_bank', 'hw_general_point',
    'hw_2d_linear_structure', 'hw_2d_sluice', 'hw_tvd_connector', 'hw_2d_results_polygon', 'hw_2d_results_line', 'hw_2d_results_point',
    'hw_1d_results_point', 'hw_2d_bridge', 'hw_spatial_rain_zone', 'hw_spatial_rain_source', 'hw_pdm_descriptor', 'hw_damage_receptor',
    'hw_head_unit_discharge', 'hw_2d_sed_ic_polygon', 'hw_mesh_level_zone', 'hw_risk_impact_zone', 'hw_sediment_grading', 'hw_suds_control',
    'hw_2d_line_source', 'hw_2d_turbulence_model', 'hw_2d_turbulence_zone', 'hw_2d_permeable_zone', 'hw_arma', 'hw_swmm_land_use',
    'hw_roughness_definition', 'hw_building', 'hw_2d_connect_line'
    ]

    element_counts = []

    tables.each do |table|
      count = count_network_elements(net, table)
      element_counts << [count, "Number of #{table.split('_').map(&:capitalize).join(' ')}"] if count > 0
    end
    
    # Sort the element counts from large to small
    element_counts.sort_by! { |count, _| -count }
    
    # Add sorted results to the results string
    element_counts.each do |count, label|
      results += add_line(count, label)
    end

    puts results
    WSApplication.message_box(results,'OK','Information','')

rescue => e
    puts e.message
end