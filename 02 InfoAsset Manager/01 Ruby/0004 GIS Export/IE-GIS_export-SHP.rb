begin
	WSApplication.use_arcgis_desktop_licence
	puts 'Start InfoAsset Manager Export to Shapefiles'
	db = WSApplication.open('//localhost:40000/IA_NEW', false)
	nw = db.model_object_from_type_and_id('Collection Network',20)
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
	options['ExportFlags'] = false					# Boolean – if true then the flags are exported along with the data values, if false they aren't. The default is true. 
	#options['Feature Dataset'] = ''				# String – for GeoDatabases, the name of the feature dataset. The default is an empty string. 
	#options['SkipEmptyTables'] = false				# Boolean – if true skips empty tables (even if they are listed in the value for the Tables key). The default is false. 
	#options['Tables'] = ''							# Array of strings – the default is to export results for all tables
	#options['UseArcGISCompatibility'] = false		# Boolean – this is the equivalent of selecting the check-box in the UI. The default is false

	puts 'Ready for export'

	nw.GIS_export(
		'SHP',  			# Format
		options,			# Params
        'C:\\temp\\'		# Location
		)               
	puts 'Done'
end
