net = WSApplication.current_network
net.transaction_begin
net.row_object_collection('hw_polygon').each do |polygon|
    if polygon.selected?
        node = net.new_row_object('hw_node')
        x = polygon.boundary_array[0]
        y = polygon.boundary_array[1]
        node['node_id'] = polygon.id + '_node'
        node['x'] = x
        node['y'] = y
        node.write
    end
end
net.transaction_commit