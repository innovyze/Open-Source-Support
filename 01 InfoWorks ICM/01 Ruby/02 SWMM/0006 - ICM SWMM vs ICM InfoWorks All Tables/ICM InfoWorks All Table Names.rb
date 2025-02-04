# Counts all of the tables in an ICM InfoWorks Network

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?

    tables = [
        "hw_node",
        "hw_conduit",
        "hw_subcatchment",
        "hw_orifice",
        "hw_channel",
        "hw_river_reach",
        "hw_pump",
        "hw_screen",
        "hw_siphon",
        "hw_sluice",
        "hw_irregular_weir",
        "hw_user_control",
        "hw_weir",
        "hw_culvert_inlet",
        "hw_culvert_outlet",
        "hw_flap_valve",
        "hw_bridge",
        "hw_bridge_opening",
        "hw_bridge_blockage",
        "hw_bridge_inlet",
        "hw_bridge_outlet",
        "hw_flume",
        "hw_blockage",
        "hw_mesh_zone",
        "hw_mesh_level_zone",
        "hw_inline_bank",  
        "hw_roughness_zone",
        "hw_storage_area",    
        "hw_building",
        "hw_2d_boundary_line",
        "hw_2d_ic_polygon",
        "hw_2d_wq_ic_polygon",
        "hw_2d_inf_ic_polygon",
        "hw_2d_sed_ic_polygon",
        "hw_2d_infiltration_zone",
        "hw_2d_infil_surface",
        "hw_2d_turbulence_zone",
        "hw_2d_turbulence_model",
        "hw_2d_permeable_zone",
        "hw_2d_point_source",
        "hw_2d_zone",
        "hw_damage_receptor",
        "hw_General_line",
        "hw_General_point",
        "hw_polygon",
        "hw_risk_impact_zone",   
        "hw_porous_polygon",
        "hw_porous_wall",
        "hw_2d_linear_structure",
        "hw_2d_sluice",
        "hw_2d_bridge",
        "hw_2d_line_source",
        "hw_tvd_connector",
        "hw_spatial_rain_source",
        "hw_spatial_rain_zone",
        "hw_ground_infiltration",
        "hw_headloss",
        "hw_suds_control",
        "hw_head_discharge",
        "hw_pdm_descriptor",
        "hw_head_unit_discharge",
        "hw_flow_efficiency",
        "hw_land_use",
        "hw_swmm_land_use",
        "hw_channel_shape",
        "hw_runoff_surface",
        "hw_shape",
        "hw_sediment_grading",
        "hw_sim_parameters",
        "hw_snow_pack",
        "hw_unit_hydrograph",
        "hw_unit_hydrograph_month",
        "hw_wq_params",
        "hw_conduit_defaults",
        "hw_manhole_defaults",
        "hw_channel_defaults",
        "hw_river_reach_defaults",
        "hw_subcatchment_defaults",
        "hw_large_catchment_parameters",
        "hw_2d_zone_defaults",
        "hw_snow_parameters",
        "hw_cross_section_survey",
        "hw_bank_survey",
        "hw_prunes",
        "hw_arma",
        "hw_roughness_definition"
  ]
  
  nodes_hash_map = Hash.new { |h, k| h[k] = [] }
  
  tables.each do |table|
    nodes_ro = net.row_objects(table)
    raise "Error: #{table} not found" if nodes_ro.nil?
    number_nodes = 0
    nodes_ro.each do |node|
      number_nodes += 1
    end
    printf "%-50s %-d\n", "Number of #{table.upcase}", number_nodes
  end
  
rescue => e
    puts "Error: #{e.message}"
  end
  