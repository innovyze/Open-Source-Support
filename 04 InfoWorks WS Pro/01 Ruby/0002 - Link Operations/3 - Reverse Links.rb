# Reverse Selected Links

network = WSApplication.current_network

network.transaction_begin

network.row_objects_selection("_links").each do |link|
	# Cache the bends (geometry of the line) - when we switch the US and DS nodes, WS Pro
	# will automatically switch the first and last bends too, it's easier for us to ignore that
	# and work from the original geometry
	bends = link["bends"]

	# Flip the Upstream and Downstream nodes
	# We have to cache one of the values as we do this
	old_id = link["us_node_id"]
	link["us_node_id"] = link["ds_node_id"]
	link["ds_node_id"] = old_id

	link["bends"] = bends.rotate(2)

	link.write
end

network.transaction_commit
