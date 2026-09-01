# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-odic_import_ex-CSV-Prompt.rb
# Purpose: Run an ODIC CSV import for a configured object table. Paste the mapped
#          line from an ODIC-saved .cfg into IMPORT_CONFIG, write a minimal .cfg
#          (DBI002 + mapped line only) to the working folder, then run odic_import_ex.
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

require 'fileutils'

# ---------------------------------------------------------------------------
# CUSTOMISE THIS SECTION for your import
# ---------------------------------------------------------------------------
#
# odic_table                 - ODIC UI table name for odic_import_ex (spaces removed).
#                              Examples: 'node', 'pipe', 'CCTVSurvey', 'ManholeSurveyAttachments'
# mapped_line                - The field-mapping line from a .cfg saved in ODIC (the line
#                              after DBI002, not the table-registry lines). Example:
#                              cams_manhole,{{"asset_id","asset_id","","",""},{"notes","notes","","",""}}
# config_name                - Filename written to the working folder (no path).
# csv_id_column              - Optional CSV column for the import summary. Auto-detected from
#                              mapped_line when omitted (id, node_id, asset_id, or pipe keys).
# callback_source_id_field   - Optional source field recorded by the ODIC callback on each row
#                              (e.g. CHAMB_REF_). Auto-detected from mapped_line when omitted.
# use_import_id_callback     - When true, records source IDs during import for the summary.
#                              Merged with custom_callback_class when that is set.
# custom_callback_class      - Optional ODIC callback class (see example below and folder
#                              0002A ODIC Callback Examples). User onBegin/onEnd run first;
#                              ID tracking runs after onEnd when use_import_id_callback is true.
#
# Optional custom callback — define above IMPORT_CONFIG, then set custom_callback_class:
#
#   class MyImporter
#     def MyImporter.onEndRecordNode(obj)
#       obj['user_text_1'] = obj['external_ref'].to_s
#     end
#   end
#
IMPORT_CONFIG = {
  odic_table: 'node',
  mapped_line: 'cams_manhole,{{"node_id","node_id","","",""},{"asset_id","asset_id","","",""},{"user_text_2","external_ref","","",""}}',
  config_name: 'ODIC_Import.cfg',
  csv_id_column: nil,
  callback_source_id_field: nil,
  use_import_id_callback: true,
  custom_callback_class: nil
}.freeze

# ODIC import options — edit here (not prompted at run time).
# 'Error File' is set automatically in the working folder.
# 'Duplication Behaviour': 'Overwrite', 'Merge', or 'Ignore'
#
IMPORT_OPTIONS = {
  'Error File' => nil,
  'Callback Class' => nil,
  'Set Value Flag' => 'CSV',
  'Default Value Flag' => nil,
  'Image Folder' => nil,
  'Duplication Behaviour' => 'Ignore',
  'Units Behaviour' => 'User',
  'Update Based On Asset ID' => false,
  'Update Only' => false,
  'Delete Missing Objects' => false,
  'Allow Multiple Asset IDs' => false,
  'Update Links From Points' => false,
  'Blob Merge' => false,
  'Use Network Naming Conventions' => false,
  'Import Images' => false,
  'Group Type' => nil,
  'Group Name' => nil
}.freeze

ERROR_LOG_BASENAME = 'ODIC_Import_Errors.txt'.freeze
NOT_IMPORTED_IDS_DIALOG_LIMIT = 25

ID_TARGET_FIELDS = %w[id node_id asset_id survey_id].freeze
PIPE_KEY_FIELDS = %w[us_node_id ds_node_id link_suffix].freeze

$odic_imported_source_ids = []

# ---------------------------------------------------------------------------
# ODIC callback — record source IDs as each CSV record is processed
# ---------------------------------------------------------------------------

def odic_record_suffix(odic_table)
  name = odic_table.to_s.strip
  return name if name.empty?
  return name[0].upcase + name[1..-1] if name == name.downcase

  name
end

def string_field_name?(value)
  value.is_a?(String) || value.is_a?(Symbol)
end

def hash_match_key?(match_key)
  match_key.is_a?(Hash)
end

