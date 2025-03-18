require 'set'

# Get the current network from the application
net = WSApplication.current_network

begin
  # Use Set instead of Hash since we only need unique IDs (more memory efficient)
  selected_runoff_surfaces = Set.new
  selected_land_uses = Set.new

  # Get selected runoff surfaces
  net.row_objects_selection('hw_runoff_surface').each do |rs|
    selected_runoff_surfaces << rs.id.to_s
  end

  # Process land uses
  net.row_objects('hw_land_use').each do |lu|
    has_matching_runoff = (1..12).any? do |i|
      runoff_surface = lu["runoff_index_#{i}"]
      runoff_surface && selected_runoff_surfaces.include?(runoff_surface.to_s)
    end
    
    if has_matching_runoff
      selected_land_uses << lu.id.to_s
      lu.selected = true
    end
  end

  # Process subcatchments
  net.row_objects('hw_subcatchment').each do |s|
    s.selected = true if selected_land_uses.include?(s.land_use_id.to_s)
  end

  # Calculate and display statistics
  all_subcatchments = net.row_objects('hw_subcatchment')
  selected_subcatchments = all_subcatchments.select(&:selected)
  
  all_land_uses = net.row_objects('hw_land_use')
  all_runoff_surfaces = net.row_objects('hw_runoff_surface')

  # Output results
  puts "Total Subcatchments: #{all_subcatchments.size}"
  puts "Selected Subcatchments: #{selected_subcatchments.size}"
  puts "Total Land Uses: #{all_land_uses.size}"
  puts "Selected Land Uses: #{selected_land_uses.size}"
  puts "Selected Land Use IDs: #{selected_land_uses.to_a.join(', ')}"
  puts "Total Runoff Surfaces: #{all_runoff_surfaces.size}"

rescue StandardError => e
  puts "Error occurred: #{e.message}"
  puts e.backtrace.join("\n")
end