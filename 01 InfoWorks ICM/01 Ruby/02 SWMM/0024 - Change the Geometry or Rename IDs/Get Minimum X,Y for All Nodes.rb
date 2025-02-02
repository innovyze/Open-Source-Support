# Modified from Innovyze Ruby Documentation

net = WSApplication.current_network

# Initialize the minimum and maximum x and y values to nil
min_x = nil
min_y = nil
max_x = nil
max_y = nil

# Iterate through the nodes in the network
net.row_objects('_nodes').each do |node|
  # Check if the x value of the current node is less than the current minimum x value
  if min_x.nil? || node.x < min_x
    # If so, update the minimum x value
    min_x = node.x
  end
  
  # Check if the x value of the current node is greater than the current maximum x value
  if max_x.nil? || node.x > max_x
    # If so, update the maximum x value
    max_x = node.x
  end

  # Check if the y value of the current node is less than the current minimum y value
  if min_y.nil? || node.y < min_y
    # If so, update the minimum y value
    min_y = node.y
  end
  
  # Check if the y value of the current node is greater than the current maximum y value
  if max_y.nil? || node.y > max_y
    # If so, update the maximum y value
    max_y = node.y
  end
end

# Output the minimum and maximum x and y values
puts "Minimum x, y: #{'%.3f' % min_x},   #{'%.3f' % min_y}"
puts "Maximum x, y: #{'%.3f' % max_x},   #{'%.3f' % max_y}"
puts 'Welcome to InfoWorks ICM Version ' + WSApplication.version
