## Trace upstream of Node with 'EX' in the node_id [line 12], find Node with 'DO' in the node_id [line 27], write DO Node ID to start EX Node User Text 1 [line 42].

net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
selectedNodes=0
selectedLinks=0
if roc.length==0
	puts "Select one or more manholes"
else
	roc.each do |ro_node|
	ro=ro_node
	if ro.node_id.include?("EX")
		ro.selected=true
		selectedNodes+=1
		unprocessedLinks=Array.new
		ro.us_links.each do |l|
			if !l._seen
				unprocessedLinks << l
			end
		end
		while unprocessedLinks.size>0
			working=unprocessedLinks.shift
			working.selected=true
			selectedLinks+=1
			workingUSNode=working.navigate1('us_node')
				if !workingUSNode.nil?
					if workingUSNode.node_id.include?("DO")
					#puts workingUSNode.node_id
					doid=workingUSNode.node_id
					end
					workingUSNode.selected=true
					selectedNodes+=1
					workingUSNode.us_links.each do |l|
						if !l._seen
							unprocessedLinks << l
							l._seen=true					
						end
				end
			end
		end
		net.transaction_begin
			ro.user_text_1=doid		# Write the 'DO' Node ID into User Text 1 of the starting Node
			ro.write
		net.transaction_commit
		puts "EX Outlet #{ro.node_id} has Updatream 'DO' #{doid}."
		else
			puts "Node #{ro.node_id} not an 'EX' node."
		end
	end
end