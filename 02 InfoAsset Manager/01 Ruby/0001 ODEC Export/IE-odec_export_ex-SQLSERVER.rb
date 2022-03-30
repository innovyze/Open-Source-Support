begin
	#WSApplication.use_arcgis_desktop_licence
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
options['Use Display Precision'] = true		# default=true
options['Field Descriptions']    = false	# default=false
options['Field Names']           = true		# default=true    
options['Flag Fields']           = false	# default=true
options['Multiple Files']        = false    	# default=false
options['User Units']            = false    	# default=false
options['Units Behaviour']       = 'Native' 	# use native units
options['Object Types']          = false    	# default=false
options['Units Text']            = false    	# default=false
options['Selection Only']        = false    	# export selected objects only?
options['Create Primary Key']	 = false     	# create a primary key
options['Error File'] 		 = 'C:\Temp\SQLErrorLog.txt' #logs export errors

options['Coordinate Arrays Format'] = 'Unpacked'  # values='Packed'(default), 'None', 'Unpacked'
options['Other Arrays Format']      = 'Separate'  # values='Packed'(default), 'None', 'Separate'

	puts 'Ready for export'

nw.odec_export_ex(
'SQLSERVER', 			#sql server backup
'C:\Temp\SQL_export.cfg',     # field mapping config file
options,                	# export options


# table group
'node',  		# InfoAsset Manager table to export
'Node', 		# export to SQL server table name
'localhost',		# export to server
'SQLEXPRESS',		# export to SQL server instance
'IAMExport',		# export to SQL server database
true,			# export update? if true, then the export target must exist
false,			# integrated security?
'USERNAME',		# SQL username (or ARGV[1] to take user name from input parameter)
'PASSWORD',		# SQL password (or ARGV[2] to take password from input parameter)

)

puts 'Export Complete'


# handle exceptions

rescue Exception => exception

puts "[#{exception.backtrace}] #{exception.to_s}"

end





