net=WSApplication.current_network
net.clear_selection
ro=net.row_objects('_nodes').each do |ro|
	if ro.us_links.length==0 && ro.ds_links.length==0 && ro.navigate('lateral_pipe').size==0
		ro.selected=true
	end
end
