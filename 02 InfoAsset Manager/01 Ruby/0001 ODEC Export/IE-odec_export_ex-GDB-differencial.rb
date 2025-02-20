## File containing last exported commit version number
exportedversion = 'C:\Temp\ExportedVersion.txt'
## Export error file location
errorfile = 'C:\Temp\ErrorFile.txt'


begin

require 'date'

class DateTime
	def to_s
	return strftime('%Y-%m-%d %H:%M:%S')
	end
end

puts DateTime.now.to_s + ' - Start InfoAsset Export'


## Override the default Working Directory
#WSApplication.override_working_folder('C:\Temp\IAMWorking')

##Use local ArcGIS Desktop License not ESRI server license
WSApplication.use_arcgis_desktop_licence()


## Open an InfoAsset database
db = WSApplication.open('localhost:40000/IA_NEW',false)

## Get the network from the object type and id
nw = db.model_object_from_type_and_id('Collection Network',4) 

## Reserve the network to prevent other users from commiting changes during export
nw.reserve

## Open the network
net = nw.open


## Read the file containing the previous exported version number
	if ( File.exist?(exportedversion)) then
		f = File.new(exportedversion,"r")         
		last_commit_id_table = f.gets.to_i
		puts 'Last version exported to GDB - ' + last_commit_id_table.to_s
		f.close()
	end



## Check for changes and update local Working Directory
current_commit_id = nw.current_commit_id
latest_commit_id = nw.latest_commit_id

	if (latest_commit_id = current_commit_id) then
		puts "InfoAsset Network version is up to date - Last update: #{latest_commit_id}"
	else
		puts "Updating InfoAsset version from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
		## Update local Working Directory for the Network
		nw.update
	end



if ( latest_commit_id > last_commit_id_table ) then


## Set export paramaters
options=Hash.new
#options['Callback Class'] = nil					# Default = nil
options['Error File'] = errorfile					# Default = nil
#options['Image Folder'] = nil						# Default = nil
#options['Units Behaviour'] = 'Native'				# Native or User | Default = Native
#options['Report Mode'] = false						# Boolean, True to export in 'report mode' | Default = FALSE
#options['Append'] = false							# Boolean, True to enable 'Append to existing data' | Default = FALSE
#options['Export Selection'] = false				# Boolean, True to export the selected objects only | Default = FALSE
options['Previous Version'] = last_commit_id_table	# Integer, Previous version, if not zero differences are exported | Default = 0
#options['Don't Update Geometry'] = false			# Boolean | Default = FALSE


## Export Network data
puts DateTime.now.to_s + ' - Start InfoAsset Pipe Export to GDB'

nw.odec_export_ex(
	'GDB',											# export data format 
	'C:\Temp\odec_export_ex-GDB-differencial.cfg',	# field mapping config file
	options,										# specified options override the default options
		## table group
	'pipe',											# InfoAsset Table to export
	'Pipe',											# Export to Feature class - unqualified name
	'Pipes',										# Export to Feature Dataset - fully qualified name
	true,											# true to update, false otherwise. If true the feature class must exist
	nil,											# ArcSDE configuration keyword – nil for Personal / File GeoDatabases, and ignored for updates
	'C:\Temp\Test.gdb'								# Filename (for personal and file GeoDatabases, connection name for SDE)
)

puts DateTime.now.to_s + ' - Start InfoAsset Node Export to GDB'

nw.odec_export_ex(
	'GDB',
	'C:\Temp\odec_export_ex-GDB-differencial.cfg',
	options,
	'node',
	'Node',
	'Nodes',
	true,
	nil,
	'C:\Temp\Test.gdb'
)


puts DateTime.now.to_s + ' - Export to GDB complete'

## Unreserve network
nw.unreserve


# Update the file containing the previous exported version number
File.write(exportedversion, "#{latest_commit_id}")


## Else to the comparison of last exported version and current network version
else
	puts DateTime.now.to_s + ' - No changes since last export'
	## Unreserve network
	nw.unreserve
end

puts DateTime.now.to_s + ' - Script complete'




## handle exceptions

rescue Exception => exception

nw.unreserve if nw

puts "#{DateTime.now.to_s} [#{exception.backtrace}] #{exception.to_s}"

f = File.open(File.dirname(WSApplication.script_file)+'\ScriptErrorLog.txt', "a")
f.puts "Script Failed - #{DateTime.now.to_s} [#{exception.backtrace}] #{exception.to_s}"
f.puts '========================================================================================='
f.close()

exit!()

end


