## Create individual reports for the selected surveys, prompts for a save location folder, re-selects the surveys once processed, prompt to open the export location

## Available Reprots:
##[['cams_manhole',nil],['cams_manhole_survey',nil],['cams_cctv_survey','MSCC'],['cams_cctv_survey','PACP'],['cams_cctv_survey',nil],['cams_pipe_clean',nil],['cams_pipe_repair',nil],['cams_manhole_repair',nil],['cams_fog_inspection',nil]]

net=WSApplication.current_network
tables=[['cams_manhole_survey',nil]]

folder=WSApplication.folder_dialog('Select an Export Location',true)

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
		prefix="#{folder}\\#{ro.id.gsub(/[^0-9A-Za-z_-]/, '--')}"		## Non-"0-9A-Za-z_-" characters in the Survey ID will be changed to '--'
		net.generate_report(t[0],t[1],ro.id,prefix+'.doc')		## Generate a Word report
		n+=1			
	end
	o.each do |sel|			## Re-select the selected objects
		sel.selected=true
	end
end

if WSApplication.message_box("Reports exported to #{folder}\nOpen folder?","YesNo","Information", false) == "Yes" then
	system("explorer #{folder}")
end