def import_source_field_name(match_key, configured_field = nil)
  if string_field_name?(configured_field)
    name = configured_field.to_s.strip
    return name unless name.empty?
  end

  return nil unless hash_match_key?(match_key) && match_key[:type] == :single

  source = match_key[:source]
  return nil unless string_field_name?(source)

  source.to_s.strip
end

def tracking_composite_source_fields(match_key)
  return nil unless hash_match_key?(match_key) && match_key[:type] == :composite

  fields = match_key[:fields].map do |_target, source|
    next nil unless string_field_name?(source)

    source.to_s.strip
  end.compact
  fields.empty? ? nil : fields
end

def append_tracked_import_id(obj, field_name)
  return if field_name.nil? || field_name.empty?

  value = obj[field_name]
  return if value.nil?

  id = normalize_id(value)
  $odic_imported_source_ids << id unless id.empty?
end

def append_tracked_composite_import_id(obj, source_fields)
  parts = source_fields.map { |field| obj[field].to_s.strip }
  id = parts.all?(&:empty?) ? '' : parts.join('.')
  id = normalize_id(id)
  $odic_imported_source_ids << id unless id.empty?
end

def call_user_callback(user_class, method_names, obj)
  return unless user_class

  method_names.each do |method_name|
    next unless user_class.respond_to?(method_name)

    user_class.send(method_name, obj)
    return
  end
end

def user_callback_responds?(user_class, method_names)
  user_class && method_names.any? { |method_name| user_class.respond_to?(method_name) }
end

def build_merged_callback_class(odic_table, match_key, user_callback_class, source_field_name)
  suffix = odic_record_suffix(odic_table)
  begin_methods = ["OnBeginRecord#{suffix}", "onBeginRecord#{suffix}"]
  end_methods = ["onEndRecord#{suffix}", "OnEndRecord#{suffix}"]
  captured_match_key = hash_match_key?(match_key) ? match_key : nil
  captured_source_field = import_source_field_name(captured_match_key, source_field_name)
  captured_composite_fields = tracking_composite_source_fields(captured_match_key)

  merged = Class.new

  if user_callback_responds?(user_callback_class, begin_methods)
    begin_methods.each do |method_name|
      merged.define_singleton_method(method_name) do |obj|
        call_user_callback(user_callback_class, begin_methods, obj)
      end
    end
  end

  if captured_composite_fields
    composite_fields = captured_composite_fields
    end_methods.each do |method_name|
      merged.define_singleton_method(method_name) do |obj|
        call_user_callback(user_callback_class, end_methods, obj)
        begin
          append_tracked_composite_import_id(obj, composite_fields)
        rescue StandardError => e
          puts "ID tracking warning: #{e.message}"
        end
      end
    end
  elsif captured_source_field && !captured_source_field.empty?
    id_field = captured_source_field
    end_methods.each do |method_name|
      merged.define_singleton_method(method_name) do |obj|
        call_user_callback(user_callback_class, end_methods, obj)
        begin
          append_tracked_import_id(obj, id_field)
        rescue StandardError => e
          puts "ID tracking warning: #{e.message}"
        end
      end
    end
  else
    end_methods.each do |method_name|
      merged.define_singleton_method(method_name) do |obj|
        call_user_callback(user_callback_class, end_methods, obj)
      end
    end
  end

  merged
end

def resolve_custom_callback_class(import_config)
  import_config[:custom_callback_class] || IMPORT_OPTIONS['Callback Class']
end

def build_import_callback_class(import_config, odic_table, match_key, source_id_field)
  user_callback = resolve_custom_callback_class(import_config)
  tracking_enabled = import_config.fetch(:use_import_id_callback, true) && (source_id_field || match_key)

  if tracking_enabled
    $odic_imported_source_ids = []
    validated_source_field = import_source_field_name(match_key, source_id_field)
    merged = build_merged_callback_class(odic_table, match_key, user_callback, validated_source_field)
    {
      callback_class: merged,
      tracking_enabled: true,
      user_callback: user_callback
    }
  elsif user_callback
    {
      callback_class: user_callback,
      tracking_enabled: false,
      user_callback: user_callback
    }
  else
    {
      callback_class: nil,
      tracking_enabled: false,
      user_callback: nil
    }
  end
end

