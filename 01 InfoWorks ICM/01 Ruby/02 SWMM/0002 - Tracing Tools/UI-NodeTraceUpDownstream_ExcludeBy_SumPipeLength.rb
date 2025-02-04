#
# This is an example script, it is your responsbility to ensure any
# script you run is suitable for the purpose you have in mind
#
net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
selectedNodes=0
selectedLinks=0
linksLength=0
if roc.length!=1
	puts 'Please select one manhole.'
else
	upstream=nil
	if WSApplication.message_box("Go upstream?\nYes = Upstream; No = Downstream","YesNo","?",true) == "Yes" then
		upstream=true
	else
		upstream=false
	end
	ro=roc[0]
	ro.selected=true
	selectedNodes+=1
	unprocessedLinks=Array.new
	if upstream
		links=ro.us_links
	else
		links=ro.ds_links
	end
	links.each do |l|
		if !l._seen
			unprocessedLinks << l
			l._seen=true
		end
	end
	iterations=0
	while unprocessedLinks.size>0 
		working=unprocessedLinks.shift
		working.selected=true
		selectedLinks+=1
		linksLength+=working.length
		if upstream
			workingNode=working.us_node
		else
			workingNode=working.ds_node
		end
		if !workingNode.nil?
			workingNode.selected=true
			selectedNodes+=1
			
		#	if workingNode.node_type!='F'		#Exclude Node_Type of 'F'
			
				if upstream
					links=workingNode.us_links
				else
					links=workingNode.ds_links
				end
				links.each do |l|
					if !l._seen
						unprocessedLinks << l
						l._seen=true					
					end
				end
			
		#	end									#End from NodeType exclusion
			
		end
	end
	puts 'Selected nodes '+selectedNodes.to_s
	puts 'Selected links '+selectedLinks.to_s
	linksLengthR=linksLength.round(3)
	puts 'Selected links Length '+linksLengthR.to_s+' (m)'
end