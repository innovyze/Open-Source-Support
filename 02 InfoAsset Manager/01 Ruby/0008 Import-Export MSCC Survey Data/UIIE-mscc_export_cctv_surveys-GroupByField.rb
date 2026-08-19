## Group selected CCTV surveys (or all surveys in the network) by a field value,
## and MSCC-export one or more XML files per group (for example one XML per PCL number).
##
## group_field - Field on cams_cctv_survey (e.g. user_text_5) or on the related pipe using
##               pipe.fieldname (e.g. pipe.user_text_29).
##
## Export settings are chosen via a prompt when run in the UI.
## In Exchange, set the values in the EXCHANGE CONFIG section below.

## EXCHANGE CONFIG
export_folder = 'C:\\Temp\\export\\'
export_images = false
individual_files = false
subfolder_per_group = false
skip_blank_groups = false
selection_only = true
group_field = 'user_text_5'
blank_group_label = 'Unknown'
file_prefix = 'MSCC_'

def export_timestamp_stamp
	t = Time.new
	format('%04d%02d%02d_%02d%02d%02d', t.year, t.month, t.day, t.hour, t.min, t.sec)
rescue StandardError
	require 'date'
	dt = DateTime.now
	format('%04d%02d%02d_%02d%02d%02d', dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec)
rescue StandardError
	puts 'Warning: could not build run timestamp; using placeholder in log/summary filenames.'
	'00000000_000000'
end

def safe_filename_part(value)
	cleaned = value.to_s.gsub(/[^0-9A-Za-z_-]/, '_')
	cleaned = cleaned.gsub(/_+/, '_')
	cleaned = cleaned.gsub(/^_+|_+$/, '')
	cleaned
end

def unique_export_label(group_key, used_labels)
	base = safe_filename_part(group_key)
	base = 'Unknown' if base.empty?
	label = base
	disambiguated = false

	if used_labels.key?(label)
		suffix = 2
		while used_labels.key?("#{base}_#{suffix}")
			suffix += 1
		end
		label = "#{base}_#{suffix}"
		disambiguated = true
	end

	used_labels[label] = group_key
	[label, disambiguated]
end

def normalize_file_prefix(prefix)
	cleaned = safe_filename_part(prefix)
	cleaned.empty? ? 'MSCC_' : cleaned
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

def ensure_directory(path)
	dir = normalize_export_folder(path).chomp('\\')
	Dir.mkdir(dir) unless File.directory?(dir)
end

def read_field_value(object, field_name)
	return nil if object.nil?

	name = field_name.to_s.strip
	return nil if name.empty?

	return object.send(name) if object.respond_to?(name)
	return object[name] if object.respond_to?(:[])
	return object.field(name) if object.respond_to?(:field)

	nil
rescue StandardError
	nil
end

def load_cctv_survey(net, survey)
	id = nil
	id = survey.id if survey.respond_to?(:id)
	id = survey['id'] if id.nil? && survey.respond_to?(:[])
	id = id.to_s.strip
	return survey if id.empty?

	begin
		full = net.row_object('cams_cctv_survey', id)
		return full if full
	rescue StandardError
	end

	survey
end

def find_pipe_by_id(net, pipe_id)
	id = pipe_id.to_s.strip
	return nil if id.empty?

	begin
		pipe = net.row_object('cams_pipe', id)
		return pipe unless pipe.nil?
	rescue StandardError
	end

	begin
		matches = net.row_objects_from_asset_id('cams_pipe', id)
		return matches.first if matches && !matches.empty?
	rescue StandardError
	end

	nil
end

def pipe_from_survey_link_fields(net, survey)
	us = read_field_value(survey, 'us_node_id').to_s.strip
	ds = read_field_value(survey, 'ds_node_id').to_s.strip
	return nil if us.empty? || ds.empty?

	suffix = read_field_value(survey, 'link_suffix').to_s.strip
	find_pipe_by_id(net, "#{us}.#{ds}.#{suffix}")
end

def related_pipe(net, survey)
	survey = load_cctv_survey(net, survey)

	%w[pipe joined].each do |nav_type|
		begin
			next unless survey.respond_to?(:navigate1)

			pipe = survey.navigate1(nav_type)
			return pipe if pipe
		rescue StandardError
		end
	end

	pipe = pipe_from_survey_link_fields(net, survey)
	return pipe if pipe

	asset_id = read_field_value(survey, 'asset_id').to_s.strip
	unless asset_id.empty?
		pipe = find_pipe_by_id(net, asset_id)
		return pipe if pipe
	end

	plr = read_field_value(survey, 'plr').to_s.strip
	unless plr.empty?
		pipe = find_pipe_by_id(net, plr)
		return pipe if pipe
	end

	nil
end

def group_surveys(net, surveys, group_field, blank_group_label, skip_blank_groups)
	groups = {}
	skipped_blank = 0
	surveys_without_pipe = 0
	grouping_by_pipe = group_field.to_s.strip.downcase.start_with?('pipe.')

	surveys.each do |survey|
		full_survey = load_cctv_survey(net, survey)
		pipe = nil

		if grouping_by_pipe
			pipe = related_pipe(net, full_survey)
			surveys_without_pipe += 1 if pipe.nil?
			pipe_field = group_field.to_s.strip
			pipe_field = pipe_field[5..-1].strip if pipe_field.downcase.start_with?('pipe.')
			pipe_field = pipe_field[1..-1].strip if pipe_field.start_with?('.')
			raw = read_field_value(pipe, pipe_field)
		else
			raw = read_field_value(full_survey, group_field)
		end
		key = raw.to_s.strip

		if key.empty?
			if skip_blank_groups
				skipped_blank += 1
				next
			end
			key = blank_group_label.to_s.strip
			key = 'Unknown' if key.empty?
		end

		groups[key] = [] if groups[key].nil?
		groups[key] << full_survey.id
	end

	[groups, skipped_blank, surveys_without_pipe]
end

def prompt_bool(value)
	value == true || value.to_s.strip.downcase == 'true'
end

def mscc_export_status(result, filename)
	return 'OK' if result == true || result.to_s.strip.downcase == 'true'
	return 'Failed' if result == false || result.to_s.strip.downcase == 'false'

	# InfoAsset Manager often returns nil on a successful export.
	export_path = File.expand_path(filename.to_s.strip)
	File.file?(export_path) ? 'OK' : 'Failed'
rescue StandardError
	'Failed'
end

def prompt_val(prompt_result, index, default = nil)
	return default if prompt_result.nil?
	return prompt_result[index] if prompt_result.is_a?(Array)
	default
end

def cctv_surveys_for_export(net, selection_only)
	if selection_only
		net.row_objects_selection('cams_cctv_survey')
	else
		net.row_objects('cams_cctv_survey')
	end
end

def append_export_log(log_file, message)
	puts message
	File.open(log_file, 'a') { |f| f.puts message }
end

def write_export_log_header(log_file, lines)
	File.open(log_file, 'w') do |f|
		lines.each { |line| f.puts line }
	end
end

def format_survey_id_list(survey_ids)
	survey_ids.map { |id| id.to_s.strip }.reject(&:empty?).join(', ')
end

def csv_field(value)
	text = value.to_s
	if text.include?(',') || text.include?('"') || text.include?("\n") || text.include?("\r")
		'"' + text.gsub('"', '""') + '"'
	else
		text
	end
end

def summary_csv_row(group_key, survey_count, filename, status, survey_ids)
	[
		group_key,
		survey_count,
		filename,
		status,
		format_survey_id_list(survey_ids)
	].map { |value| csv_field(value) }.join(',')
end

if WSApplication.ui?
	net = WSApplication.current_network
