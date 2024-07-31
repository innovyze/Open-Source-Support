# Trace Upstream from selected Pipe(s) and create a Selection List of the selected Upstream Pipes


db=WSApplication.current_database 
net=WSApplication.current_network
roc_pipe=net.row_objects_selection('cams_pipe')

if roc_pipe.length==0
	puts 'Please select one or more Pipes'
else
	roc_pipe.each do |ro_pipe|
		net.row_objects('_links').each do |l|
			l._seen=false
		end
		net.clear_selection
		ro_node = ro_pipe.navigate1('us_node')
		puts ro_node.object_id
		selectedNodes=0
		selectedLinks=0
		ro=ro_node
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
		puts 'Selected nodes '+selectedNodes.to_s
		puts 'Selected links '+selectedLinks.to_s
		
		# Asset Group location to save a new Selection List to
		mo_assetgrp = db.model_object_from_type_and_id('Asset group',3)
		
		# Create a Selection List in the above Asset Group
		mo_sellist=mo_assetgrp.new_model_object('Selection list',ro_node.object_id.to_s)
		
		# Save the Selection to the above Selection List
		net.save_selection(mo_sellist)

	end
end