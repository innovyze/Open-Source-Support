# Counts all of the tables in an ICM SWMM Network

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?

    table_names = [
        "sw_conduit",
        "sw_node",
        "sw_uh",
        "sw_uh_group",
        "sw_weir",
        "sw_pump",
        "sw_orifice",
        "sw_outlet",
        "sw_subcatchment",
        "sw_suds_control",
        "sw_aquifer",
        "sw_snow_pack",
        "sw_raingage",
        "sw_curve_control",
        #"sw_curve_diversion",
        "sw_curve_pump",
        "sw_curve_rating",
        "sw_curve_shape",
        "sw_curve_storage",
        "sw_curve_tidal",
        "sw_curve_weir",
        "sw_curve_underdrain",
        "sw_land_use",  
        "sw_pollutant",
        "sw_polygon",
        "sw_General_line",    
        "sw_spatial_rain_source",
        "sw_spatial_rain_zone",
        "sw_transect",
        "sw_tvd_connector",
        "sw_soil",
        "sw_2d_zone",
        "sw_mesh_zone",
        "sw_porous_polygon",
        "sw_porous_wall",
        "sw_roughness_zone",
        "sw_mesh_level_zone",
        "sw_roughness_definition",
        "sw_2d_boundary_line",
        "sw_head_unit_discharge"
      ]
      
      table_names.each do |table_name|
        hash_map = Hash.new { |h, k| h[k] = [] }
        table_rows = net.row_objects(table_name)
        raise "Error: #{table_name} not found" if table_rows.nil?
        number_of_rows = 0
        table_rows.each do |row|
          number_of_rows += 1
        end
        printf "%-50s %-d\n", "ICM SWMM Elements #{table_name}", number_of_rows
      end
        
rescue => e
    puts "Error: #{e.message}"
  end
  