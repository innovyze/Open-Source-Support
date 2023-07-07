# net variable is assigned the current network of the WSApplication
# the hash code is from https://github.com/chaitanyalakeshri/ruby_scripts and 
# the tree walking code is from Unit 5 from https://github.com/innovyze/Open-Source-Support/tree/main/01%20InfoWorks%20ICM/01%20Ruby
net = WSApplication.current_network

# Get all subcatchments from the network and assign them to the variable all_subs
all_subs=net.row_objects('_subcatchments')

# Create an empty hash variable named node_sub_hash_map
node_sub_hash_map={}

# Get all nodes from the network and assign them to the variable all_nodes
all_nodes=net.row_objects('_nodes')

# Assign node ID's as hash keys in the node_sub_hash_map
all_nodes.each do |h|
	node_sub_hash_map[h.node_id]=[]
end

# Get all subcatchments again and assign them to the variable all_subs
all_subs=net.row_objects('_subcatchments')

# Pair subcatchments to appropriate hash keys (i.e. node id's) in the node_sub_hash_map
node_sub_hash_map = Hash.new { |h, k| h[k] = [] }
all_subs.each do |subb|
  node_sub_hash_map[subb.node_id] << subb
end

# Get all the selected rows in the _nodes collection and assign them to the variable roc
roc = net.row_object_collection_selection('_nodes')

# Create an empty array named unprocessedLinks
unprocessedLinks = Array.new

# Initialize a counter variable for the total number of subcatchments and a variable for the total are
total_subcatchments = 0
total_area = 0.0

roc.each do |ro|
	# Iterate through all the upstream links of the current row object
	ro.us_links.each do |l|
		# if the link has not been seen before, add it to the unprocessedLinks array
		if !l._seen
			unprocessedLinks << l
			l._seen=true
		end
	end
	# While there are still unprocessed links in the array
	while unprocessedLinks.size>0
		# take the first link in the array and assign it to the variable working
		working = unprocessedLinks.shift
		working.selected=true
		# get the upstream node of the current link
		workingUSNode = working.us_node
		# if the upstream node is not nil and has not been seen before
		if !workingUSNode.nil? && !workingUSNode._seen
			workingUSNode.selected=true
			# Now that hash is ready with node id's as key and upstream subcatchments as paired values, keys can be used to get an array containing upstream subcathments
			# In the below code id's of subcatchments upstream of node 'node_1' are printed. The below code can be reused multiple times for different nodes within the script without being computationally expensive
			node_sub_hash_map[workingUSNode.id].each  do |sub|
				# puts "Found Upstream Subcatchment #{sub.id} connected to Node #{workingUSNode.id}"
				total_area += sub.total_area
				total_subcatchments += 1
				sub.selected=true
			end
			# Iterate through all the upstream links of the current node and add them to the unprocessedLinks array
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					l.selected=true
					l._seen=true
				end
			end
		end
	end
end

# Print the total number of subcatchments and the total area
puts "Total number of found Subcatchments: #{total_subcatchments}"
puts "Total area of found Subcatchments: #{total_area.round(4)}"
