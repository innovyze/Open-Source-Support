require "csv"
now=DateTime.now.strftime("%Y%m%d%H%M")

nw=WSApplication.current_network 
exportloc ='C:\\Temp\\export\\'			## Export to folder
file=exportloc+'MSCC_'						## Filename prefix or leave as just "exportloc" to not include a prefix
log=exportloc+'MSCC_Export_'+now+'.csv'		## Log CSV filename

CSV.open(log, "wb") do |csv|

	list=Array.new
	list=nw.row_objects_selection('cams_cctv_survey')
	n=list.count
	puts "Surveys to export: #{n}\nLog: #{log}\n\nIndex	Survey ID	Filename"
	csv << ["Surveys to export: #{n}"]
	csv << ["Index", "Survey ID", "Filename"]
	
	c=0
	while c<n
		list.each do |o|
		nw.clear_selection
		ro=nw.row_object('cams_cctv_survey',o.id)
		ro.selected=true
		oid=o.id.gsub(/[^0-9A-Za-z_-]/, '')+'.xml'	## Remove any non-alphanumeric characters from the filename
		filename=file+c.to_s+'_'+oid				## The filename will be "prefix index Survey ID
		puts "#{c}	#{o.id}	#{filename}" 
		csv << ["#{c}", "#{o.id}", "#{filename}"]
		nw.mscc_export_cctv_surveys(filename,false,true,nil)
		c=c+1
		end
	end
end
