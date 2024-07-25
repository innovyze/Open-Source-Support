net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
selectedNodes=0
selectedLinks=0
if roc.length!=1
	puts 'Please select one manhole'
else
	ro=roc[0]
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
end