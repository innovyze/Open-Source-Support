begin

net = WSApplication.current_network

#Option to export entire network or selection. Option to cancel and exit.
#

msbx = WSApplication.message_box(

	'Export Selection?', 'YesNoCancel', '?', false
)

puts 'Export Selection Y/N? - ' + msbx

ExportFolder = WSApplication.folder_dialog('title', true)

# set bool options
#

options = Hash.new

options['Use Display Precision'] = true     								# default=true
options['Field Descriptions'] = false										# default=false
options['Field Names'] = true												# default=true
options['Flag Fields'] = true												# default=true
options['Multiple Files'] = true											# default=false
options['User Units'] = false												# default=false
options['Object Types'] = false												# default=false
options['Units Text'] = false												# default=false
options['Error File'] = ExportFolder + '\ICMExport_Error.txt'				# error file		*****************************************

# set string options
#

options['Coordinate Arrays Format'] = 'Unpacked'  							# values='Packed'(default), 'None', 'Unpacked'
options['Other Arrays Format']      = 'Separate'  							# values='Packed'(default), 'None', 'Separate'

# export selected objects only?
#

if msbx == 'Yes'

	# export network data to csv format
	#
	options['Selection Only'] = true
	
	# Select Export Folder
	#

	
	puts 'Files exported to ' + ExportFolder
	
	net.csv_export(

		ExportFolder + '\model', 			# export to file name
		options								# export options
	)	
	
	puts 'Only selected objects exported'
	
elsif msbx == 'No'

	options['Selection Only'] = false
	
	# Select Export Folder
	#

		puts 'Files exported to ' + ExportFolder
		
	net.csv_export(

		ExportFolder + '\model', 			# export to file name
		options								# export options
	)	
		
	puts 'Entire network exported'		
elsif msbx == 'Cancel'
	
	puts 'Export action aborted'
end

puts 'Done'

#handle exceptions
#

rescue Exception => exception

puts "[#{exception.backtrace}] #{exception.to_s}"

end