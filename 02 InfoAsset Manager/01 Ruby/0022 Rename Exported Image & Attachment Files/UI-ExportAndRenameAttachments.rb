# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-ExportAndRenameAttachments.rb
# Purpose: Export attachment and image files from a GeoPlan selection via ODEC,
#          then rename exported files using a user-defined filename format.
#
# Run from: Network > Run Ruby Script (with objects selected on the GeoPlan)
# ============================================================================

require 'csv'
require 'fileutils'

IMAGE_REF_FIELDS = %w[
  detail_image ds_image ds_photo external_photo injection_point_image
  internal_image internal_photo location_image location_photo location_sketch
  other_image photo plan_sketch sketch us_image us_photo
].freeze

FILENAME_FORMAT_PRESETS = [
  '{id}',
  '{id}_{filename}',
  '{id}_{purpose}',
  '{id}_{source}',
  '{table}_{id}',
  '{table}_{id}_{filename}',
  '{table}_{id}_{purpose}',
  '{table}_{id}_{source}',
  'Custom'
].freeze

FILENAME_PLACEHOLDER_HELP =
  'Placeholders: {table} {id} {filename} {purpose} {description} {source}'.freeze

INDEX_CSV_FILENAME = 'attachment_export_index.csv'.freeze
INDEX_LOG_FILENAME = 'attachment_export_log.txt'.freeze

EXPORT_LOG = { enabled: false, lines: [] }

def export_log(message = '')
  puts message
  return unless EXPORT_LOG[:enabled]

  message.to_s.each_line { |line| EXPORT_LOG[:lines] << line.chomp }
end

def write_export_log(path)
  return unless EXPORT_LOG[:enabled]

  File.open(path, 'w') { |f| f.puts EXPORT_LOG[:lines] }
end

def prompt_true?(value)
  value == true || value.to_s.strip.downcase == 'true'
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

ODEC_TABLE_NAME_OVERRIDES = {
  'cams_incident_odor' => 'Odorincident',
  'wams_incident_odor' => 'Odorincident',
  'ams_incident_odor' => 'Odorincident'
}.freeze

def field_display_name(field)
  field.description.to_s.strip
end

# Resolve the object ID field from table metadata (field description "ID").
# See 0030 List Network Fields-Structure for the introspection pattern.
def id_field_from_structure(table)
  table.fields.each do |field|
    next if field.data_type == 'WSStructure'

    return field.name if field_display_name(field).casecmp?('ID')
  end

  names = table_field_names(table)
  names.include?('id') ? 'id' : nil
end

def titleize_table_word(word)
  text = word.to_s.strip
  return '' if text.empty?

  # Keep acronyms such as CCTV and GPS unchanged.
  return text if text == text.upcase && text.length > 1

  text[0].upcase + text[1..].downcase
end

def table_filename_label(table)
  description = table_display_name(table).gsub('Odour', 'Odor')
  unless description.empty?
    return description.split(/\s+/).map { |word| titleize_table_word(word) }.join
  end

  db_name = table.name.sub(/\A(?:cams|wams|ams)_/, '')
  db_name.split('_').map { |part| titleize_table_word(part) }.join
end

def odec_ui_table_name(table)
  return ODEC_TABLE_NAME_OVERRIDES[table.name] if ODEC_TABLE_NAME_OVERRIDES.key?(table.name)

  description = table_display_name(table)
  unless description.empty?
    name = description.gsub(/\s+/, '').gsub('Odour', 'Odor')
    return name.length <= 1 ? name.upcase : name[0].upcase + name[1..].downcase
  end

  db_name = table.name.sub(/\A(?:cams|wams|ams)_/, '')
  derived = db_name.split('_').join
  derived.empty? ? table.name : derived[0].upcase + derived[1..].downcase
end

def row_object_id(ro)
  return ro.id.to_s.strip if ro.respond_to?(:id) && !ro.id.nil?

  ''
rescue StandardError
  ''
end

def row_field_value(ro, field_name)
  return ro[field_name].to_s.strip if ro.respond_to?(:[])

  ''
rescue StandardError
  ''
end

