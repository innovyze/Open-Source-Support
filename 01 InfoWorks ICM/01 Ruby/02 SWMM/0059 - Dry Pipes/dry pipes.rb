#Below script selects all dry pipes in a ICM model network
# the code is from https://github.com/chaitanyalakeshri/ruby_scripts
# modifed by CHATGPT and RED

net=WSApplication.current_network
net.clear_selection

#creating an array to store drainage node id of subcatchments
node_id=Array.new

subs_all=net.row_object_collection('_subcatchments')
subs_all.each do |a|
	node_id<<a.node_id
end
unprocessed_links=Array.new
node_id.each do |x|
	a=net.row_object('hw_node',x)
	a.ds_links.each do |l|
		unprocessed_links<<l	
	end
	while unprocessed_links.size>0
		working=unprocessed_links.shift
		working._seen=true
		working_ds_node=working.ds_node
		if !working_ds_node._seen && !working_ds_node.nil?
			working_ds_node._seen=true
			working_ds_node.ds_links.each do |b|
				unprocessed_links<<b
			end
		end
	end
end
all_links=net.row_object_collection('_links')
all_links.each do |d|
	if !d._seen
		d.selected=true
		d.us_node.selected=true
	end
end
