# Node to Links

# Converts a node to a link - this could be made cleaner, but it works. The existing node is converted to the Upstream node
#
# @network [WSOpenNetwork]
# @node [WSNode] the node to convert
# @linktype [String] the type of link to convert into, this should be the WS Pro internal row name e.g. wn_pipe
# @prexix [String] What to append to the upstream node - not really a prefix
# @suffix [String] What to append to the new downstream node
# @return [WSLink] the WSLink that was created

def node2link (network, node, linktype, prefix, suffix)

	# Do some basic checks
	if network == nil || node == nil
		puts "Network (#{network}) or Node (#{node}) invalid."
		return nil
	elsif prefix == nil && suffix == nil
		puts "Failed to create Link from Node \'#{node.node_id}\' - Upstream and Downstream suffix cannot both be blank."
		return nil
	elsif linktype == nil
		puts "Failed to create Link from Node \'#{node.node_id}\' - no link type specified."
		return nil
	end

	# Determine connectivity
	if node.ds_links.length == 1 && node.us_links.length == 1
		# Link connectivity is straightforward - the node has 1 US and 1 DS link
		uslink = node.us_links[0]
		dslink = node.ds_links[0]
	elsif (node.ds_links.length + node.us_links.length) == 2
		# Link connectivity is complex - the node has 2 US or 2 DS links
		links = Array.new
		node.ds_links.each { |link| links << link }
		node.us_links.each { |link| links << link }

		# Does not apply any logic to determine US/DS
		uslink = links[0]
		dslink = links[1]

		# Flip the downstream link so that the rest of the code works as normal
		new_ds_node = dslink['us_node_id']
		dslink['us_node_id'] = dslink['ds_node_id']
		dslink['ds_node_id'] = new_ds_node
		dslink.write

		# Log what we just did
		puts "Flipped link - new link is \'#{dslink['us_node_id']}.#{dslink['ds_node_id']}.#{dslink['link_suffix']}\'"
	else
		puts "Failed to create Link from Node \'#{node.node_id}\' - does not have clear linkage. Probably has more than 3 links attached to node."
		return nil
	end

	oldnodename = node["node_id"]

	# Make the new downstream node
	newnode = network.new_row_object('wn_node')
	newnode['node_id'] = node["node_id"] + suffix
	newnode['x'] = node['x']
	newnode['y'] = node['y']
	newnode['z'] = node['z']

	# Make the new link
	newlink = network.new_row_object(linktype)
	newlink['us_node_id'] = node['node_id']
	newlink['ds_node_id'] = newnode['node_id']
	newlink['link_suffix'] = 1
	newlink['length'] = 1
	newlink['asset_id'] = node['asset_id']
	newlink['diameter'] = dslink['diameter']
	newlink['k'] = dslink['k']

	# Update the old node, clear the asset ID because only the link should have this ID
	node['asset_id'] = ''
	if prefix != nil then node['node_Id'] = node['node_Id'] + prefix end

	# Shift the DS link's US node to the new node we just made
	dslink['us_node_id'] = newnode['node_id']

	# Migrate user fields
	for i in 1...15 do
		# Move the data into the link
		newlink["user_text_#{i}"] = node["user_text_#{i}"]
		newlink["user_number_#{i}"] = node["user_number_#{i}"]

		# Clear the original node's data
		node["user_text_#{i}"] = ''
		node["user_number_#{i}"] = ''
	end

	# Write all our changes
	newnode.write # The new DS Node
	newlink.write
	node.write # The old node, which is now US
	dslink.write

	puts "Creating Link #{newlink['us_node_id']}.#{newlink['ds_node_id']}.1 (#{linktype}) from Node \'#{oldnodename}\' (Asset ID #{newlink.asset_id})"

	return newlink
end

# Main Function
# ------------------------------------------------------------------

network = WSApplication.current_network

# Confirm which nodes to convert
if network.selection_size > 0
	# Will exit the script if user presses cancel
	WSApplication.message_box("There are currently #{network.selection_size} object(s) selected - continue with this selection?", 'OKCancel', '?', true)
else
	WSApplication.message_box('There are no objects selected.', 'OK', '!', true)
	exit
end

# Prompt user for options
options = WSApplication.prompt("Node to Link Options",
	[
		["Link Type", "String", "wn_pipe"],
		["Upstream", "String", "_US"],
		["Downstream", "String", "_DS"],
		["Expand & Simplify", "Boolean",  true]
	],
	true)

network.transaction_begin

# Convert Nodes to Links - store the new links in an array
new_links = Array.new

network.row_objects_selection('_nodes').each do |node|
	link = node2link(network, node, options[0], options[1], options[2])
	if link != nil then new_links << link end
end

# Select just the new links
network.clear_selection
new_links.each do |link|
	link.selected = true
end

# Expand and simplify - expand_short_links works on the current network selection
if options[3] == true then
	network.expand_short_links({
		"Expansion threshold" => 1,
		"Minimum resultant length" => 1,
		"Protect connection points" => true,
		"Recalculate Length" => false,
		"Tables" => ["wn_pipe", "wn_valve", "wn_meter", "wn_non_return_valve"]
	})

	new_links.each do |link|
		link["bends"] = [
			link.us_node["X"],
			link.us_node["Y"],
			link.ds_node["X"],
			link.ds_node["Y"],
		]

		link.write
	end
end

network.transaction_commit