def blob_entry_db_ref(entry)
  return entry.db_ref.to_s.strip if entry.respond_to?(:db_ref)
  return entry['db_ref'].to_s.strip if entry.respond_to?(:[])

  ''
rescue StandardError
  ''
end

def detail_image_ref(entry)
  return entry.detail_image.to_s.strip if entry.respond_to?(:detail_image)
  return entry['detail_image'].to_s.strip if entry.respond_to?(:[])

  ''
rescue StandardError
  ''
end

def details_image_refs(ro, field_name)
  refs = []
  return refs unless ro.respond_to?(:[])

  blob = ro[field_name]
  return refs if blob.nil?

  if blob.respond_to?(:each)
    blob.each do |entry|
      next if entry.nil?

      ref = detail_image_ref(entry)
      refs << ref unless ref.empty?
    end
  end
  refs
rescue StandardError
  refs
end

def blob_entry_field_value(entry, field_name)
  return entry[field_name].to_s.strip if entry.respond_to?(:[]) && !entry[field_name].nil?
  return entry.send(field_name).to_s.strip if entry.respond_to?(field_name)

  ''
rescue StandardError
  ''
end

def with_user_units
  was_user_units = WSApplication.use_user_units?
  WSApplication.use_user_units = true unless was_user_units
  yield
ensure
  WSApplication.use_user_units = was_user_units unless was_user_units
end

def format_detail_distance(value)
  str = value.to_s.strip
  return '' if str.empty?
  return str unless str =~ /\A-?\d+(\.\d+)?\z/

  format('%.2f', str.to_f)
end

def details_purpose_from_values(code, distance)
  code = code.to_s.strip
  distance = format_detail_distance(distance)
  return "#{code}_#{distance}" if !code.empty? && !distance.empty?
  return code unless code.empty?
  return distance unless distance.empty?

  ''
end

def build_details_purpose_map(net, table, source)
  map = {}
  with_user_units do
    net.row_objects_selection(table.name).each do |ro|
      blob = ro[source[:field_name]]
      next if blob.nil?
      next unless blob.respond_to?(:each)

      blob.each do |entry|
        next if entry.nil?

        ref = detail_image_ref(entry)
        next if ref.empty?

        code = blob_entry_field_value(entry, 'code')
        distance = blob_entry_field_value(entry, 'distance')
        purpose = details_purpose_from_values(code, distance)
        map[ref] = purpose unless purpose.empty?
      end
    end
  end
  map
rescue StandardError => e
  export_log "WARNING: Could not build details purpose map for #{table.name}/#{source[:field_name]}: #{e.message}"
  {}
end

def blob_db_refs(ro, field_name)
  refs = []
  return refs unless ro.respond_to?(:[])

  blob = ro[field_name]
  return refs if blob.nil?

  if blob.respond_to?(:each)
    blob.each do |entry|
      next if entry.nil?

      ref = blob_entry_db_ref(entry)
      refs << ref unless ref.empty?
    end
  end
  refs
rescue StandardError
  refs
end

def build_db_ref_object_id_map(net, table, source)
  map = {}
  net.row_objects_selection(table.name).each do |ro|
    object_id = row_object_id(ro)
    next if object_id.empty?

    case source[:type]
    when :blob
      blob_db_refs(ro, source[:field_name]).each { |ref| map[ref] = object_id }
    when :details
      details_image_refs(ro, source[:field_name]).each { |ref| map[ref] = object_id }
    else
      ref = row_field_value(ro, source[:field_name])
      map[ref] = object_id unless ref.empty?
    end
  end
  map
rescue StandardError => e
  export_log "WARNING: Could not build object ID map for #{table.name}/#{source[:field_name]}: #{e.message}"
  {}
end

def selection_count(net, table_name)
  net.row_objects_selection(table_name).length
rescue StandardError
  0
end

def table_prompt_label_with_selection(net, table)
  count = selection_count(net, table.name)
  "#{table_prompt_label(table)} [#{count} selected]"
end

def table_field_names(table)
  table.fields.map(&:name)
end

def structure_blob_field?(field)
  field.data_type == 'WSStructure' &&
    !field.fields.nil? &&
    field.fields.any? { |bf| bf.name == 'db_ref' }
