begin
  # Accessing the current network
  net = WSApplication.current_network
  raise "Error: Current network not found" if net.nil?

  # Define a method to get network elements with their IDs
  def get_network_elements_with_ids(network, object_type)
    elements = network.row_objects(object_type)
    return nil if elements.nil?
    
    # Collect IDs for each element
    ids = []
    elements.each do |element|
      # Try different common ID field names
      id = nil
      if element.respond_to?(:id)
        id = element.id
      elsif element.respond_to?(:us_node_id)
        id = element.us_node_id
      elsif element.respond_to?(:node_id)
        id = element.node_id
      elsif element.respond_to?(:link_id)
        id = element.link_id
      elsif element.respond_to?(:name)
        id = element.name
      elsif element.respond_to?(:descriptor)
        id = element.descriptor
      end
      
      ids << (id || "Unknown ID")
    end
    
    return ids
  end

  # Define a helper for formatted output
  def format_table_output(table_name, ids)
    output = "\n#{table_name.split('_').map(&:capitalize).join(' ')} (Count: #{ids.length}):\n"
    output += "-" * 80 + "\n"
    
    if ids.length > 0
      # Sort IDs for better readability
      sorted_ids = ids.sort
      
      # Display 5 IDs per row
      sorted_ids.each_slice(5).with_index do |row_ids, row_index|
        row_output = ""
        row_ids.each_with_index do |id, col_index|
          item_number = row_index * 5 + col_index + 1
          # Format each ID with consistent width for alignment
          row_output += sprintf("%-3d. %-15s", item_number, id.to_s[0..14])
        end
        output += "  #{row_output}\n"
      end
    else
      output += "  No elements found\n"
    end
    
    output += "\n"
    return output
  end

  # Collect results in a string
  results = "Network Element Parameter IDs:\n"
  results += "=" * 50 + "\n"

  # Define all HW_ tables
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

  # Process each table
  table_data = []
  
  tables.each do |table|
    ids = get_network_elements_with_ids(net, table)
    if ids && ids.length > 0
      table_data << [table, ids]
    end
  end
  
  # Sort tables by element count (descending)
  table_data.sort_by! { |_, ids| -ids.length }
  
  # Add sorted results to the output
  table_data.each do |table, ids|
    results += format_table_output(table, ids)
  end
  
  # Summary at the end
  results += "=" * 50 + "\n"
  results += "Total tables with elements: #{table_data.length}\n"
  results += "Total elements across all tables: #{table_data.sum { |_, ids| ids.length }}\n"
  
  # Output results
  puts results
  
  # For large results, you might want to save to a file instead of showing in message box
  if results.length > 10000
    # Save to file
    filename = "network_elements_ids_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt"
    File.open(filename, 'w') { |f| f.write(results) }
    WSApplication.message_box("Results saved to: #{filename}", 'OK', 'Information', '')
  else
    WSApplication.message_box(results, 'OK', 'Information', '')
  end

rescue => e
  error_msg = "Error: #{e.message}\n#{e.backtrace.join("\n")}"
  puts error_msg
  WSApplication.message_box(error_msg, 'OK', 'Error', '')
end