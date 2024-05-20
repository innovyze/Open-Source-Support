net=WSApplication.current_network
net.clear_selection			## Clear current selection from network
net.load_selection 1778		## Load Selection List from database
selection_list=net.row_object_collection_selection('cams_manhole')	## Look at the cams_manhole objects from the current selection
bert=Array.new				## Create an array
selection_list.each do |s|	## Populate the array with the current selection
	bert << s
end
net.clear_selection

bert.each do |sel|			## Go through the array and do something
	puts sel.id
	sel.selected = true
end
