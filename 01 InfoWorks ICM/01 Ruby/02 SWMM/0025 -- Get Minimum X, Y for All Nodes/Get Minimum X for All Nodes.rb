# Modified from Innovyze Ruby Documentation

net = WSApplication.current_network

# Initialize the minimum x and y values to nil
min_x = nil
min_y = nil

# Iterate through the nodes in the network
net.row_objects('_nodes').each do |node|
  # Check if the x value of the current node is less than the current minimum x value
  if min_x.nil? || node.x < min_x
    # If so, update the minimum x value
    min_x = node.x
    # Check if the y value of the current node is less than the current minimum y value
    if min_y.nil? || node.y < min_y
      # If so, update the minimum y value
      min_y = node.y
    end
  end
end

# Output the minimum x and y values
puts "Minimum x, y: #{min_x}, #{min_y}"
puts 'Welcome to InfoWorks ICM Version '+WSApplication.version
