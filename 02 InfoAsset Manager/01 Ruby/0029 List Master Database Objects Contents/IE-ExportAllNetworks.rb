# Database Configuration
database = '//localhost:40000/IA_NEW'
logFilename = 'Output.txt'

# Choose the object types for export
object_types = ['Collection Network']

# End of Configuration


db = WSApplication.open(database)

$logFile = File.open(logFilename, 'w')
def log(str = '')
	puts str
	$logFile.puts str
end

log object_types
log

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

log "Database Guid: #{db.guid}"
log

object_types.each { |network_type|
	networks = db.model_object_collection(network_type)
	network_ids = Array.new
	
	log "#{network_type}(s)"
	
	networks.each { |network|
		log "#{network.id}	#{network.name}"
		#log "#{network.id}	#{network.name}		#{network.path}"
		
		
		### Insert your chosen export method here
		
			nw = db.model_object_from_type_and_id('Collection Network', network.id)		## Network to export
			nw.update																	## Update local copy of network to latest
			on = nw.open																## Open network for export

			options=Hash.new
			#options['SelectedOnly'] = false									## Boolean | Default = FALSE
			#options['IncludeImageFiles'] = false								## Boolean | Default = FALSE
			#options['IncludeGeoPlanPropertiesAndThemes'] = false				## Boolean | Default = FALSE
			#options['ChangesFromVersion'] = 0									## Integer | Default = 0
			#options['Tables'] = ["cams_cctv_survey","cams_manhole_survey"]		## Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.

			file="C:\\TEMP\\export_"+network.id.to_s+".isfc"					## Set an export location & filename
			on.snapshot_export_ex(file,options)									## Export network
			
			on.close															## Close network after export has finished
		
		###
		
		
		network_ids.push network.id
	}

	log "Identified #{network_ids.size} #{network_type}"
	log
}

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

log
log "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
log

puts log

if !WSApplication.ui?
	$logFile.close()
end