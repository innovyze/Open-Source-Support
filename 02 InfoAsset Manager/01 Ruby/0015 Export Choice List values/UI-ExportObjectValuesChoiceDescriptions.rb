# Outputs the values from the Pipe table fields the ID, system_type, pipe_type, user_text_29 converting the choice values to the descriptions

require 'csv'

CSV.open("C:\\TEMP\\export.csv", "wb") do |csv|

	nw = WSApplication.current_network
	nw.clear_selection
	
	ro=nw.row_objects('cams_pipe').each do |ro|
		if ro.user_text_9 == 'AA'
			ro.selected=true
		end
	end
	
	puts "oid,systemType,pipeType,userText29"
	csv << ["oid","systemType","pipeType","userText29"]
	
	ro=nw.row_objects_selection('cams_pipe').each do |ro|
		ac = nw.field_choices('cams_pipe','system_type')
		ad = nw.field_choice_descriptions('cams_pipe','system_type')
		systemType=Hash.new
		
		bc = nw.field_choices('cams_pipe','pipe_type')
		bd = nw.field_choice_descriptions('cams_pipe','pipe_type')
		pipeType=Hash.new
		
		cc = nw.field_choices('cams_pipe','user_text_29')
		cd = nw.field_choice_descriptions('cams_pipe','user_text_29')
		ut29=Hash.new
		
		
		if ac and ad then
		i=0
			ac.each do |a|
				systemType[a]=ad[i]
				i=i+1
			end
		end
		#puts systemType["F"]
		
		
		if bc and bd then
		i=0
			bc.each do |b|
				pipeType[b]=bd[i]
				i=i+1
			end
		end
		#puts pipeType["A"]
		
		
		if cc and cd then
		i=0
			cc.each do |c|
				ut29[c]=cd[i]
				i=i+1
			end
		end
		#puts ut29["A"]
		
		
		puts("#{ro.us_node_id}"+"."+"#{ro.ds_node_id}"+"."+"#{ro.link_suffix}"","+((ro.system_type.empty?) ? "" : systemType[ro.system_type])+","+((ro.pipe_type.empty?) ? "" : pipeType[ro.pipe_type])+","+((ro.user_text_29.empty?) ? "" : ut29[ro.user_text_29]))
		
		csv << ["#{ro.us_node_id}"+"."+"#{ro.ds_node_id}"+"."+"#{ro.link_suffix}" , ((ro.system_type.empty?) ? "" : systemType[ro.system_type]) , ((ro.pipe_type.empty?) ? "" : pipeType[ro.pipe_type]) , ((ro.user_text_29.empty?) ? "" : ut29[ro.user_text_29])]
		
	end
end