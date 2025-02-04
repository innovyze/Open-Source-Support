# Get the current network object
net = WSApplication.current_network

# Initialize an empty hash to store IDs of selected runoff surfaces
selected_runoff_surfaces = {}

# Iterate through the selected rows in the hw_runoff_surface table
net.row_objects_selection('hw_runoff_surface').each do |rs|
  # Add the ID of the current row to the hash with a value of 0
  selected_runoff_surfaces[rs.id] = 0
end

# Initialize an empty hash to store IDs of selected land uses
selected_land_uses = {}

# Iterate through all the rows in the hw_land_use table
net.row_objects('hw_land_use').each do |lu|
  # Iterate through the fields runoff_index_1 to runoff_index_10
  (1..10).each do |i|
    # Get the value of the current field
    runoff_surface = lu["runoff_index_#{i}"]
    # If the field has a value
    if !runoff_surface.nil?
      # Check if the value is a key in the selected_runoff_surfaces hash
      if selected_runoff_surfaces.key?(runoff_surface)
        # If it is, add the ID of the current row to the selected_land_uses hash
        # with a value of 0 and set the selected field of the row to true
        selected_land_uses[lu.id] = 0
        lu.selected = true
      end
    end
  end
end

# Iterate through all the rows in the hw_subcatchment table
net.row_objects('hw_subcatchment').each do |s|
  # If the land_use_id field of the current row is a key in the selected_land_uses hash
  if selected_land_uses.key?(s.land_use_id)
    # Set the selected field of the row to true
    s.selected = true
  end
end