else
	db = WSApplication.open
	dbnet = db.model_object_from_type_and_id 'Collection Network', 2	## Collection Network #2 in Exchange
	net = dbnet.open
end

if WSApplication.ui?
	while true
		val = WSApplication.prompt 'MSCC CCTV export - group by field',
		[
			['Export folder:', 'String', export_folder, nil, 'FOLDER', 'Select export folder'],
			['Export file prefix (optional):', 'String', file_prefix],
			['Leave blank to use MSCC_', 'Readonly', ''],
			['Process selection only?', 'Boolean', selection_only],
			['Unchecked = all CCTV surveys in the network.', 'Readonly', ''],
			['Group field:', 'String', group_field],
			['Survey field, or pipe.fieldname (e.g. pipe.user_text_29).', 'Readonly', ''],
			['Label for blank group values (optional):', 'String', blank_group_label],
			['Skip surveys with blank group values', 'Boolean', skip_blank_groups],
			['Individual XML files per survey', 'Boolean', individual_files],
			['False = one XML file per group.', 'Readonly', ''],
			['Export defect images', 'Boolean', export_images],
			['Images are saved alongside the XML files.', 'Readonly', ''],
			['Create subfolder per group', 'Boolean', subfolder_per_group],
			['Each group exports into its own subfolder.', 'Readonly', ''],
		],
		false

		if val.nil?
			abort 'Export cancelled - prompt closed.'
		end

		export_folder = prompt_val(val, 0, export_folder).to_s
		file_prefix = normalize_file_prefix(prompt_val(val, 1, file_prefix))
		selection_only = prompt_bool(prompt_val(val, 3, selection_only))
		group_field = prompt_val(val, 5, group_field).to_s.strip
		blank_group_label = prompt_val(val, 7, blank_group_label).to_s
		skip_blank_groups = prompt_bool(prompt_val(val, 8, skip_blank_groups))
		individual_files = prompt_bool(prompt_val(val, 9, individual_files))
		export_images = prompt_bool(prompt_val(val, 11, export_images))
		subfolder_per_group = prompt_bool(prompt_val(val, 13, subfolder_per_group))

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

		if group_field.empty?
			WSApplication.message_box(
				"Group field is required.\n\nEnter a survey field name or pipe.fieldname.",
				'OK', '!', false
			)
			next
		end

		break
	end
end

file_prefix = normalize_file_prefix(file_prefix)
blank_group_label = blank_group_label.to_s.strip
blank_group_label = 'Unknown' if blank_group_label.empty?

unless export_folder_exists?(export_folder)
	abort "Export folder not found: #{File.expand_path(export_folder.to_s.strip)}"
end

if group_field.to_s.strip.empty?
	abort 'Group field is required.'
end

export_folder = normalize_export_folder(export_folder)
run_stamp = export_timestamp_stamp
log_file = "#{export_folder}#{file_prefix}Export_#{run_stamp}.log"
summary_csv = "#{export_folder}#{file_prefix}ExportSummary_#{run_stamp}.csv"

surveys = cctv_surveys_for_export(net, selection_only)

if surveys.count == 0
	if selection_only
		abort 'No CCTV surveys found in the current selection.'
	end
	abort 'No CCTV surveys found in the network.'
end

groups, skipped_blank, surveys_without_pipe = group_surveys(
	net, surveys, group_field, blank_group_label, skip_blank_groups
)

if groups.empty?
	abort 'No survey groups to export after grouping.'
end

puts "Export folder: #{export_folder}"
puts "File prefix: #{file_prefix}"
puts "Group field: #{group_field}"
puts "Scope: #{selection_only ? 'Selection only' : 'Whole network'}"
puts "Surveys to process: #{surveys.count}"
puts "Groups to export: #{groups.length}"
puts "Surveys without related pipe: #{surveys_without_pipe}" if group_field.to_s.strip.downcase.start_with?('pipe.')
puts "Skipped blank groups: #{skipped_blank}" if skipped_blank > 0
puts "Individual files: #{individual_files}"
puts "Export images: #{export_images}"
puts "Subfolder per group: #{subfolder_per_group}"
puts "Log file: #{log_file}"
puts "Summary CSV: #{summary_csv}"

