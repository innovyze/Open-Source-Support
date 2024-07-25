# Get the current network
current_net = WSApplication.current_network

# Get the background network (if one is loaded)
background_net = WSApplication.background_network

# Check if a background network is loaded
if background_net.nil?
  puts "No background network loaded"
else
  puts "Background network is loaded"
end

def compare_nodes(current_net, background_net)
    puts "Comparing nodes between current and background networks:"
    
    current_nodes = current_net.row_objects('hw_node')
    background_nodes = background_net.row_objects('sw_node')
    
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
  
  # Use the function if a background network is loaded
  if background_net
    compare_nodes(current_net, background_net)
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
  
  # Use the function if a background network is loaded
  if background_net
    copy_node_data(current_net, background_net, 'ground_level')
  end

  def (net1, net2, table)
    objects1 = net1.row_objects(table)
    objects2 = net2.row_objects(table)
    
    ids1 = objects1.map(&:id).to_set
    ids2 = objects2.map(&:id).to_set
    
    unique_to_1 = ids1 - ids2
    unique_to_2 = ids2 - ids1
    
    puts "Objects in #{table} unique to first network: #{unique_to_1.to_a}"
    puts "Objects in #{table} unique to second network: #{unique_to_2.to_a}"
  end
  
  # Use the function if a background network is loaded
  if background_net
    find_unique_objects(current_net, background_net, 'hw_node')
    find_unique_objects(current_net, background_net, 'sw_node')
  end

  def find_nearby_objects(current_net, background_net, x, y, distance)
    puts "Finding objects within #{distance} meters of (#{x}, #{y}):"
    
    current_objects = current_net.search_at_point(x, y, distance, '_nodes')
    bg_objects = background_net.search_at_point(x, y, distance, '_nodes')
    
    puts "In current network:"
    current_objects.each { |obj| puts "  #{obj.id}" }
    
    puts "In background network:"
    bg_objects.each { |obj| puts "  #{obj.id}" }
  end
  
  # Use the function if a background network is loaded
  if background_net
    find_nearby_objects(current_net, background_net, 100000, 200000, 50)
  end


  