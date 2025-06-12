# --- Load network ---
net = WSApplication.current_network

# Get selected node
selected_nodes = net.row_objects_selection('_nodes')

if selected_nodes.empty?
  puts 'No node selected. Please select one node and run the script again.'
  return
end

if selected_nodes.length > 1
  puts 'More than one node selected. Using the first one.'
end

start_node = selected_nodes.first
start_node_id = start_node.id

# Build upstream links map from hw_conduit, using conduit_length
upstream_links = Hash.new { |h, k| h[k] = [] }
net.row_objects('hw_conduit').each do |link|
  upstream_links[link.ds_node_id] << link
end

# Recursive function to find longest upstream path
def find_longest_path(node_id, upstream_links)
  return [0.0, []] unless upstream_links[node_id]

  max_length = 0.0
  best_path = []

  upstream_links[node_id].each do |link|
    us_id = link.us_node_id
    length = link.conduit_length.to_f rescue 0.0  # safely get length
    total_length, path = find_longest_path(us_id, upstream_links)
    total = length + total_length

    if total > max_length
      max_length = total
      best_path = path.dup
      best_path << link
    end
  end

  return [max_length, best_path]
end

# Run the search
total_length, longest_path = find_longest_path(start_node_id, upstream_links)

# Output the result
puts "Longest upstream path from node #{start_node_id} is #{total_length.round(2)} m and includes #{longest_path.length} links:"
longest_path.reverse.each_with_index do |link, i|
  puts "#{i+1}. Link ID: #{link.id}, From: #{link.us_node_id} to: #{link.ds_node_id}, Length: #{link.conduit_length}"
end

# Highlight the longest path in the network
net.clear_selection
longest_path.each do |link|
  link.selected = true
end

puts "The longest upstream path has been highlighted in the network."
