#
# This is an example script, it is your responsibility to ensure any
# script you run is suitable for the purpose you have in mind
#
net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
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
	unprocessedLinks=Array.new
	if upstream
		links=ro.us_links
	else
		links=ro.ds_links
	end
	links.each do |l|
		if !l._seen
			if l.us_invert>15
				unprocessedLinks << l
			end
			l._seen=true
		end
	end
	iterations=0
	while unprocessedLinks.size>0 
		working=unprocessedLinks.shift
		working.selected=true
		if upstream
			workingNode=working.us_node
		else
			workingNode=working.ds_node
		end
		if !workingNode.nil?
			workingNode.selected=true
			if upstream
				links=workingNode.us_links
			else
				links=workingNode.ds_links
			end
			links.each do |l|
				if !l._seen
					if l.us_invert>15
						unprocessedLinks << l
					end
					l._seen=true					
				end
			end
		end
	end
end