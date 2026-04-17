net=WSApplication.current_network
net.transaction_begin

net.row_objects_selection('_nodes').each do |ro|
	ro.autoname
	ro.write
end

net.row_objects_selection('_links').each do |ro|
	ro.autoname
	ro.write
end

net.transaction_commit
