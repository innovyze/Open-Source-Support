net = WSApplication.current_network
roc = net.row_object_collection_selection('_links')
unprocessedLinks = Array.new
roc.each do |ro|
	ro.us_node.us_links.each do |l|
		if !l._seen
			unprocessedLinks << l
			l.us_node.selected = true
			l._seen = true
		end
	end
	while unprocessedLinks.size > 0
		working = unprocessedLinks.shift
		working.selected = true
		workingDSNode = working.us_node
		if !workingDSNode.nil? && !workingDSNode._seen
			workingDSNode.selected = true
			workingDSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					l.selected = true
					l._seen = true
				end
			end
		end
	end
end
