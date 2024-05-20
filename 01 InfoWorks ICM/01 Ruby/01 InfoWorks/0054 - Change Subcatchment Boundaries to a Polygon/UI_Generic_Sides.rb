# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Function to generate the boundary for a polygon with a given number of sides
def generate_polygon_boundary(boundary_array, sides)
    # Calculate the minimum and maximum x and y coordinates
    min_x = boundary_array.each_slice(2).map(&:first).min
    max_x = boundary_array.each_slice(2).map(&:first).max
    min_y = boundary_array.each_slice(2).map(&:last).min
    max_y = boundary_array.each_slice(2).map(&:last).max

    # Calculate the width and height
    width = max_x - min_x
    height = max_y - min_y

    # Calculate the points of the polygon
    polygon_boundary = []
    sides.times do |i|
        angle = 2 * Math::PI / sides * i
        x = min_x + width * 0.5 + width * 0.5 * Math.cos(angle)
        y = min_y + height * 0.5 + height * 0.5 * Math.sin(angle)
        polygon_boundary << x << y
    end
    polygon_boundary << polygon_boundary[0] << polygon_boundary[1]  # Close the shapet
    polygon_boundary
end

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Set the new boundary array
        sides = 5 
        polygon.boundary_array = generate_polygon_boundary(boundary_array, sides)  # Change the number of sides here
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit