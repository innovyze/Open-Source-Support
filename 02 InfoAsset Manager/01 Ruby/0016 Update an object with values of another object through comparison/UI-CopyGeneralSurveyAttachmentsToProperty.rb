startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network

val = WSApplication.prompt 'Run Options',
	[['Run on', 'String', 'Whole Network', nil, 'LIST', ['Whole Network', 'Selected Surveys']]],
	false

exit if val.nil?
use_selection = val[0] == 'Selected Surveys'

survey_attachments = Hash.new { |hash, key| hash[key] = [] }

surveys = use_selection ? net.row_objects_selection('cams_general_survey') : net.row_objects('cams_general_survey')
surveys.each do |survey|
	next if survey.asset_type != 'cams_property'

	asset_id = survey.asset_id
	next if asset_id.nil? || asset_id.strip.empty?

	survey.attachments.each do |a|
		next if a.db_ref.nil? || a.db_ref.strip.empty?
		survey_attachments[asset_id] << [a.purpose, a.filename, a.description, a.db_ref]
		puts "Survey #{survey.id}: found attachment '#{a.filename}' (db_ref=#{a.db_ref}) for property #{asset_id}"
	end
end

puts "\nSurvey attachments found for #{survey_attachments.size} unique property ID(s).\n\n"

net.transaction_begin
net.row_objects('cams_property').each do |prop|
	prop_id = prop.id
	next unless survey_attachments.has_key?(prop_id)

	existing_db_refs = []
	prop.attachments.each do |a|
		existing_db_refs << a.db_ref.downcase unless a.db_ref.nil? || a.db_ref.strip.empty?
	end

	added = 0
	survey_attachments[prop_id].each do |att|
		db_ref = att[3]
		if existing_db_refs.include?(db_ref.downcase)
			puts "Property #{prop_id}: attachment db_ref=#{db_ref} already present, skipping."
		else
			current_attachments = prop.attachments
			n = current_attachments.length
			current_attachments.length = n + 1
			postcode = (prop.property_postalcode.nil? || prop.property_postalcode.strip.empty?) ? '' : prop.property_postalcode.gsub(' ', '')
			prop_name = (prop.property_name.nil? || prop.property_name.strip.empty?) ? '' : prop.property_name
			survey_filename = (att[1].nil? || att[1].strip.empty?) ? '' : att[1]
			new_filename = "#{postcode}#{prop_name}_#{survey_filename}_Loc.View"
			current_attachments[n].purpose = 'Location view'
			current_attachments[n].filename = new_filename
			current_attachments[n].description = att[2]
			current_attachments[n].db_ref = db_ref
			current_attachments.write
			prop.write
			existing_db_refs << db_ref.downcase
			added += 1
			puts "Property #{prop_id}: added attachment '#{new_filename}' (db_ref=#{db_ref})"
		end
	end

	puts "Property #{prop_id}: #{added} attachment(s) added." if added > 0
end
net.transaction_commit

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

puts "\nDone. Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
