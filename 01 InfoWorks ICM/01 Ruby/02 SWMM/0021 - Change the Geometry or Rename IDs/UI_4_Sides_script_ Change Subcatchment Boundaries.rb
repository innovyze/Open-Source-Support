# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_2d_infiltration_zone').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the minimum and maximum x and y coordinates
        min_x = boundary_array.each_slice(2).map(&:first).min
        max_x = boundary_array.each_slice(2).map(&:first).max
        min_y = boundary_array.each_slice(2).map(&:last).min
        max_y = boundary_array.each_slice(2).map(&:last).max
        puts "Subcatchment ID: #{polygon.id} | Min X: #{min_x} | Max X: #{max_x} | Min Y: #{min_y} | Max Y: #{max_y}"

        # Create a new boundary array for the rectangle
        rectangle_boundary = [min_x, min_y, max_x, min_y, max_x, max_y, min_x, max_y, min_x, min_y]

        # Set the new boundary array
        polygon.boundary_array = rectangle_boundary
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit