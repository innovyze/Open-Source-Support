# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_polygon').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the centroid of the polygon
        centroid_x = boundary_array.each_slice(2).map(&:first).sum / (boundary_array.size / 2)
        centroid_y = boundary_array.each_slice(2).map(&:last).sum / (boundary_array.size / 2)

        # Create a new node at the centroid for a SWMM model use sw_node
        centroid_node = net.new_row_object('hw_node')
        centroid_node['node_id'] = polygon.id + '_centroid'
        centroid_node['x'] = centroid_x
        centroid_node['y'] = centroid_y
        centroid_node.write

        # Create a new node at each vertex
        boundary_array.each_slice(2).with_index do |(x, y), index|
            vertex_node = net.new_row_object('hw_node')
            vertex_node['node_id'] = "#{polygon.id}_vertex_#{index}"
            vertex_node['x'] = x
            vertex_node['y'] = y
            vertex_node.write
        end
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit