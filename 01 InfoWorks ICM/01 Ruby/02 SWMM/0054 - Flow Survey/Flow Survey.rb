
net=WSApplication.current_network


def ustrace(link)
	link._seen=true
	unprocessedLinks=Array.new
	unprocessedLinks<<link
	uslinks=Array.new
	uslinks<<link
	usnodes=Array.new
	
	
	while unprocessedLinks.size>0
		working=unprocessedLinks.shift
		workingUSNode=working.us_node
		if !workingUSNode.nil? && !workingUSNode._seen
			usnodes<<workingUSNode
			workingUSNode._seen=true
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					uslinks<<l
					l._seen=true
				end
			end
		end
	end
	return [usnodes,uslinks]
end
val=WSApplication.prompt "Flow Monitor Input Dialog Box",
[
['ID of Master Group or Model Group where selection list will be saved','String'],
['Above ID is of Master Group/ Model Group?','String','Model group',nil,'LIST',['Model group','Master group']]
],true
db=WSApplication.current_database
mo=db.model_object_from_type_and_id(val[1],val[0].to_i)
flow_monitors_links=net.row_objects_selection('_links')
flow_monitors_links.each do |z|
	z._seen=true
end
flow_monitors_links.each do |n|
	net.clear_selection
	us_array=ustrace(n)
	
	nodes_roc=us_array[0]
	nodes_roc.each do |a|
		a.selected=true
	end
	
	links_roc=us_array[1]
	links_roc.each do |b|
		b.selected=true
	end
	
	#Slecting U/S subcatchments 
	subs_all=net.row_objects('_subcatchments')
	net.row_objects_selection('_nodes').each do |d| 
		subs_all.each do |c|
			if c.drains_to=="Node" && c.node_id==d.node_id
				c.selected=true
			end
		end
	end
	child=mo.new_model_object('Selection list',n.us_node_id+"."+n.link_suffix)
	net.save_selection child
	net.clear_selection
end
