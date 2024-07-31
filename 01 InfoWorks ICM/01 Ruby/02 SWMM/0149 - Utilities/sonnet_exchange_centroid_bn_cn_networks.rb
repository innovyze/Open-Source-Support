# This script performs various operations on a current network and a background network in InfoWorks ICM.
# It compares nodes between the current and background networks, copies node data from the background to the current network,
# finds unique objects in each network, finds nearby objects within a certain distance from a given point,
# calculates the centroid and farthest distance of nodes in a network, and finds nearby objects based on the centroid and farthest distance.
# The script requires the 'set' library.

require 'set'

# Get the current network
current_net = WSApplication.current_network

# Get the background network (if one is loaded)
background_net = WSApplication.background_network

# Check if a background network is loaded
if background_net.nil?
  puts "No background network loaded"
  exit
else
  puts "Background network is loaded"
end

def compare_nodes(current_net, background_net)
  puts "Comparing nodes between current and background networks:"
  
  current_nodes = current_net.row_objects('hw_node')
  
  current_nodes.each do |current_node|
    bg_node = background_net.row_object('sw_node', current_node.id)
    if bg_node
      if current_node.ground_level != bg_node.ground_level
        puts "Node #{current_node.id} ground level changed:"
        puts "  Current: #{current_node.ground_level}"
        puts "  Background: #{bg_node.ground_level}"
      end
    else
      puts "Node #{current_node.id} exists in current network but not in background"
    end
  end
end

def copy_node_data(current_net, background_net, field)
  puts "Copying #{field} from background to current network"
  
  current_net.transaction_begin
  
  current_nodes = current_net.row_objects('hw_node')
  current_nodes.each do |current_node|
    bg_node = background_net.row_object('sw_node', current_node.id)
    if bg_node && bg_node[field] != current_node[field]
      current_node[field] = bg_node[field]
      current_node.write
      puts "Updated #{field} for node #{current_node.id}"
    end
  end
  
  current_net.transaction_commit
end

def find_unique_objects(net1, net2, table1, table2)
  objects1 = net1.row_objects(table1)
  objects2 = net2.row_objects(table2)
  
  ids1 = objects1.map(&:id).to_set
  ids2 = objects2.map(&:id).to_set
  
  unique_to_1 = ids1 - ids2
  unique_to_2 = ids2 - ids1
  
  puts "Objects in #{table1} unique to first network:  #{unique_to_1.to_a}"
  puts "Objects in #{table2} unique to second network: #{unique_to_2.to_a}"
end

def find_nearby_objects(current_net, background_net, x, y, distance)
  puts "Finding objects within #{distance} meters of (#{x}, #{y}):"
  
  current_objects = current_net.search_at_point(x, y, distance, '_nodes')
  bg_objects = background_net.search_at_point(x, y, distance, '_nodes')
  
  puts "In current network:    #{current_objects.size} objects found"
  puts "In background network: #{bg_objects.size} objects found"
end

def distance(x1, y1, x2, y2)
  Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
end

def find_centroid_and_farthest_distance(network, table)
  nodes = network.row_objects(table)
  
  return { x: 0, y: 0, farthest_distance: 0 } if nodes.empty?
  
  sum_x = 0.0
  sum_y = 0.0
  
  nodes.each do |node|
    sum_x += node.x
    sum_y += node.y
  end
  
  centroid_x = sum_x / nodes.size
  centroid_y = sum_y / nodes.size
  
  farthest_distance = nodes.map { |node| distance(centroid_x, centroid_y, node.x, node.y) }.max
  
  { x: centroid_x, y: centroid_y, farthest_distance: farthest_distance }
end

# Example usage
if background_net
  compare_nodes(current_net, background_net)
  copy_node_data(current_net, background_net, 'ground_level')
  find_unique_objects(current_net, background_net, 'hw_node', 'sw_node')
  centroid_info = find_centroid_and_farthest_distance(current_net, 'hw_node')
  puts "Centroid of hw_node in current network: (#{centroid_info[:x]}, #{centroid_info[:y]})"
  puts "Farthest node distance from centroid: #{centroid_info[:farthest_distance]}"    
  # Use the centroid coordinates and the farthest distance for finding nearby objects
  find_nearby_objects(current_net, background_net, centroid_info[:x], centroid_info[:y], centroid_info[:farthest_distance])
end