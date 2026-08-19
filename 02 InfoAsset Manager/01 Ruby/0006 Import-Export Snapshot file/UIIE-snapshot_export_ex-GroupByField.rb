## Group objects from one or more network tables by a shared field value,
## and export one snapshot file per group.
##
## Snapshot file extension depends on network type:
##   Collection (CAMS)     -> .isfc
##   Distribution (WAMS)   -> .isfd
##   Asset (AMS)           -> .isfa
##
## group_field - Field on the object (e.g. user_text_5) or on a related pipe using
##               pipe.fieldname (e.g. pipe.user_text_29).
##
## Export settings are chosen via prompts when run in the UI.
## In Exchange, set the values in the EXCHANGE CONFIG section below.

## EXCHANGE CONFIG
export_folder = 'C:\\Temp\\export\\'
include_image_files = false
include_geoplan_properties = false
subfolder_per_group = false
skip_blank_groups = false
selection_only = true
source_tables = 'cams_cctv_survey'
group_field = 'user_text_5'
blank_group_label = 'Unknown'
file_prefix = 'Snapshot_'

def table_profile(table_name)
	return :cams if table_name.start_with?('cams__') || table_name.start_with?('cams_')
	return :wams if table_name.start_with?('wams__') || table_name.start_with?('wams_')
	return :ams if table_name.start_with?('ams__') || table_name.start_with?('ams_')

	nil
end

def detect_network_profile(table_names)
	counts = { cams: 0, wams: 0, ams: 0 }

	table_names.each do |name|
		profile = table_profile(name)
		counts[profile] += 1 if profile
	end

	best = counts.max_by { |_profile, count| count }
	return best[0] if best[1] > 0

	:cams
end

def network_profile_label(profile)
	case profile
	when :wams then 'Distribution (WAMS)'
	when :ams then 'Asset (AMS)'
	else 'Collection (CAMS)'
	end
end

def snapshot_extension_for_profile(profile)
	case profile
	when :wams then 'isfd'
	when :ams then 'isfa'
	else 'isfc'
	end
end

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
	cleaned.empty? ? 'Snapshot_' : cleaned
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

def prompt_bool(value)
	value == true || value.to_s.strip.downcase == 'true'
end

def prompt_val(prompt_result, index, default = nil)
	return default if prompt_result.nil?
	return prompt_result[index] if prompt_result.is_a?(Array)
	default
end

def table_display_name(table)
	table.description.to_s.strip
end

def table_prompt_label(table)
	description = table_display_name(table)
	description.empty? ? table.name : "#{description} (#{table.name})"
end

def table_sort_key(table)
	description = table_display_name(table)
	(description.empty? ? table.name : description).downcase
end

def prompt_table_selection(present_tables)
	table_prompt = [['Select / deselect all object tables', 'Boolean', false]]
	present_tables.each { |table| table_prompt << [table_prompt_label(table), 'Boolean', false] }

	table_val = WSApplication.prompt 'Snapshot export - select object tables', table_prompt, false
	return nil if table_val.nil?

	select_all = table_val[0]
	selected_tables = []
	present_tables.each_with_index do |table, idx|
		selected_tables << table.name if prompt_bool(select_all) || prompt_bool(table_val[idx + 1])
	end
	selected_tables
end

def parse_source_tables(input, present_table_names)
	names = input.to_s.split(',').map(&:strip).reject(&:empty?)
	return present_table_names.dup if names.empty?

	unknown = names.reject { |name| present_table_names.include?(name) }
	unless unknown.empty?
		abort "Unknown source table(s): #{unknown.join(', ')}"
	end
	names
end

def row_id(row)
	id = row.id if row.respond_to?(:id)
	id = row['id'] if id.nil? && row.respond_to?(:[])
	id.to_s.strip
rescue StandardError
	''
end

def network_rows(net, table_name, selection_only)
	if selection_only
		if net.respond_to?(:row_object_collection_selection)
			rows = net.row_object_collection_selection(table_name)
			return rows unless rows.nil?
		elsif net.respond_to?(:row_objects_selection)
			rows = net.row_objects_selection(table_name)
			return rows unless rows.nil?
		end
		return []
	end

	if net.respond_to?(:row_object_collection)
		return net.row_object_collection(table_name)
	end
	if net.respond_to?(:row_objects)
		return net.row_objects(table_name)
	end

	[]
rescue StandardError
	[]
end

def collect_object_refs(net, table_names, selection_only)
	object_refs = []

	table_names.each do |table_name|
		network_rows(net, table_name, selection_only).each do |row|
			id = row_id(row)
			object_refs << [table_name, id] unless id.empty?
		end
	end

	object_refs
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

def load_row_object(net, table_name, object_id)
	id = object_id.to_s.strip
	return nil if id.empty?

	begin
		row = net.row_object(table_name, id)
		return row if row
	rescue StandardError
	end

	nil
end

def pipe_table_for(table_name)
	return 'cams_pipe' if table_name.start_with?('cams_')
	return 'wams_pipe' if table_name.start_with?('wams_')

	nil
end

def find_pipe_by_id(net, pipe_id, pipe_table)
	id = pipe_id.to_s.strip
	return nil if id.empty? || pipe_table.nil?

	begin
		pipe = net.row_object(pipe_table, id)
		return pipe unless pipe.nil?
	rescue StandardError
	end

	begin
		matches = net.row_objects_from_asset_id(pipe_table, id)
		return matches.first if matches && !matches.empty?
	rescue StandardError
	end

	nil
end

def pipe_from_survey_link_fields(net, row, pipe_table)
	us = read_field_value(row, 'us_node_id').to_s.strip
	ds = read_field_value(row, 'ds_node_id').to_s.strip
	return nil if us.empty? || ds.empty? || pipe_table.nil?

	suffix = read_field_value(row, 'link_suffix').to_s.strip
	find_pipe_by_id(net, "#{us}.#{ds}.#{suffix}", pipe_table)
end

def related_pipe(net, table_name, row)
	row = load_row_object(net, table_name, row_id(row))
	return nil if row.nil?

	pipe_table = pipe_table_for(table_name)

	if pipe_table && table_name == pipe_table
		return row
	end

	%w[pipe joined].each do |nav_type|
		begin
			next unless row.respond_to?(:navigate1)

			pipe = row.navigate1(nav_type)
			return pipe if pipe
		rescue StandardError
		end
	end

	pipe = pipe_from_survey_link_fields(net, row, pipe_table)
	return pipe if pipe

	asset_id = read_field_value(row, 'asset_id').to_s.strip
	unless asset_id.empty?
		pipe = find_pipe_by_id(net, asset_id, pipe_table)
		return pipe if pipe
	end

	plr = read_field_value(row, 'plr').to_s.strip
	unless plr.empty?
		pipe = find_pipe_by_id(net, plr, pipe_table)
		return pipe if pipe
	end

	nil
end

def group_objects(net, object_refs, group_field, blank_group_label, skip_blank_groups)
	groups = {}
	skipped_blank = 0
	objects_without_pipe = 0
	grouping_by_pipe = group_field.to_s.strip.downcase.start_with?('pipe.')

	object_refs.each do |table_name, object_id|
		row = load_row_object(net, table_name, object_id)
		pipe = nil

		if grouping_by_pipe
			pipe = related_pipe(net, table_name, row)
			objects_without_pipe += 1 if pipe.nil?
			pipe_field = group_field.to_s.strip
			pipe_field = pipe_field[5..-1].strip if pipe_field.downcase.start_with?('pipe.')
			pipe_field = pipe_field[1..-1].strip if pipe_field.start_with?('.')
			raw = read_field_value(pipe, pipe_field)
		else
			raw = read_field_value(row, group_field)
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
		groups[key] << [table_name, object_id]
	end

	[groups, skipped_blank, objects_without_pipe]
end

def snapshot_export_options(include_image_files, include_geoplan_properties)
	options = {}
	options['SelectedOnly'] = true
	options['IncludeImageFiles'] = include_image_files
	options['IncludeGeoPlanPropertiesAndThemes'] = include_geoplan_properties
	options
end

def snapshot_export_status(result, filename)
	return 'OK' if result == true || result.to_s.strip.downcase == 'true'
	return 'Failed' if result == false || result.to_s.strip.downcase == 'false'

	export_path = File.expand_path(filename.to_s.strip)
	File.file?(export_path) ? 'OK' : 'Failed'
rescue StandardError
	'Failed'
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

def format_object_ref(object_ref)
	table_name, object_id = object_ref
	"#{table_name}:#{object_id}"
end

def format_object_ref_list(object_refs)
	object_refs.map { |object_ref| format_object_ref(object_ref) }.join(', ')
end

def csv_field(value)
	text = value.to_s
	if text.include?(',') || text.include?('"') || text.include?("\n") || text.include?("\r")
		'"' + text.gsub('"', '""') + '"'
	else
		text
	end
end

def summary_csv_row(group_key, object_count, filename, status, object_refs)
	[
		group_key,
		object_count,
		filename,
		status,
		format_object_ref_list(object_refs)
	].map { |value| csv_field(value) }.join(',')
end

if WSApplication.ui?
	net = WSApplication.current_network
else
	db = WSApplication.open
	dbnet = db.model_object_from_type_and_id 'Collection Network', 2	## Collection Network #2 in Exchange
	net = dbnet.open
end

present_tables = net.tables.sort_by { |table| table_sort_key(table) }
present_table_names = present_tables.map(&:name)
network_profile = detect_network_profile(present_table_names)
snapshot_extension = snapshot_extension_for_profile(network_profile)

if present_tables.empty?
	abort 'No object tables were found in the current network.'
end

if WSApplication.ui?
	selected_tables = prompt_table_selection(present_tables)
	if selected_tables.nil?
		abort 'Export cancelled - table selection closed.'
	end
	if selected_tables.empty?
		WSApplication.message_box('No object tables were selected.', 'OK', '!', false)
		abort 'Export cancelled - no tables selected.'
	end

	while true
		val = WSApplication.prompt 'Snapshot export - group by field',
		[
			['Export folder:', 'String', export_folder, nil, 'FOLDER', 'Select export folder'],
			['Export file prefix (optional):', 'String', file_prefix],
			['Leave blank to use Snapshot_', 'Readonly', ''],
			['Process selection only?', 'Boolean', selection_only],
			['Unchecked = all objects in the selected tables.', 'Readonly', ''],
			['Group field:', 'String', group_field],
			['Object field, or pipe.fieldname (e.g. pipe.user_text_29).', 'Readonly', ''],
			['Label for blank group values (optional):', 'String', blank_group_label],
			['Skip objects with blank group values', 'Boolean', skip_blank_groups],
			['Include image files', 'Boolean', include_image_files],
			['Attached images are included in the snapshot.', 'Readonly', ''],
			['Include GeoPlan properties and themes', 'Boolean', include_geoplan_properties],
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
		include_image_files = prompt_bool(prompt_val(val, 9, include_image_files))
		include_geoplan_properties = prompt_bool(prompt_val(val, 11, include_geoplan_properties))
		subfolder_per_group = prompt_bool(prompt_val(val, 12, subfolder_per_group))

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
				"Group field is required.\n\nEnter an object field name or pipe.fieldname.",
				'OK', '!', false
			)
			next
		end

		break
	end
else
	selected_tables = parse_source_tables(source_tables, present_table_names)
	if selected_tables.empty?
		abort 'No source tables configured.'
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
export_options = snapshot_export_options(include_image_files, include_geoplan_properties)

object_refs = collect_object_refs(net, selected_tables, selection_only)

if object_refs.empty?
	if selection_only
		abort 'No objects found in the current selection for the selected tables.'
	end
	abort 'No objects found in the selected tables.'
end

groups, skipped_blank, objects_without_pipe = group_objects(
	net, object_refs, group_field, blank_group_label, skip_blank_groups
)

if groups.empty?
	abort 'No object groups to export after grouping.'
end

