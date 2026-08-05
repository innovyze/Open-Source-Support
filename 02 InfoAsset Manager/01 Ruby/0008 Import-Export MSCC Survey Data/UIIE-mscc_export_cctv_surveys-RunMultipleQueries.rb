## Run multiple Stored SQL Queries and MSCC-export the CCTV surveys selected by each query.
##
## stored_query_ids - Comma-separated stored query database object IDs (UI prompt or EXCHANGE CONFIG).
## query_labels      - Optional comma-separated export labels, one per query in the same order.
## Export folder, file prefix, stored query IDs, query labels, individual files, and export images
## are chosen via a prompt when run in the UI.
## In Exchange, set the values in the EXCHANGE CONFIG section below.

## EXCHANGE CONFIG
export_folder = 'C:\\Temp\\export\\'
export_images = false
individual_files = false
stored_query_ids = '2602,2603'
query_labels = ''
file_prefix = 'MSCC_'

def safe_filename_part(value)
	value.to_s.gsub(/[^0-9A-Za-z_-]/, '')
end

def normalize_file_prefix(prefix)
	cleaned = safe_filename_part(prefix)
	cleaned.empty? ? 'MSCC_' : cleaned
end

def parse_stored_query_ids(input)
	input.to_s.split(',').map(&:strip).reject(&:empty?).map do |part|
		{ id: part.to_i }
	end
end

def apply_query_labels(queries, labels_input)
	labels = labels_input.to_s.split(',').map(&:strip)

	queries.each_with_index do |query, index|
		label = index < labels.length ? labels[index] : nil
		query[:label] = label.nil? || label.empty? ? query[:id].to_s : label
	end

	queries
end

def normalize_export_folder(path)
	folder = File.expand_path(path.to_s.strip)
	folder = folder.gsub('/', '\\')
	folder += '\\' unless folder.end_with?('\\')
	folder
end

def export_folder_exists?(path)
	folder = path.to_s.strip
	!folder.empty? && File.directory?(File.expand_path(folder))
end

def mscc_export_prompt_layout(export_folder, file_prefix, stored_query_ids, query_labels, individual_files, export_images)
	[
		['Export folder:', 'String', export_folder, nil, 'FOLDER', 'Select export folder'],
		['Export file prefix (optional):', 'String', file_prefix],
		['Leave blank to use MSCC_', 'Readonly', ''],
		['Stored query IDs (comma separated):', 'String', stored_query_ids],
		['Enter database object IDs, comma separated.', 'Readonly', ''],
		['Export labels (comma separated, optional):', 'String', query_labels],
		['One label per query, same order. Leave blank to use query ID.', 'Readonly', ''],
		['Individual XML files per survey', 'Boolean', individual_files],
		['False = one XML file per stored query.', 'Readonly', ''],
		['Export defect images', 'Boolean', export_images],
		['Images are saved alongside the XML files.', 'Readonly', ''],
	]
end

if WSApplication.ui?
	net = WSApplication.current_network
else
	db = WSApplication.open
	dbnet = db.model_object_from_type_and_id 'Collection Network', 2	## Collection Network #2 in Exchange
	net = dbnet.open
end

if WSApplication.ui?
	loop do
		val = WSApplication.prompt 'MSCC CCTV export - multiple stored queries',
			mscc_export_prompt_layout(export_folder, file_prefix, stored_query_ids, query_labels, individual_files, export_images),
			false

		if val.nil?
			abort 'Export cancelled - prompt closed.'
		end

		export_folder = val[0].to_s
		file_prefix = normalize_file_prefix(val[1])
		stored_query_ids = val[3].to_s
		query_labels = val[5].to_s
		individual_files = val[7]
		export_images = val[9]

		if export_folder.strip.empty?
			WSApplication.message_box(
				"Export folder is required.\n\nPlease select or enter a folder.",
				'OK', '!', false
			)
			next
		end

		unless export_folder_exists?(export_folder)
			WSApplication.message_box(
				"Export folder not found:\n#{File.expand_path(export_folder.strip)}\n\nPlease choose an existing folder.",
				'OK', '!', false
			)
			next
		end

		break
	end
end

file_prefix = normalize_file_prefix(file_prefix)

unless export_folder_exists?(export_folder)
	abort "Export folder not found: #{File.expand_path(export_folder.to_s.strip)}"
end

stored_queries = apply_query_labels(parse_stored_query_ids(stored_query_ids), query_labels)
if stored_queries.empty?
	abort 'No stored query IDs provided.'
end

export_folder = normalize_export_folder(export_folder)

log_file = "#{export_folder}#{file_prefix}Export_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log"
puts "Export folder: #{export_folder}"
puts "File prefix: #{file_prefix}"
puts "Stored queries: #{stored_queries.map { |q| "#{q[:id]} (#{safe_filename_part(q[:label])})" }.join(', ')}"
puts "Individual files: #{individual_files}"
puts "Export images: #{export_images}"
puts "Log file: #{log_file}"

stored_queries.each_with_index do |query, query_index|
	query_id = query[:id]
	query_label = safe_filename_part(query[:label] || query_id)

	net.clear_selection
	net.run_stored_query_object(query_id)

	surveys = net.row_objects_selection('cams_cctv_survey')
	survey_count = surveys.count

	puts "Query #{query_index + 1}/#{stored_queries.length} (ID #{query_id}, label #{query_label}): #{survey_count} survey(s) selected"

	next if survey_count == 0

	if individual_files
		surveys.each_with_index do |survey, survey_index|
			net.clear_selection
			net.row_object('cams_cctv_survey', survey.id).selected = true

			survey_id = safe_filename_part(survey.id)
			filename = "#{export_folder}#{file_prefix}#{query_label}_#{survey_index}_#{survey_id}.xml"

			puts "  Export #{survey_index + 1}/#{survey_count}: #{survey.id} -> #{filename}"
			net.mscc_export_cctv_surveys(filename, export_images, true, log_file)
		end
	else
		filename = "#{export_folder}#{file_prefix}#{query_label}.xml"
		puts "  Export combined file: #{filename}"
		net.mscc_export_cctv_surveys(filename, export_images, true, log_file)
	end
end

puts 'Export complete.'
