net = WSApplication.current_network
nodes = Array.new
net.row_object_collection('hw_node').each do |n|
  if n.selected?
    temp = Array.new
    temp << n.id
    temp << n.x
    temp << n.y
    temp << n.system_type
    temp << n.ground_level # Assuming ground_level is an attribute of the node
    nodes << temp
  end
end

net.transaction_begin
changed_nodes_count = 0

net.row_object_collection('hw_subcatchment').each do |s|
  if s.selected?
    node_system_type = ''
    sx = s.x
    sy = s.y
    nearest_distance = 999999999.9
    nearest_storm_distance = 999999999.9
    nearest_foul_distance = 999999999.9
    nearest_sanitary_distance = 999999999.9
    nearest_combined_distance = 999999999.9
    nearest_overland_distance = 999999999.9
    nearest_other_distance = 999999999.9

    # Array to store nodes with their distances
    nodes_with_distances = []

    (0...nodes.size).each do |i|
      nx = nodes[i][1]
      ny = nodes[i][2]
      n_id = nodes[i][0]
      distance = ((sx - nx) * (sx - nx)) + ((sy - ny) * (sy - ny))
      node_system_type = nodes[i][3].downcase
      ground_level = nodes[i][4] # Assuming ground_level is the 5th element in the nodes array

      # Store the node with its distance
      nodes_with_distances << { id: n_id, distance: distance, system_type: node_system_type, ground_level: ground_level }
    end

    # Sort the nodes based on distance
    sorted_nodes = nodes_with_distances.sort_by { |node| node[:distance] }

    # Select the nearest 5 nodes
    nearest_5_nodes = sorted_nodes.first(5)

    # Print the sorted nodes and their ground levels
    #puts "Sorted nodes and their ground levels:"
    #nearest_5_nodes.each do |node|
      #puts "Node ID: #{node[:id]}, Distance: #{node[:distance]}, Ground Level: #{node[:ground_level]}"
    #end

    # Find the node with the lowest ground level among the nearest 5 nodes
    lowest_ground_level_node = nearest_5_nodes.min_by { |node| node[:ground_level] }

    # Update the subcatchment with the nearest node with the lowest ground level
    if lowest_ground_level_node
      s.node_id = lowest_ground_level_node[:id]
      changed_nodes_count += 1
    end

    s.write
  end
end

net.transaction_commit

puts "Number of nodes checked: #{changed_nodes_count}"