puts "Export folder: #{export_folder}"
puts "Network profile: #{network_profile_label(network_profile)}"
puts "Snapshot extension: .#{snapshot_extension}"
puts "File prefix: #{file_prefix}"
puts "Source tables: #{selected_tables.join(', ')}"
puts "Group field: #{group_field}"
puts "Scope: #{selection_only ? 'Selection only' : 'All objects in selected tables'}"
puts "Objects to process: #{object_refs.length}"
puts "Groups to export: #{groups.length}"
puts "Objects without related pipe: #{objects_without_pipe}" if group_field.to_s.strip.downcase.start_with?('pipe.')
puts "Skipped blank groups: #{skipped_blank}" if skipped_blank > 0
puts "Include image files: #{include_image_files}"
puts "Include GeoPlan properties and themes: #{include_geoplan_properties}"
puts "Subfolder per group: #{subfolder_per_group}"
puts "Log file: #{log_file}"
puts "Summary CSV: #{summary_csv}"

if WSApplication.ui?
	summary_message = "Found #{object_refs.length} object(s) in #{groups.length} group(s) across #{selected_tables.length} table(s)."
	summary_message += "\n#{objects_without_pipe} object(s) have no related pipe (grouped as #{blank_group_label})." if group_field.to_s.strip.downcase.start_with?('pipe.') && objects_without_pipe > 0
	summary_message += "\n#{skipped_blank} object(s) skipped (blank group value)." if skipped_blank > 0
	summary_message += "\n\nContinue with export?"

	if WSApplication.message_box(summary_message, 'YesNo', 'Information', false).to_s.downcase != 'yes'
		abort 'Export cancelled by user.'
	end
end

export_log_header = [
	"Snapshot export - group by field (#{run_stamp})",
	"Network profile: #{network_profile_label(network_profile)}",
	"Snapshot extension: .#{snapshot_extension}",
	"Export folder: #{export_folder}",
	"File prefix: #{file_prefix}",
	"Source tables: #{selected_tables.join(', ')}",
	"Group field: #{group_field}",
	"Scope: #{selection_only ? 'Selection only' : 'All objects in selected tables'}",
	"Objects to process: #{object_refs.length}",
	"Groups to export: #{groups.length}",
	"Include image files: #{include_image_files}",
	"Include GeoPlan properties and themes: #{include_geoplan_properties}",
	"Subfolder per group: #{subfolder_per_group}"
]
export_log_header << "Objects without related pipe: #{objects_without_pipe}" if group_field.to_s.strip.downcase.start_with?('pipe.')
export_log_header << "Skipped blank groups: #{skipped_blank}" if skipped_blank > 0
export_log_header << ''
write_export_log_header(log_file, export_log_header)

summary_log = File.open(summary_csv, 'w')
summary_log.puts 'Group,ObjectCount,Filename,Status,ObjectIDs'

used_export_labels = {}
groups.sort.each do |group_key, grouped_object_refs|
	export_label, disambiguated = unique_export_label(group_key, used_export_labels)

	group_folder = export_folder
	if subfolder_per_group
		group_folder = "#{export_folder}#{export_label}\\"
		ensure_directory(group_folder)
	end

	net.clear_selection
	grouped_object_refs.each do |table_name, object_id|
		row = load_row_object(net, table_name, object_id)
		row.selected = true if row
	end

	filename = "#{group_folder}#{file_prefix}#{export_label}.#{snapshot_extension}"
	append_export_log(log_file, "Group #{group_key}: #{grouped_object_refs.length} object(s)")
	append_export_log(log_file, "  Export label: #{export_label}") if disambiguated
	append_export_log(log_file, "  Object IDs: #{format_object_ref_list(grouped_object_refs)}")
	append_export_log(log_file, "  Export: #{filename}")
	result = net.snapshot_export_ex(filename, export_options)
	status = snapshot_export_status(result, filename)
	append_export_log(log_file, "  Status: #{status}") if status != 'OK'
	summary_log.puts summary_csv_row(group_key, grouped_object_refs.length, filename, status, grouped_object_refs)
end

summary_log.close
append_export_log(log_file, 'Export complete.')
