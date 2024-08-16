## Compare the current network selection to a selection list, select the objects on the network which are in both
net=WSApplication.current_network
selected_nodes=net.row_object_collection_selection('cams_manhole')
fred=Array.new
selected_nodes.each do |s|
	fred << s
end
net.clear_selection
net.load_selection 1778
selection_list=net.row_object_collection_selection('cams_manhole')
bert=Array.new
selection_list.each do |s|
	bert << s
end
net.clear_selection

fred.each do |ro|
	bert.each do |sel|
	
		if sel.id.to_s == ro.id.to_s

			sel.selected = true
		end
	end
end  