require 'date'
begin
	db = WSApplication.open
	mo = db.model_object_from_type_and_id('Sim',614)				# The ID is hardcoded in this example. Use a sim ID matching your use case.
	sim = mo.open
	table = 'hw_river_reach'
	sim.current_timestep = 10										# The simulation timestep is hardcoded in this example. See script 0043 that gets results for all timesteps.
	sim.row_object_collection(table).each do |row_object|
		# Build an array of section IDs for each river reach
		river_reach_sections = Array.new
		row_object.sections.each do |section|
			river_reach_sections |= [section.key]
		end
		# Build an array of results for each section
		results_array = row_object.result('rr_flow')
		# Build a 2D arrray matching the two arrays above
		section_results = river_reach_sections.zip(results_array)
		# Print results
		puts row_object.id
		puts "#{section_results}"
	end
	sleep 100
rescue => e
	puts e
	sleep 10
end