
## Available Reprots:
##[['cams_manhole',nil],['cams_manhole_survey',nil],['cams_cctv_survey','MSCC'],['cams_cctv_survey','PACP'],['cams_cctv_survey',nil],['cams_pipe_clean',nil],['cams_pipe_repair',nil],['cams_manhole_repair',nil],['cams_fog_inspection',nil]]

net=WSApplication.current_network
tables=[['cams_manhole_survey',nil]]

objs=Array.new
tables.each do |t|
	objs << net.row_objects_selection(t[0])
end
(0...tables.size).each do |i|	
	t=tables[i]
	o=objs[i]
	n=0
	o.each do |ro|
		net.clear_selection
		ro.selected=true
		suffix=''
		if !t[1].nil?
			suffix=t[1]+'_'
		end
		prefix="c:\\temp\\Report_#{t[0]}_#{suffix}_#{ro.id}"	## Export folder location and report name pre-fix
		net.generate_report(t[0],t[1],ro.id,prefix+'.doc')		## Generate a Word report
		net.generate_report(t[0],t[1],ro.id,prefix+'.html')		## Generate a HTML report
		n+=1
		if n==3
			break
		end
	end
end
WSApplication.message_box "Reports Exported","OK","Information", false
