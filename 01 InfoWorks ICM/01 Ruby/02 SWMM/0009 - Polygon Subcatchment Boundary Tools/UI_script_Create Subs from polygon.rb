# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
      # Get the boundary array of the polygon
      boundary_array = polygon.boundary_array
  
      # Calculate the centroid of the polygon
      centroid_x = boundary_array.each_slice(2).map(&:first).sum / (boundary_array.size / 2)
      centroid_y = boundary_array.each_slice(2).map(&:last).sum / (boundary_array.size / 2)
  
      # Calculate the width and height of the polygon
      width = boundary_array.each_slice(2).map(&:first).max - boundary_array.each_slice(2).map(&:first).min
      height = boundary_array.each_slice(2).map(&:last).max - boundary_array.each_slice(2).map(&:last).min
  
      # Calculate the coordinates of the 4 quadrants
      quadrant_1 = [centroid_x, centroid_y, centroid_x + width / 2, centroid_y + height / 2]
      quadrant_2 = [centroid_x, centroid_y, centroid_x - width / 2, centroid_y + height / 2]
      quadrant_3 = [centroid_x, centroid_y, centroid_x - width / 2, centroid_y - height / 2]
      quadrant_4 = [centroid_x, centroid_y, centroid_x + width / 2, centroid_y - height / 2]
            puts quadrant_1
            puts quadrant_2
      # Create new polygons for each quadrant
      # [quadrant_1, quadrant_2, quadrant_3, quadrant_4].each_with_index do |quadrant, index|
        new_polygon = net.new_row_object('hw_subcatchment')
        new_polygon['subcatchment_id'] = "#{subcatchment.id}#{index + 1}"
        new_polygon['boundary_array'] << quadrant_1
        new_polygon['boundary_array'] << quadrant_2
        new_polygon['boundary_array'] << quadrant_3
        new_polygon['boundary_array'] << quadrant_4
        new_polygon.write
      end
    end

# Commit the transaction, making all changes permanent
net.transaction_commit