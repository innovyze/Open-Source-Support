# IExchange Configuration (ignore if using UI)
database = '//localhost:40000/IA_NEW'
logFilename = 'Output.txt'

# General Configuration
object_types = ['Collection Network', 'Distribution Network', 'Asset Network', 'Theme', 'Stored Query', 'Selection List', 'Web workspace']

# End of Configuration

if WSApplication.ui?
	db = WSApplication.current_database

	def log(str = '')
		puts str
	end
else
	db = WSApplication.open(database)

	$logFile = File.open(logFilename, 'w')
	def log(str = '')
		puts str
		$logFile.puts str
	end
end

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

log "Database Guid: #{db.guid}"
log

object_types.each { |network_type|
	networks = db.model_object_collection(network_type)
	network_ids = Array.new

	networks.each { |network|
		network_ids.push network.id
	}

	log "#{network_ids.size}	#{network_type}"

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