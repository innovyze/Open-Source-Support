# Product		InfoWorks WS Pro - UI & EX
# Script Name	Node to Link
# Description	Creates a link from the currently selected node (UI)

# Main Function	node2link
# Arguments		network - network to work on
#				node - WSRowObject - the node object to generate a link from
#				linktype - string - the type of link to create e.g. wn_pipe
#				prefix* - string - added to the US node (the one provided to the method)
#				suffix* - string - added to the DS node (the one generated)

# Method(s)
#-------------------------------------------------------------------
def node2link (network, node, linktype='wn_pipe', prefix='_US', suffix='_DS')

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

		# Clear the node's data
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

# UI / Exchange Switch
#-------------------------------------------------------------------
if WSApplication.ui?
	network=WSApplication.current_network

	# What nodes to convert?
	if network.selection_size > 0
		# Will exit the script if user presses cancel
		WSApplication.message_box("There are currently #{network.selection_size} object(s) selected - continue with this selection?", 'OKCancel', '?', true)
	else
		WSApplication.message_box('There are no objects selected.', 'OK', '!')
		exit
	end

	# Iterate over every selected node to create the links
	newlinks = Array.new
	network.transaction_begin

	network.row_objects_selection('wn_node').each do |n|
		newlink = node2link(network, n)
		if newlink != nil then newlinks << newlink end
	end

	network.transaction_commit

	#Clear the selection of nodes, and select the new links instead (so we can do stuff to them in the UI)
	network.clear_selection

	newlinks.each do |link|
		link.selected = true
	end
end