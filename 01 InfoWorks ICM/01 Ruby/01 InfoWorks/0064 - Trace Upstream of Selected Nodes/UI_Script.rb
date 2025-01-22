net = WSApplication.current_network

# Get all subcatchments from the network
all_subs = net.row_object_collection('hw_subcatchment')

# Create a hash to map node IDs to their subcatchments
node_sub_hash_map = {}

# Get all nodes from the network
all_nodes = net.row_object_collection('hw_node')

# Initialize the hash with node IDs as keys and empty arrays as values
all_nodes.each do |node|
  node_sub_hash_map[node.node_id] = []
end

# Pair subcatchments to their corresponding nodes in the hash
all_subs.each do |sub|
  if sub.node_id != ''
    node_sub_hash_map[sub.node_id] << sub
  else
    sub.lateral_links.each do |link|
      node_sub_hash_map[link.node_id] ||= []
      node_sub_hash_map[link.node_id] << sub
    end
  end
end

# Get all selected nodes
roc = net.row_object_collection_selection('_nodes')

# Check if no nodes are selected
selected_nodes_count = 0
selected_nodes_list = []
roc.each do |ro|
  selected_nodes_count += 1
  selected_nodes_list << ro.node_id
end

if selected_nodes_count == 0
  puts "No nodes were selected. Select one or more nodes and rerun the script."
  return
end

# Array to keep track of unprocessed links
unprocessedLinks = []

# Counter for selected subcatchments
selected_subcatchments_count = 0

# Process each selected node
roc.each do |ro|
  # Add upstream links to unprocessedLinks array
  ro.us_links.each do |link|
    if !link._seen
      unprocessedLinks << link
      link._seen = true
    end
  end

  # Process unprocessed links
  while unprocessedLinks.size > 0
    # Take the first link and process it
    working = unprocessedLinks.shift
    working.selected = true
    workingUSNode = working.us_node

    if !workingUSNode.nil? && !workingUSNode._seen
      workingUSNode.selected = true
      # Select upstream subcatchments
      node_sub_hash_map[workingUSNode.id].each do |sub|
        sub.selected = true
        selected_subcatchments_count += 1
      end
      # Add upstream links of the current node to unprocessedLinks array
      workingUSNode.us_links.each do |link|
        if !link._seen
          unprocessedLinks << link
          link.selected = true
          link._seen = true
        end
      end
    end
  end
end

# Output the count of selected subcatchments and the list of selected nodes
puts "Subcatchments were selected upstream of these nodes:"
puts selected_nodes_list.join("\n")
puts "\n"
puts "Count of selected subcatchments: #{selected_subcatchments_count}"