if WSApplication.ui?
	summary_message = "Found #{surveys.count} survey(s) in #{groups.length} group(s)."
	summary_message += "\n#{surveys_without_pipe} survey(s) have no related pipe (grouped as #{blank_group_label})." if group_field.to_s.strip.downcase.start_with?('pipe.') && surveys_without_pipe > 0
	summary_message += "\n#{skipped_blank} survey(s) skipped (blank group value)." if skipped_blank > 0
	summary_message += "\n\nContinue with export?"

	if WSApplication.message_box(summary_message, 'YesNo', 'Information', false).to_s.downcase != 'yes'
		abort 'Export cancelled by user.'
	end
end

export_log_header = [
	"MSCC CCTV export - group by field (#{run_stamp})",
	"Export folder: #{export_folder}",
	"File prefix: #{file_prefix}",
	"Group field: #{group_field}",
	"Scope: #{selection_only ? 'Selection only' : 'Whole network'}",
	"Surveys to process: #{surveys.count}",
	"Groups to export: #{groups.length}",
	"Individual files: #{individual_files}",
	"Export images: #{export_images}",
	"Subfolder per group: #{subfolder_per_group}"
]
export_log_header << "Surveys without related pipe: #{surveys_without_pipe}" if group_field.to_s.strip.downcase.start_with?('pipe.')
export_log_header << "Skipped blank groups: #{skipped_blank}" if skipped_blank > 0
export_log_header << ''
write_export_log_header(log_file, export_log_header)

summary_log = File.open(summary_csv, 'w')
summary_log.puts 'Group,SurveyCount,Filename,Status,SurveyIDs'

used_export_labels = {}
groups.sort.each do |group_key, survey_ids|
	export_label, disambiguated = unique_export_label(group_key, used_export_labels)

	group_folder = export_folder
	if subfolder_per_group
		group_folder = "#{export_folder}#{export_label}\\"
		ensure_directory(group_folder)
	end

	net.clear_selection
	survey_ids.each do |survey_id|
		net.row_object('cams_cctv_survey', survey_id).selected = true
	end

	append_export_log(log_file, "Group #{group_key}: #{survey_ids.length} survey(s)")
	append_export_log(log_file, "  Export label: #{export_label}") if disambiguated
	append_export_log(log_file, "  Survey IDs: #{format_survey_id_list(survey_ids)}")

	if individual_files
		survey_ids.each_with_index do |survey_id, survey_index|
			net.clear_selection
			net.row_object('cams_cctv_survey', survey_id).selected = true

			survey_part = safe_filename_part(survey_id)
			filename = "#{group_folder}#{file_prefix}#{export_label}_#{survey_index}_#{survey_part}.xml"

			append_export_log(log_file, "  Export #{survey_index + 1}/#{survey_ids.length}: #{survey_id} -> #{filename}")
			result = net.mscc_export_cctv_surveys(filename, export_images, true, nil)
			status = mscc_export_status(result, filename)
			append_export_log(log_file, "  Status: #{status}") if status != 'OK'
			summary_log.puts summary_csv_row(group_key, 1, filename, status, [survey_id])
		end
	else
		filename = "#{group_folder}#{file_prefix}#{export_label}.xml"
		append_export_log(log_file, "  Export combined file: #{filename}")
		result = net.mscc_export_cctv_surveys(filename, export_images, true, nil)
		status = mscc_export_status(result, filename)
		append_export_log(log_file, "  Status: #{status}") if status != 'OK'
		summary_log.puts summary_csv_row(group_key, survey_ids.length, filename, status, survey_ids)
	end
end

summary_log.close
append_export_log(log_file, 'Export complete.')
