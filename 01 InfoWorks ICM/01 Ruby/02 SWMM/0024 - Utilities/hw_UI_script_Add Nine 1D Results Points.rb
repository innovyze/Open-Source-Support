
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection
    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?

    net.transaction_begin

    # Define the percentages at which to add result points
    percentages = [10, 20, 30, 40, 50, 60, 70, 80, 90]

    # Iterate through the selected links
    net.row_objects('hw_conduit').each do |ro|
        next unless ro.selected
    
        # Get the upstream and downstream nodes
        us_node_id = ro.us_node_id
        ds_node_id = ro.ds_node_id
        us_node = net.row_object('hw_node', us_node_id)
        ds_node = net.row_object('hw_node', ds_node_id)
    
        # Get the x, y coordinates of the upstream and downstream nodes
        us_x, us_y = us_node.x, us_node.y
        ds_x, ds_y = ds_node.x, ds_node.y
    
        # Iterate through the percentages
        percentages.each do |percentage|
        # Calculate the position along the link at which to add the result point
        position_x = us_x + (ds_x - us_x) * (percentage / 100.0)
        position_y = us_y + (ds_y - us_y) * (percentage / 100.0)
    
        # Create a new hw_1d_results_point
        result_point = net.new_row_object('hw_1d_results_point')
    
        # Set the properties of the new hw_1d_results_point
        result_point.point_id = "#{us_node_id}_#{percentage}"
        result_point.point_x = position_x
        result_point.point_y = position_y
        result_point.link_suffix = ro.link_suffix
        result_point.us_node_id = us_node_id
        result_point.start_length = ro.conduit_length * (percentage / 100.0)
    
        # Write the new hw_1d_results_point to the database
        result_point.write
        end
    end

    net.transaction_commit
    # clear selection
    net.clear_selection
  
rescue => e
    puts "Error: #{e.message}"
end