def resolve_source_id_field(import_config, _mapped_line, match_key)
  field = import_config[:callback_source_id_field]
  field = nil unless string_field_name?(field)
  field = import_config[:csv_id_column] if field.nil? || field.to_s.strip.empty?
  field = nil unless string_field_name?(field)
  import_source_field_name(match_key, field)
end

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def win_path(path)
  path.to_s.strip.gsub('/', '\\')
end

def working_folder
  folder = WSApplication.local_root.to_s.strip
  return folder unless folder.empty?

  'C:\\Temp'
rescue StandardError
  'C:\\Temp'
end

def prompt_cancel(message)
  WSApplication.message_box("#{message}\nScript cancelled", 'OK', '!', false)
  raise 'abort'
end

def normalise_mapped_line(mapped_line)
  text = mapped_line.to_s.strip
  prompt_cancel('Mapped line is required. Paste the field-mapping line from your ODIC .cfg into IMPORT_CONFIG[:mapped_line].') if text.empty?

  line = text.split(/\r?\n/).map(&:strip).reject(&:empty?).find do |candidate|
    candidate.include?(',{') && !candidate.match?(/\ADBI00[12]\z/i)
  end
  line ||= text.sub(/\ADBI00[12]\s*\r?\n?/i, '').strip

  prompt_cancel('Mapped line must include field mappings in ODIC format, e.g. cams_manhole,{{"asset_id","asset_id","","",""}}') unless line.include?(',{')

  line.sub(/,\z/, '')
end

def table_key_from_mapped_line(mapped_line)
  idx = mapped_line.index(',{')
  return mapped_line unless idx

  mapped_line[0...idx]
end

def build_odic_import_cfg(mapped_line)
  "DBI002\n#{mapped_line}\n"
end

def build_cfg_for_import(import_config)
  mapped_line = normalise_mapped_line(import_config[:mapped_line])
  build_odic_import_cfg(mapped_line)
end

def write_cfg_file(folder, filename, contents)
  path = File.join(folder, filename)
  File.write(path, contents)
  path
end

def import_options_for_run(folder, callback_class = nil)
  options = IMPORT_OPTIONS.dup
  options['Error File'] = File.join(folder, ERROR_LOG_BASENAME)
  options['Callback Class'] = callback_class if callback_class
  options.reject { |_key, value| value.nil? }
end

def prepare_error_log(error_file)
  return if error_file.nil? || error_file.to_s.strip.empty?

  File.delete(error_file) if File.file?(error_file)
rescue StandardError => e
  puts "Could not clear previous error log (#{error_file}): #{e.message}"
end

def prompt_import_settings(default_folder, mapped_line)
  table_key = table_key_from_mapped_line(mapped_line)
  val = WSApplication.prompt(
    'ODIC CSV Import',
    [
      ['Import table:', 'Readonly', IMPORT_CONFIG[:odic_table]],
      ['Mapped line table:', 'Readonly', table_key],
      ['CSV file to import:', 'String', nil, nil, 'FILE', true, 'csv', 'Select CSV file', false],
      ['Config and error log folder (working folder):', 'String', default_folder, nil, 'FOLDER', 'Working folder']
    ],
    false
  )
  prompt_cancel('Parameters dialog closed') if val.nil?

  csv_path = win_path(val[2])
  prompt_cancel('CSV file is required') if csv_path.nil? || csv_path.empty?
  prompt_cancel("CSV file not found:\n#{csv_path}") unless File.file?(csv_path)

  output_folder = win_path(val[3])
  prompt_cancel('Working folder is required') if output_folder.nil? || output_folder.empty?
  FileUtils.mkdir_p(output_folder) unless File.directory?(output_folder)

  {
    csv_path: csv_path,
    output_folder: output_folder
  }
end

def parse_csv_line(line)
  fields = []
  field = ''
  in_quotes = false
  i = 0
  while i < line.length
    ch = line[i]
    if in_quotes
      if ch == '"'
        if i + 1 < line.length && line[i + 1] == '"'
          field << '"'
          i += 1
        else
          in_quotes = false
        end
      else
        field << ch
      end
    elsif ch == '"'
      in_quotes = true
    elsif ch == ','
      fields << field
      field = ''
    else
      field << ch
    end
    i += 1
  end
  fields << field
  fields
end

def normalize_text(value)
  text = value.to_s.dup
  if text.encoding == Encoding::ASCII_8BIT
    utf8 = text.dup.force_encoding('UTF-8')
    text = if utf8.valid_encoding?
             utf8
           else
             text.force_encoding('Windows-1252').encode('UTF-8')
           end
  else
    text = text.encode('UTF-8')
  end
  text.sub(/\A\uFEFF/, '').strip
end

def normalize_csv_header(header)
  normalize_text(header)
end

def normalize_id(value)
  normalize_text(value)
end

def row_value_case_insensitive(row, column_name)
  return nil if column_name.nil? || column_name.to_s.strip.empty?

  key = normalize_csv_header(column_name)
  row.each do |header, value|
    return value if normalize_csv_header(header).casecmp(key).zero?
  end
  nil
end

def read_csv_file_text(csv_path)
  bytes = ''
  File.open(csv_path, 'rb') do |file|
    bytes = file.read
  end
  bytes = bytes.sub(/\A\xEF\xBB\xBF/n, '')
  text = bytes.dup.force_encoding('UTF-8')
  if text.valid_encoding?
    text
  else
    bytes.dup.force_encoding('Windows-1252').encode('UTF-8')
  end
end

def read_csv_rows(csv_path)
  text = read_csv_file_text(csv_path)
  lines = text.split(/\r?\n/)
  return { headers: [], rows: [] } if lines.empty?

  headers = parse_csv_line(lines[0].to_s.chomp).map { |header| normalize_csv_header(header) }
  rows = []
  lines[1..-1].each do |line|
    next if line.to_s.strip.empty?

    values = parse_csv_line(line.to_s.chomp)
    row = {}
    headers.each_with_index { |header, index| row[header] = values[index] }
    rows << row
  end

  { headers: headers, rows: rows }
end

def parse_field_mappings_from_mapped_line(mapped_line)
  mappings = []
  mapped_line.scan(/\{"([^"]*)","([^"]*)","([^"]*)","([^"]*)","([^"]*)"\}/) do |target, source, _default, _flag, _units|
    mappings << [target, source]
  end
  mappings
end

def match_key_from_mappings(mappings)
  targets = mappings.map(&:first)

  if PIPE_KEY_FIELDS.all? { |field| targets.include?(field) }
    fields = PIPE_KEY_FIELDS.map do |target|
      mapping = mappings.find { |entry| entry[0] == target }
      return nil unless mapping

      [target, mapping[1]]
    end
    return { type: :composite, fields: fields }
  end

  ID_TARGET_FIELDS.each do |target|
    mapping = mappings.find { |entry| entry[0] == target }
    next if mapping.nil? || mapping[1].to_s.strip.empty?

    return { type: :single, target: target, source: mapping[1] }
  end

  mapping = mappings.find { |target, source| target == source && !target.to_s.strip.empty? }
  return { type: :single, target: mapping[0], source: mapping[1] } if mapping

  nil
end

def match_key_label(match_key)
  return nil if match_key.nil?

  case match_key[:type]
  when :composite
    match_key[:fields].map { |target, source| "#{target} (#{source})" }.join(', ')
  when :single
    "#{match_key[:target]} (#{match_key[:source]})"
  end
end

def csv_row_match_id(row, match_key)
  case match_key[:type]
  when :composite
    parts = match_key[:fields].map { |_target, source| row_value_case_insensitive(row, source).to_s.strip }
    return nil if parts.all?(&:empty?)

    parts.join('.')
  when :single
    value = row_value_case_insensitive(row, match_key[:source]).to_s.strip
    value.empty? ? nil : value
  end
end

def callback_row_match_id(row, source_id_field, match_key)
  return csv_row_match_id(row, match_key) if match_key

  value = row[source_id_field].to_s.strip
  value.empty? ? nil : value
end

def object_field_value(obj, field)
  return '' if field.nil? || field.to_s.strip.empty?

  if obj.respond_to?(field)
    obj.send(field).to_s.strip
  elsif obj.respond_to?(:[])
    obj[field].to_s.strip
  else
    ''
  end
end

def object_match_id(obj, match_key)
  case match_key[:type]
  when :composite
    parts = match_key[:fields].map do |target, _source|
      value = object_field_value(obj, target)
      value = object_field_value(obj, 'id') if value.empty? && target != 'id'
      value
    end
    return '' if parts.all?(&:empty?)

    parts.join('.')
  when :single
    target = match_key[:target]
    source = match_key[:source]
    [target, source, 'id'].uniq.each do |field|
      value = object_field_value(obj, field)
      return value unless value.empty?
    end
    ''
  end
end

def unique_ids(ids)
  seen = {}
  ids.map { |id| normalize_id(id) }.reject(&:empty?).select do |id|
    next false if seen[id]

    seen[id] = true
    true
  end
end

def ids_not_imported(source_ids, imported_ids)
  imported_lookup = {}
  unique_ids(imported_ids).each { |id| imported_lookup[id] = true }
  unique_ids(source_ids).reject { |id| imported_lookup[id] }
end

def analyse_csv_import(csv_path, mapped_line, imported_objects, csv_id_column = nil, callback_imported_ids = nil, source_id_field = nil)
  csv_data = read_csv_rows(csv_path)
  api_import_count = imported_object_count(imported_objects)
  callback_ids = (callback_imported_ids || []).map(&:to_s).reject(&:empty?)

  match_key = if csv_id_column && !csv_id_column.to_s.strip.empty?
                { type: :single, target: csv_id_column, source: csv_id_column }
              else
                match_key_from_mappings(parse_field_mappings_from_mapped_line(mapped_line))
              end

  unless match_key || (source_id_field && !source_id_field.to_s.strip.empty?)
    return {
      csv_row_count: csv_data[:rows].length,
      imported_count: api_import_count,
      api_import_count: api_import_count,
      callback_import_count: callback_ids.length,
      not_imported_ids: [],
      match_key_label: source_id_field,
      id_comparison_available: false,
      used_callback_tracking: callback_ids.any?
    }
  end

  csv_ids = csv_data[:rows].map do |row|
    callback_row_match_id(row, source_id_field, match_key)
  end.compact

  api_imported_ids = (imported_objects || []).map { |obj| object_match_id(obj, match_key) }
  source_ids = callback_ids.any? ? callback_ids : csv_ids
  not_imported_ids = ids_not_imported(source_ids, api_imported_ids)

  label = match_key_label(match_key)
  label = source_id_field.to_s if label.nil? && source_id_field

  {
    csv_row_count: csv_data[:rows].length,
    imported_count: api_import_count,
    api_import_count: api_import_count,
    callback_import_count: callback_ids.length,
    not_imported_ids: not_imported_ids,
    match_key_label: label,
    id_comparison_available: true,
    used_callback_tracking: callback_ids.any?
  }
end

def format_import_summary(summary, table_name, id_limit = nil)
  lines = []
  lines << "CSV rows: #{summary[:csv_row_count]}"

  if summary[:used_callback_tracking]
    lines << "Processed through ODIC callback: #{summary[:callback_import_count]} (#{summary[:match_key_label]})"
  end

  api_import_count = summary[:api_import_count]
  lines << "Imported or updated: #{api_import_count} #{table_name} object#{'s' unless api_import_count == 1}"

  if summary[:id_comparison_available]
    not_imported_ids = summary[:not_imported_ids]
    lines << "Not imported: #{not_imported_ids.length}"
    unless not_imported_ids.empty?
      comparison_source = summary[:used_callback_tracking] ? 'processed but not imported' : 'in CSV but not imported'
      lines << "Not imported IDs (#{comparison_source}, #{summary[:match_key_label]}):"
      ids_to_show = id_limit ? not_imported_ids.first(id_limit) : not_imported_ids
      ids_to_show.each { |id| lines << "  #{id}" }
      remaining = not_imported_ids.length - ids_to_show.length
      lines << "  ... and #{remaining} more (see Ruby console output)" if remaining > 0
    end
  else
    lines << 'ID comparison unavailable (could not detect an ID column from mapped_line).'
    lines << 'Set IMPORT_CONFIG[:csv_id_column] or [:callback_source_id_field] to enable not-imported ID reporting.'
  end

  lines.join("\n")
end

def read_error_log(error_file)
  return '' unless File.file?(error_file) && File.size(error_file) > 0

  File.read(error_file).strip
rescue StandardError => e
  "Could not read error log (#{error_file}): #{e.message}"
end

def imported_object_count(imported_objects)
  return 0 if imported_objects.nil?

  imported_objects.respond_to?(:length) ? imported_objects.length : 0
end

def report_import_result(cfg_path, csv_path, error_file, summary, table_name)
  summary_text = format_import_summary(summary, table_name)
  dialog_summary = format_import_summary(summary, table_name, NOT_IMPORTED_IDS_DIALOG_LIMIT)

  puts 'ODIC import completed.'
  puts "  Config:  #{cfg_path}"
  puts "  CSV:     #{csv_path}"
  puts '  Summary:'
  summary_text.each_line { |line| puts "    #{line.chomp}" }

  if File.file?(error_file) && File.size(error_file) > 0
    error_text = read_error_log(error_file)
    puts "  Errors:  #{error_file}"
    unless error_text.empty?
      puts '  Error log:'
      error_text.each_line { |line| puts "    #{line.chomp}" }
    end
    WSApplication.message_box(
      "Import finished with errors.\n\n#{dialog_summary}\n\n#{error_text}",
      'OK', '!', false
    )
  else
    puts '  Errors:  none'
    WSApplication.message_box(
      "Import completed.\n\n#{dialog_summary}",
      'OK', 'Information', false
    )
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

begin
  net = WSApplication.current_network
  prompt_cancel('No open network found. Open a network, then run via Network > Run Ruby Script.') if net.nil?

  mapped_line = normalise_mapped_line(IMPORT_CONFIG[:mapped_line])
  settings = prompt_import_settings(working_folder, mapped_line)
  cfg_contents = build_cfg_for_import(IMPORT_CONFIG)
  cfg_path = write_cfg_file(settings[:output_folder], IMPORT_CONFIG[:config_name], cfg_contents)

  match_key = match_key_from_mappings(parse_field_mappings_from_mapped_line(mapped_line))
  source_id_field = resolve_source_id_field(IMPORT_CONFIG, mapped_line, match_key)

  callback_setup = build_import_callback_class(
    IMPORT_CONFIG,
    IMPORT_CONFIG[:odic_table],
    match_key,
    source_id_field
  )
  callback_class = callback_setup[:callback_class]

  if callback_setup[:tracking_enabled]
    tracker_field = match_key ? match_key_label(match_key) : source_id_field
    if callback_setup[:user_callback]
      puts "Merged callback: #{callback_setup[:user_callback]} + ID tracking (#{tracker_field})"
    else
      puts "Import ID callback enabled (#{odic_record_suffix(IMPORT_CONFIG[:odic_table])}, field: #{tracker_field})"
    end
  elsif callback_setup[:user_callback]
    puts "Using custom callback class: #{callback_setup[:user_callback]} (ID tracking disabled)."
  end

  options = import_options_for_run(settings[:output_folder], callback_class)
  prepare_error_log(options['Error File'])

  puts 'Writing ODIC config:'
  puts "  #{cfg_path}"
  puts 'Starting ODIC import...'
  puts "  Table: #{IMPORT_CONFIG[:odic_table]}"
  puts "  CSV:   #{settings[:csv_path]}"

  imported_objects = net.odic_import_ex(
    'CSV',
    cfg_path,
    options,
    IMPORT_CONFIG[:odic_table],
    settings[:csv_path]
  )

  import_summary = analyse_csv_import(
    settings[:csv_path],
    mapped_line,
    imported_objects,
    IMPORT_CONFIG[:csv_id_column],
    $odic_imported_source_ids,
    source_id_field
  )

  report_import_result(
    cfg_path,
    settings[:csv_path],
    options['Error File'],
    import_summary,
    IMPORT_CONFIG[:odic_table]
  )
rescue RuntimeError => e
  raise e unless e.message == 'abort'
rescue StandardError => e
  WSApplication.message_box("Import failed:\n#{e.message}", 'OK', 'Stop', false)
  raise
end
