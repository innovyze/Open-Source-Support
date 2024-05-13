# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
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

        # Calculate the width and height
        width = max_x - min_x
        height = max_y - min_y

        # Calculate the center point
        center_x = min_x + width / 2
        center_y = min_y + height / 2

        # Calculate the radius
        radius = [width, height].min / 2

        # Create a new boundary array for the pentagon
        pentagon_boundary = []
        5.times do |i|
            angle = 2 * Math::PI / 5 * i
            x = center_x + radius * Math.cos(angle)
            y = center_y + radius * Math.sin(angle)
            pentagon_boundary << x << y
        end

        # Set the new boundary array
        polygon.boundary_array = pentagon_boundary
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit