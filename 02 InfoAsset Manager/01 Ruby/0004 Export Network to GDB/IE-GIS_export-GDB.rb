begin
	WSApplication.use_arcgis_desktop_licence
	puts 'Start InfoAsset Manager Export to Geodatabase File'
	db = WSApplication.open('//localhost:40000/IA_NEW', false)
	nw = db.model_object_from_type_and_id('Collection Network',4)
	puts 'Network open'
	current_commit_id = nw.current_commit_id
	latest_commit_id = nw.latest_commit_id
	if(latest_commit_id > current_commit_id) then
		puts "Updating from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
		nw.update
	else
		puts 'Network is up to date'
	end

options=Hash.new
options['ExportFlags'] = false

	puts 'Ready for export'

	nw.GIS_export(
		'GDB',  options,                 
         'C:\temp\test.gdb')               
	puts 'Done'
end

