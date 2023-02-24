# Reverse Selected Links

network = WSApplication.current_network

network.transaction_begin

network.row_objects_selection("_links").each do |link|
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
end

network.transaction_commit