end

def details_blob_field?(field)
  field.data_type == 'WSStructure' &&
    !field.fields.nil? &&
    field.fields.any? { |bf| bf.name == 'detail_image' }
end

def image_reference_field?(table, field_name)
  return true if IMAGE_REF_FIELDS.include?(field_name)

  field = table.fields.find { |f| f.name == field_name }
  return false unless field
  return false unless field.data_type == 'String'

  name = field.name
  return true if name.end_with?('_image', '_photo', '_sketch')
  return true if %w[photo sketch].include?(name)

  table_field_names(table).include?("#{name}_filename")
end

def discover_export_sources(table)
  sources = []
  names = table_field_names(table)

  table.fields.each do |field|
    if structure_blob_field?(field)
      label = field.description.to_s.strip
      label = field.name if label.empty?
      sources << {
        key: "blob_#{field.name}",
        field_name: field.name,
        label: "#{label} (blob)",
        type: :blob
      }
    elsif details_blob_field?(field)
      label = field.description.to_s.strip
      label = field.name if label.empty?
      sources << {
        key: "details_#{field.name}",
        field_name: field.name,
        label: "#{label} - defect image (blob)",
        type: :details
      }
    end
  end

  candidate_names = (IMAGE_REF_FIELDS + names).uniq
  candidate_names.each do |field_name|
    next unless names.include?(field_name)
    next if structure_blob_field?(table.fields.find { |f| f.name == field_name })

    field = table.fields.find { |f| f.name == field_name }
    next unless field
    next unless field.data_type == 'String'
    next unless image_reference_field?(table, field_name)

    label = field.description.to_s.strip
    label = field.name if label.empty?
    sources << {
      key: "field_#{field_name}",
      field_name: field_name,
      label: label,
      type: :field
    }
  end

  sources
end

def odec_field_mapping(export_col, source_field)
  "{#{export_col},Field,Default,Default,Default,#{source_field}}"
end

def build_odec_export_cfg(table_db_name, field_mappings)
  mappings = field_mappings.map { |export_col, source| odec_field_mapping(export_col, source) }
  mapped_line = "#{table_db_name},{#{mappings.join(',')}}"
  "DBX002\n#{mapped_line}\n"
end

def pipe_composite_key_table?(table)
  names = table_field_names(table)
  names.include?('us_node_id') && names.include?('ds_node_id') && names.include?('link_suffix')
end

def table_id_field_mappings(table)
  if pipe_composite_key_table?(table)
    return [
      ['us_node_id', 'us_node_id'],
      ['ds_node_id', 'ds_node_id'],
      ['link_suffix', 'link_suffix']
    ]
  end

  pk = id_field_from_structure(table)
  return [] unless pk

  [[pk, pk]]
end

def object_id_from_csv_row(row, table)
  if pipe_composite_key_table?(table)
    us = row['us_node_id'].to_s.strip
    ds = row['ds_node_id'].to_s.strip
    suffix = row['link_suffix'].to_s.strip
    return '' if us.empty? && ds.empty? && suffix.empty?

    "#{us}.#{ds}.#{suffix}"
  else
    pk = id_field_from_structure(table)
    return '' unless pk

    row[pk].to_s.strip
  end
end

def blob_field_mappings(table, blob_field_name)
  table_id_field_mappings(table) + [
    ['db_ref', "#{blob_field_name}.db_ref"],
    ['filename', "#{blob_field_name}.filename"],
    ['purpose', "#{blob_field_name}.purpose"],
    ['description', "#{blob_field_name}.description"]
  ]
end

def details_subfield_names(table, details_field_name)
  field = table.fields.find { |f| f.name == details_field_name }
  return [] unless field && field.fields

  field.fields.map(&:name)
end

def details_field_mappings(table, details_field_name)
  mappings = table_id_field_mappings(table) + [
    ['db_ref', "#{details_field_name}.detail_image"]
  ]
  subfields = details_subfield_names(table, details_field_name)
  mappings << ['code', "#{details_field_name}.code"] if subfields.include?('code')
  mappings << ['distance', "#{details_field_name}.distance"] if subfields.include?('distance')
  mappings
