# Node to Links

# Converts a node to a link - the existing node is converted to the Upstream node
#
# network (WSOpenNetwork) - the network, needed to generate new objects
# node (WSNode) - the node to convert into a link
# link_type (String) - the type of link to convert to, this should be the WS Pro internal row name e.g. wn_pipe
# us_suffix (String) - Suffix to append to the upstream node
# ds_suffix (String) - Suffix to append to the downstream node
# migrate_fields (Boolean) - Whether to migrate the user fields from the existing node to the new link
#
# Returns the new link (WSLink)
def node2link (network: , node: , link_type: 'wn_pipe', us_suffix: '_US', ds_suffix: '_DS', flag: nil, migrate_fields: true)

	# Do some basic checks on the input
	if network.nil? then
		raise "Network (#{network}) invalid"
	elsif node.nil? then
		puts "Node object invalid"
		return nil
	elsif us_suffix.nil? || ds_suffix.nil? then
		puts "Failed to create Link from Node \'#{node.node_id}\' - Upstream and Downstream suffix cannot be blank"
		return nil
	elsif link_type.nil? then
		puts "Failed to create Link from Node \'#{node.node_id}\' - no link type specified"
		return nil
	end

	us_count = node.us_links.length
	ds_count = node.ds_links.length

	# Determine and fix connectivity
	if us_count == 1 && ds_count == 1 then
		# Link connectivity is straightforward - the node has 1 US and 1 DS link
	elsif us_count == 2 && ds_count == 0 then
		# We need to flip one of the US links
		reverse_link(node.us_links[0])
	elsif ds_count == 2 && us_count == 0 then
		# We need to flip one of the DS links
		reverse_link(node.ds_links[0])
	else
		puts "Failed to create Link from Node \'#{node.node_id}\' - does not have clear linkage. Probably has more than 3 links attached to node."
		return nil
	end

	us_link = node.us_links[0]
	ds_link = node.ds_links[0]

	old_node_id = node["node_id"]
	us_node = node

	# Make the new downstream node
	ds_node = network.new_row_object('wn_node')
	ds_node['node_id'] = us_node["node_id"] + ds_suffix
	ds_node['node_id_flag'] = flag

	fields = ['x', 'y', 'z']
	fields.each do |field|
		ds_node[field] = us_node[field]
		ds_node[field + '_flag'] = flag
	end

	# Shift the DS link's US node to the new node we just made
	ds_link['us_node_id'] = ds_node['node_id']

	# Make the new link
	newlink = network.new_row_object(link_type)
	newlink['us_node_id'] = us_node['node_id']
	newlink['us_node_id_flag'] = flag
	newlink['ds_node_id'] = ds_node['node_id']
	newlink['ds_node_id_flag'] = flag
	newlink['link_suffix'] = 1
	newlink['link_suffix_flag'] = flag
	newlink['length'] = 1
	newlink['length_flag'] = flag
	newlink['asset_id'] = us_node['asset_id']
	newlink['asset_id_flag'] = flag

	fields = ['diameter', 'roughness_type', 'k', 'hazen_williams', 'darcy_weissbach']
	fields.each do |field|
		newlink[field] = ds_link[field]
		newlink[field + '_flag'] = flag
	end

	# Update the old node, clear the asset ID because only the link should have this ID
	us_node['asset_id'] = nil
	us_node['node_id'] = us_node['node_id'] + us_suffix

	# Migrate user fields
	if migrate_fields then
		for i in 1...15 do
			# Move the data into the link
			newlink["user_text_#{i}"] = us_node["user_text_#{i}"]
			newlink["user_number_#{i}"] = us_node["user_number_#{i}"]

			# Clear the original node's data
			us_node["user_text_#{i}"] = ''
			us_node["user_number_#{i}"] = ''
		end
	end

	# Write all our changes
	ds_node.write # The new DS Node
	newlink.write
	us_node.write # The old (now US) node
	ds_link.write

	puts "Creating Link #{newlink['us_node_id']}.#{newlink['ds_node_id']}.1 (#{link_type}) from Node \'#{old_node_id}\' (Asset ID #{newlink.asset_id})"

	return newlink
end

def reverse_link (link)
	old_bends = link["bends"]
	new_bends = Array.new
	while !old_bends.empty?
		new_bends.concat(old_bends.pop(2))
	end

	old_us_id = link["us_node_id"]
	link["us_node_id"] = link["ds_node_id"]
	link["ds_node_id"] = old_us_id
	link["bends"] = new_bends

	link.write

	puts "Flipped link - new link is \'#{link['us_node_id']}.#{link['ds_node_id']}.#{link['link_suffix']}\'"
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
options = WSApplication.prompt(
	"Node to Link Options",
	[
		["Link Type", "String", "wn_pipe"],
		["Upstream Suffix", "String", "_US"],
		["Downstream Suffix", "String", "_DS"],
		["Flag", "String", "NL"],
		["Migrate User Fields", "Boolean",  true],
		["Expand & Simplify", "Boolean",  true]
	],
	true)

network.transaction_begin

# Convert Nodes to Links - store the new links in an array
new_links = Array.new

network.row_objects_selection('_nodes').each do |node|
	link = node2link(
		network: network,
		node: node,
		link_type: options[0],
		us_suffix: options[1],
		ds_suffix: options[2],
		flag: options[3],
		migrate_fields: options[4]
	)

	new_links << link unless link.nil?
end

# Select just the new links
network.clear_selection
new_links.each { |link| link.selected = true }

# Expand and simplify - expand_short_links works on the current network selection
if options[5] then
	network.expand_short_links({
		"Expansion threshold" => 1,
		"Minimum resultant length" => 1,
		"Protect connection points" => true,
		"Recalculate Length" => false,
		"Flag" => options[3],
		"Tables" => [options[0]]
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
