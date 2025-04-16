cn = WSApplication.current_network

begin
  # Prompt the user for the new runoff coefficient value
  new_coefficient_str = WSApplication.prompt("Enter new runoff coefficient value:",
    [
      ['Runoff coefficient', 'String']
    ], false
  )
  puts "New coefficient: #{new_coefficient_str}"
  
  new_coefficient = 0.5

  # Additional validation: if the string is not a valid number, to_f returns 0.0.
  # So if the string is not "0" (trimmed) and the float is zero, treat that as error.
  if new_coefficient == 0.0 && new_coefficient_str.strip != "0"
    puts "Error: Please enter a valid numeric value"
    exit
  end

  # Initialize counter for changed runoff surfaces
  changed_count = 0

  # Begin transaction
  cn.transaction_begin

  # Get all runoff surfaces once for efficiency
  runoff_surfaces = cn.row_objects('hw_runoff_surface')
  land_uses = cn.row_objects('hw_land_use')

  # Iterate through selected subcatchments
  cn.row_objects_selection('hw_subcatchment').each do |subcatchment|
    landuse_id = subcatchment.land_use_id
    
    # Find matching land use
    matching_landuse = land_uses.find { |lu| lu.land_use_id == landuse_id }
    
    if matching_landuse
      runoff_surface_id = matching_landuse.runoff_index_1
      puts "Found runoff index: #{runoff_surface_id}"

      # Find and update matching runoff surface
      matching_surface = runoff_surfaces.find { |rs| rs.id == runoff_surface_id }
      
      if matching_surface
        puts "Old coefficient: #{matching_surface.runoff_coefficient}"
        matching_surface.runoff_coefficient = new_coefficient
        matching_surface.write
        changed_count += 1
      else
        puts "Warning: No matching runoff surface found for ID: #{runoff_surface_id}"
      end
    else
      puts "Warning: No matching land use found for ID: #{landuse_id}"
    end
  end

  # Commit the transaction
  cn.transaction_commit
  puts "#{changed_count} runoff surfaces were updated"
end