end

def details_purpose_from_row(row)
  details_purpose_from_values(row['code'], row['distance'])
end

def image_field_mappings(table, field_name)
  mappings = table_id_field_mappings(table) + [
    ['db_ref', field_name]
  ]
  filename_field = "#{field_name}_filename"
  ref_field = "#{field_name}_ref"
  mappings << ['filename', filename_field] if table_field_names(table).include?(filename_field)
  mappings << ['description', ref_field] if table_field_names(table).include?(ref_field)
  mappings
end

def write_text(path, content)
  File.open(path, 'w') { |f| f.write(content) }
end

def sanitize_filename_part(value)
  value.to_s.strip
       .gsub(/[\\\/:\*\?"<>|]/, '_')
       .gsub(/[^0-9A-Za-z. _-]/, '')
       .gsub(/[ ]+/, ' ')
       .gsub(/_+/, '_')
       .gsub(/\A[_. ]+|[_. ]+\z/, '')
end

def sanitize_filename(value)
  sanitize_filename_part(value)
end

def resolve_filename_format(preset, custom_format)
  if preset == 'Custom'
    custom_format.to_s.strip
  else
    preset.to_s.strip
  end
end

def build_new_basename(row, format, table_label)
  replacements = {
    '{table}' => table_label,
    '{id}' => row['id'].to_s,
    '{filename}' => File.basename(row['filename'].to_s, '.*'),
    '{purpose}' => row['purpose'].to_s,
    '{description}' => row['description'].to_s,
    '{source}' => row['source_field'].to_s
  }

  name = format.dup
  replacements.each do |token, value|
    name = name.gsub(token, sanitize_filename_part(value))
  end
  sanitize_filename(name)
end

def reserve_unique_basename(folder_used, base)
  candidate = base
  index = 1
  while folder_used[candidate.downcase]
    candidate = "#{base}_#{index}"
    index += 1
  end
  folder_used[candidate.downcase] = true
  candidate
end

def ensure_folder_basenames(used_basenames, folder)
  key = folder.downcase
  used_basenames[key] = collect_existing_basenames(folder) unless used_basenames.key?(key)
  used_basenames[key]
end

def resolve_dest_folder(export_root, row, folder_by_table, folder_by_object_id)
  parts = [export_root]
  parts << sanitize_filename_part(row['table'].to_s) if folder_by_table
  parts << sanitize_filename_part(row['id'].to_s) if folder_by_object_id
  File.join(*parts)
end

def table_export_folder(export_root, table_label, folder_by_table)
  folder_by_table ? File.join(export_root, sanitize_filename_part(table_label)) : export_root
end

def collect_existing_basenames(folder)
  used = {}
  Dir.foreach(folder) do |entry|
    next if entry == '.' || entry == '..'

    path = File.join(folder, entry)
    next unless File.file?(path)

    used[File.basename(entry, '.*').downcase] = true
  end
  used
end

def track_created_folder(created_folders, path)
  normalized = File.expand_path(path.to_s)
  return if normalized.empty?

  created_folders << normalized unless created_folders.include?(normalized)
end

def folder_empty?(path)
  return false unless File.directory?(path)

  Dir.entries(path).none? { |entry| entry != '.' && entry != '..' }
end

def remove_empty_created_folders(created_folders)
  created_folders.uniq.sort_by { |folder| -folder.count(File::SEPARATOR) }.each do |folder|
    next unless File.directory?(folder)
    next unless folder_empty?(folder)

    Dir.rmdir(folder)
    export_log "REMOVED empty folder: #{folder}"
  rescue StandardError => e
    export_log "NOTE: Could not remove empty folder #{folder}: #{e.message}"
  end
end

def export_source_rows(net, table, source, export_root, odec_table, odec_folder, table_label)
  cfg_path = File.join(export_root, "_odec_#{source[:key]}.cfg")
  csv_path = File.join(export_root, "_odec_#{source[:key]}.csv")

  mappings =
    case source[:type]
    when :blob
      blob_field_mappings(table, source[:field_name])
    when :details
      details_field_mappings(table, source[:field_name])
    else
      image_field_mappings(table, source[:field_name])
    end

  write_text(cfg_path, build_odec_export_cfg(table.name, mappings))

  options = {
    'Error File' => File.join(export_root, 'ExportErrorLog.txt'),
    'Image Folder' => odec_folder,
    'Append' => false,
    'Export Selection' => true,
    'Units Behaviour' => 'User'
  }

  net.odec_export_ex('csv', cfg_path, options, odec_table, csv_path)

  id_map = build_db_ref_object_id_map(net, table, source)
  purpose_map = source[:type] == :details ? build_details_purpose_map(net, table, source) : {}
  rows = []
  if File.file?(csv_path)
    CSV.foreach(csv_path, headers: true) do |row|
      db_ref = row['db_ref'].to_s.strip
      db_ref = row['detail_image'].to_s.strip if db_ref.empty?
      next if db_ref.empty?

      object_id = id_map[db_ref]
      object_id = object_id_from_csv_row(row, table) if object_id.nil? || object_id.empty?

      purpose =
        if source[:type] == :details
          purpose = purpose_map[db_ref].to_s.strip
          purpose = details_purpose_from_row(row) if purpose.empty?
          purpose
        else
          row['purpose'].to_s.strip
        end

      source_field =
        if source[:type] == :details
          "#{source[:field_name]}.detail_image"
        else
          source[:field_name]
        end

      rows << {
        'table' => table_label,
        'id' => object_id,
        'db_ref' => db_ref,
        'filename' => row['filename'].to_s.strip,
        'purpose' => purpose,
        'description' => row['description'].to_s.strip,
        'source_field' => source_field
      }
    end
  end

  File.delete(cfg_path) if File.exist?(cfg_path)
  File.delete(csv_path) if File.exist?(csv_path)
  rows
rescue StandardError => e
  export_log "ERROR exporting #{source[:label]}: #{e.message}"
  []
end

def write_index_csv(path, rows)
  headers = %w[table id folder db_ref filename purpose description source_field new_filename]
  CSV.open(path, 'w', write_headers: true, headers: headers) do |csv|
    rows.each { |row| csv << headers.map { |h| row[h] } }
  end
end

def fallback_export_basename(row, file_from)
  candidates = [
    File.basename(row['filename'].to_s, '.*'),
    File.basename(file_from, '.*'),
    row['db_ref'].to_s
  ]
  candidates.each do |candidate|
    base = sanitize_filename_part(candidate)
    return base unless base.empty?
  end
  'export'
end

def resolve_export_basename(row, format, table_label, file_from)
  new_base = build_new_basename(row, format, table_label)
  return new_base unless new_base.empty?

  fallback = fallback_export_basename(row, file_from)
  export_log "NOTE: empty filename after sanitisation; using [#{fallback}] (id=#{row['id']}, source=#{row['source_field']})"
  fallback
end

def rename_exported_files(export_root, rows, format, used_basenames, folder_by_table, folder_by_object_id, odec_folder, created_folders)
  used_basenames = {} if used_basenames.nil?
  renamed = 0
  skipped = 0

  rows.each do |row|
    db_ref = row['db_ref'].to_s.strip
    next if db_ref.empty?

    file_from = File.join(odec_folder, db_ref)
    unless File.file?(file_from)
      export_log "SKIP: source file not found [#{db_ref}] (id=#{row['id']}, source=#{row['source_field']})"
      skipped += 1
      next
    end

    dest_folder = resolve_dest_folder(export_root, row, folder_by_table, folder_by_object_id)
    FileUtils.mkdir_p(dest_folder)
    track_created_folder(created_folders, dest_folder)
    folder_used = ensure_folder_basenames(used_basenames, dest_folder)

    new_base = resolve_export_basename(row, format, row['table'].to_s, file_from)
    unique_base = reserve_unique_basename(folder_used, new_base)
    extension = File.extname(file_from)
    file_to = File.join(dest_folder, unique_base + extension)

    relative_folder = dest_folder.sub(/\A#{Regexp.escape(export_root)}[\/\\]?/i, '')
    row['folder'] = relative_folder
    row['new_filename'] = unique_base + extension

    File.rename(file_from, file_to)
    dest_label = relative_folder.empty? ? unique_base + extension : File.join(relative_folder, unique_base + extension)
    export_log "RENAMED: #{db_ref} -> #{dest_label}"
    renamed += 1
  end

  [renamed, skipped, used_basenames]
end

def discover_export_sources_for_tables(tables)
  sources = []
  tables.each do |table|
    discover_export_sources(table).each do |source|
      entry = source.dup
      entry[:table] = table
      entry[:key] = "#{table.name}_#{source[:key]}"
      entry[:label] = "#{table_prompt_label(table)} - #{source[:label]}"
      sources << entry
    end
  end
  sources
end

def prompt_selected_tables(net, tables_with_selection)
  table_prompt = [
    ['Select all tables', 'Boolean', false],
    ['Only tables with a current GeoPlan selection are listed.', 'Readonly', '']
  ]
  tables_with_selection.each do |table|
    table_prompt << [table_prompt_label_with_selection(net, table), 'Boolean', false]
  end

  table_val = WSApplication.prompt('Export Attachments - Select Object Tables', table_prompt, false)
  return nil if table_val.nil?

  select_all = prompt_true?(table_val[0])
  selected_tables = []
  tables_with_selection.each_with_index do |table, idx|
    selected_tables << table if select_all || prompt_true?(table_val[idx + 2])
  end
  selected_tables
end

def process_table_exports(net, table, table_sources, export_root, filename_format, used_basenames, folder_by_table, folder_by_object_id, created_folders)
  odec_table = odec_ui_table_name(table)
  table_label = table_filename_label(table)
  odec_folder = table_export_folder(export_root, table_label, folder_by_table)
  FileUtils.mkdir_p(odec_folder)
  track_created_folder(created_folders, odec_folder)
  table_rows = []

  export_log ''
  export_log "Table         : #{table_prompt_label(table)}"
  export_log "ODEC table    : #{odec_table}"
  export_log "Table label   : #{table_label}"
  export_log "Export folder : #{odec_folder}"
  export_log "Selection     : #{selection_count(net, table.name)} object(s)"
  export_log "Sources       : #{table_sources.map { |s| s[:field_name] }.join(', ')}"

  table_sources.each do |source|
    export_log "Exporting #{source[:label]}..."
    rows = export_source_rows(net, table, source, export_root, odec_table, odec_folder, table_label)
    export_log "  #{rows.length} file reference(s) exported"
    table_rows.concat(rows)
  end

  return [0, 0, used_basenames, table_rows] if table_rows.empty?

  export_log "Renaming #{table_rows.length} exported file(s) for #{odec_table}..."
  renamed, skipped, used_basenames = rename_exported_files(
    export_root, table_rows, filename_format, used_basenames,
    folder_by_table, folder_by_object_id, odec_folder, created_folders
  )
  [renamed, skipped, used_basenames, table_rows]
end

def prompt_cancel(message)
  WSApplication.message_box("#{message}\nScript cancelled", 'OK', '!', false)
  raise 'abort'
end

net = WSApplication.current_network
prompt_cancel('No network is open. Open a network on the GeoPlan and run the script again.') if net.nil?

present_tables = net.tables.sort_by { |t| table_sort_key(t) }
tables_with_selection = present_tables.select { |table| selection_count(net, table.name) > 0 }
prompt_cancel('No selected objects were found on the open network.') if tables_with_selection.empty?

selected_tables = prompt_selected_tables(net, tables_with_selection)
prompt_cancel('Parameters dialog closed (table selection).') if selected_tables.nil?
prompt_cancel('No object tables were selected.') if selected_tables.empty?

export_sources = discover_export_sources_for_tables(selected_tables)
if export_sources.empty?
  prompt_cancel('No attachment or image fields were found on the selected tables.')
end

source_prompt = [
  ['Select attachment / image sources to export.', 'Readonly', '']
]
export_sources.each do |source|
  source_prompt << [source[:label], 'Boolean', true]
end

source_val = WSApplication.prompt('Export Attachments - Select Sources', source_prompt, false)
prompt_cancel('Parameters dialog closed (source selection).') if source_val.nil?

selected_sources = []
export_sources.each_with_index do |source, idx|
  selected_sources << source if prompt_true?(source_val[idx + 1])
end
prompt_cancel('No attachment sources were selected.') if selected_sources.empty?

options_val = WSApplication.prompt(
  'Export Attachments - Export and Rename Options',
  [
    ['Export folder', 'String', nil, nil, 'FOLDER', 'Export folder'],
    ['Filename format', 'String', '{table}_{id}_{purpose}', nil, 'LIST', FILENAME_FORMAT_PRESETS],
    ['Custom format (when Custom selected)', 'String', '{table}_{id}_{source}'],
    [FILENAME_PLACEHOLDER_HELP, 'Readonly', ''],
    ['Create subfolder for each table', 'Boolean', false],
    ['Create subfolder for each object ID', 'Boolean', false],
    ['Keep index CSV and log after renaming', 'Boolean', true]
  ],
  false
)
prompt_cancel('Parameters dialog closed (export options).') if options_val.nil?

export_folder = options_val[0].to_s.strip
format_preset = options_val[1].to_s.strip
custom_format = options_val[2].to_s.strip
folder_by_table = prompt_true?(options_val[4])
folder_by_object_id = prompt_true?(options_val[5])
keep_index_csv = prompt_true?(options_val[6])
EXPORT_LOG[:enabled] = keep_index_csv
EXPORT_LOG[:lines].clear if keep_index_csv

prompt_cancel('Export folder is required.') if export_folder.empty?
FileUtils.mkdir_p(export_folder) unless File.directory?(export_folder)

filename_format = resolve_filename_format(format_preset, custom_format)
prompt_cancel('Filename format is required.') if filename_format.empty?

export_log ''
export_log "Tables        : #{selected_tables.map { |t| table_prompt_label(t) }.join(', ')}"
export_log "Export folder : #{export_folder}"
export_log "Format        : #{filename_format}"
export_log "Subfolders    : table=#{folder_by_table}, object ID=#{folder_by_object_id}"

used_basenames = {}
created_folders = []
track_created_folder(created_folders, export_folder)
all_rows = []
total_renamed = 0
total_skipped = 0
tables_processed = 0

selected_tables.each do |table|
  table_sources = selected_sources.select { |source| source[:table].name == table.name }
  if table_sources.empty?
    export_log ''
    export_log "SKIPPED: #{table_prompt_label(table)} - no sources selected"
    next
  end

  renamed, skipped, used_basenames, table_rows = process_table_exports(
    net, table, table_sources, export_folder, filename_format, used_basenames,
    folder_by_table, folder_by_object_id, created_folders
  )

  if table_rows.empty?
    export_log "  No files exported for #{table_prompt_label(table)}"
    next
  end

  tables_processed += 1
  total_renamed += renamed
  total_skipped += skipped
  all_rows.concat(table_rows)
end

if all_rows.empty?
  remove_empty_created_folders(created_folders)
  WSApplication.message_box(
    "No attachment files were exported.\nCheck the Ruby console and ExportErrorLog.txt for details.",
    'OK',
    '!',
    false
  )
  raise 'abort'
end

index_csv = File.join(export_folder, INDEX_CSV_FILENAME)
index_log = File.join(export_folder, INDEX_LOG_FILENAME)
write_index_csv(index_csv, all_rows) if keep_index_csv
File.delete(index_csv) if !keep_index_csv && File.exist?(index_csv)

remove_empty_created_folders(created_folders)

summary = "Export and rename complete.\n\n" \
          "Tables  : #{tables_processed}\n" \
          "Renamed : #{total_renamed}\n" \
          "Skipped : #{total_skipped}\n" \
          "Folder  : #{export_folder}"
summary += "\n\nIndex CSV : #{index_csv}" if keep_index_csv
summary += "\nLog file  : #{index_log}" if keep_index_csv

export_log ''
summary.each_line { |line| export_log line.chomp }
write_export_log(index_log) if keep_index_csv
File.delete(index_log) if !keep_index_csv && File.exist?(index_log)

WSApplication.message_box(summary, 'OK', 'information', false)
