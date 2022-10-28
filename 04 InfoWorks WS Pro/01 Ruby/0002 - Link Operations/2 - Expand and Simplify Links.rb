# Expand and Simplify Selected Links

network = WSApplication.current_network

network.transaction_begin

network.expand_short_links({
  "Expansion threshold" => 1,
  "Minimum resultant length" => 1,
  "Protect connection points" => true,
  "Recalculate Length" => false,
  "Tables" => ["wn_pipe", "wn_valve", "wn_meter", "wn_non_return_valve"]
})

network.row_objects_selection("_links").each do |link|
	# The bends array is a linear X, Y, X, Y etc
	link["bends"] = [
		link.us_node["X"],
		link.us_node["Y"],
		link.ds_node["X"],
		link.ds_node["Y"],
	]

	link.write
end

network.transaction_commit
