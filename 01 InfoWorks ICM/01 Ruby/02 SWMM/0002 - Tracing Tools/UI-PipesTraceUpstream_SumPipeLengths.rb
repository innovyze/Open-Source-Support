# Trace Upstream from selected Pipe(s) and sum the Length of the selected Upstream Pipes


db=WSApplication.current_database 
net=WSApplication.current_network
roc_pipe=net.row_objects_selection('cams_pipe')



if roc_pipe.length==0
	WSApplication.message_box "Please select one or more Pipes\nThen re-run the trace script","OK","Information", false
else
	roc_pipe.each do |ro_pipe|
	linksLength=0
	puts "\n#{ro_pipe.us_node_id}.#{ro_pipe.ds_node_id}.#{ro_pipe.link_suffix}"
		net.row_objects('_links').each do |l|
			l._seen=false
		end
		linksLength+=ro_pipe.length
		#net.clear_selection
		ro_node = ro_pipe.navigate1('us_node')
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
			linksLength+=working.length
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
		linksLengthR=linksLength.round(3).to_s
		puts "Selected links Length #{linksLengthR} (m)"
		


	end
end