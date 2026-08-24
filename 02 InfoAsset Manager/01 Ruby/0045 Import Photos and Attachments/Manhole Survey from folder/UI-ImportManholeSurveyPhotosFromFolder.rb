# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-ImportManholeSurveyPhotosFromFolder.rb
# Purpose: Read manhole survey photos from a folder of image files, split into
#          ODIC header-image and attachment CSVs, then import via ODIC.
#
# Filename convention (survey ID or node ID + optional bracket index before extension):
#   SurveyID.jpg        -> location view (location_image)
#   SurveyID (2).jpg    -> location view (location_image)
#   SurveyID (3).jpg    -> internal view (internal_image)
#   SurveyID (4+).jpg   -> attachments blob (purpose = Location Photo)
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .tif .tiff .bmp .webp].freeze
MATCH_MODE_CHOICES = ['Survey ID', 'Node ID'].freeze

HEADER_FIELDS = {
  1 => { image: 'location_image', filename: 'location_image_filename', ref: 'location_image_ref' },
  2 => { image: 'location_image', filename: 'location_image_filename', ref: 'location_image_ref' },
  3 => { image: 'internal_image', filename: 'internal_image_filename', ref: 'internal_image_ref' }
}.freeze

HEADER_CSV_HEADERS = %w[
  id
  internal_image internal_image_filename internal_image_ref
  location_sketch location_sketch_filename location_sketch_ref
  location_image location_image_filename location_image_ref
  plan_sketch plan_sketch_filename plan_sketch_ref
].freeze

ATTACHMENT_CSV_HEADERS = %w[
  id attachments.db_ref attachments.filename attachments.description attachments.purpose
].freeze

ATTACHMENT_PURPOSE = 'Location Photo'.freeze
ODIC_SURVEY_TABLE = 'ManholeSurvey'.freeze
ODIC_ATTACHMENTS_TABLE = 'ManholeSurveyAttachments'.freeze
SURVEY_TABLE = 'cams_manhole_survey'.freeze
ATTACHMENTS_TABLE = 'cams_manhole_survey:attachments'.freeze
FILENAME_INDEX_RE = /\A(.+?)\s*\((\d+)\)\z/.freeze

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

def csv_escape(value)
  text = value.to_s
  return text unless text =~ /[",\r\n]/

  '"' + text.gsub('"', '""') + '"'
end

def odic_field_mapping(target_field, source_field, default_value = '', flag_field = '', units = '')
  %({"#{target_field}","#{source_field}","#{default_value}","#{flag_field}","#{units}"})
end

def build_mapping_line(table_key, field_mappings)
  mappings = field_mappings.map { |target, source| odic_field_mapping(target, source) }
  "#{table_key},{#{mappings.join(',')}}"
end

def build_odic_table_registry(net, mapped_registry_key)
  lines = []
  net.tables.each do |table|
    table_line = "#{table.name},"
    lines << table_line unless table_line == mapped_registry_key

    table.fields.each do |field|
      next unless field.data_type == 'WSStructure'
      blob_line = "#{table.name}:#{field.name},"
      lines << blob_line unless blob_line == mapped_registry_key
    end
  end
  lines.sort
end

def build_odic_import_cfg(mapped_line, registry_lines)
  (['DBI002', mapped_line] + registry_lines).join("\n") + "\n"
end

def build_header_cfg(net)
  mapped_line = build_mapping_line(
    SURVEY_TABLE,
    [
      %w[id id],
      %w[internal_image internal_image],
      %w[internal_image_filename internal_image_filename],
      %w[internal_image_ref internal_image_ref],
      %w[location_sketch location_sketch],
      %w[location_sketch_filename location_sketch_filename],
      %w[location_sketch_ref location_sketch_ref],
      %w[location_image location_image],
      %w[location_image_filename location_image_filename],
      %w[location_image_ref location_image_ref],
      %w[plan_sketch plan_sketch],
      %w[plan_sketch_filename plan_sketch_filename],
      %w[plan_sketch_ref plan_sketch_ref]
    ]
  )
  registry = build_odic_table_registry(net, "#{SURVEY_TABLE},")
  build_odic_import_cfg(mapped_line, registry)
end

def build_attachments_cfg(net)
  mapped_line = build_mapping_line(
    ATTACHMENTS_TABLE,
    [
      %w[id id],
      %w[db_ref attachments.db_ref],
      %w[filename attachments.filename],
      %w[description attachments.description],
      %w[purpose attachments.purpose]
    ]
  )
  registry = build_odic_table_registry(net, "#{ATTACHMENTS_TABLE},")
  build_odic_import_cfg(mapped_line, registry)
end

def win_path(path)
  path.to_s.strip.gsub('/', '\\')
end

def prompt_cancel(message)
  WSApplication.message_box("#{message}\nScript cancelled", 'OK', '!', false)
  abort(message)
end

def prompt_values
  val = WSApplication.prompt(
    'Import Manhole Survey Photos from Folder',
    [
      ['Image folder (source files and ODIC output):', 'String', nil, nil, 'FOLDER', 'Image folder'],
      ['Match filename to:', 'String', 'Survey ID', nil, 'LIST', MATCH_MODE_CHOICES],
      ['Node ID uses the most recent survey when several share the same node.', 'Readonly', ''],
      ['Update existing surveys only', 'Boolean', true],
      ['Run ODIC import after generating CSVs', 'Boolean', true]
    ],
    false
  )
  prompt_cancel('Parameters dialog closed') if val.nil?

  image_folder = win_path(val[0])
  prompt_cancel('Image folder is required') if image_folder.nil? || image_folder.empty?
  prompt_cancel("Image folder not found:\n#{image_folder}") unless File.directory?(image_folder)

  {
    image_folder: image_folder,
    match_by_node_id: val[1] == 'Node ID',
    update_only: val[3] == true,
    run_odic: val[4] == true
  }
end

def image_file?(filename)
  ext = File.extname(filename.to_s).downcase
  IMAGE_EXTENSIONS.include?(ext)
end

def split_name_and_index(filename)
  basename = File.basename(filename.to_s)
  name = File.basename(basename, File.extname(basename))
  if (match = name.match(FILENAME_INDEX_RE))
    [match[1].strip, match[2].to_i]
  else
    [name.strip, 1]
  end
end

def read_photo_files(image_folder)
  rows = []

  Dir.entries(image_folder).each do |entry|
    next if entry == '.' || entry == '..'
    next if entry.start_with?('ODIC_')

    path = File.join(image_folder, entry)
    next unless File.file?(path)
    next unless image_file?(entry)

    file_key, slot_index = split_name_and_index(entry)
    next if file_key.empty?

    rows << {
      file_key: file_key,
      filename: entry,
      description: '',
      slot_index: slot_index
    }
  end

  raise 'No image files found in folder' if rows.empty?
  rows.sort_by { |r| [r[:file_key].to_s.upcase, r[:slot_index], r[:filename].to_s.downcase] }
end

def survey_field_value(survey, field_name)
  return survey[field_name] if survey.respond_to?(:[])
  return survey.send(field_name) if survey.respond_to?(field_name)
rescue StandardError
  nil
end

def survey_recency_sort_key(survey)
  %w[when_surveyed survey_date date_completed].each do |field_name|
    value = survey_field_value(survey, field_name)
    next if value.nil? || value.to_s.strip.empty?

    return value
  end

  survey_field_value(survey, 'id').to_s
end

def build_surveys_by_node_id(net)
  by_node = Hash.new { |hash, key| hash[key] = [] }

  net.row_objects('cams_manhole_survey').each do |survey|
    node_id = survey_field_value(survey, 'node_id').to_s.strip
    next if node_id.empty?

    by_node[node_id] << survey
  end

  by_node
end

def choose_survey_for_node(surveys)
  return [nil, :not_found] if surveys.nil? || surveys.empty?

  if surveys.length == 1
    survey = surveys[0]
    return [survey_field_value(survey, 'id').to_s.strip, :ok]
  end

  chosen = surveys.max_by { |survey| survey_recency_sort_key(survey) }
  [survey_field_value(chosen, 'id').to_s.strip, :ambiguous]
end

def resolve_photo_rows(photo_files, net, match_by_node_id)
  warnings = []
  resolved = []

  if match_by_node_id
    by_node = build_surveys_by_node_id(net)
    photo_files.each do |row|
      survey_id, status = choose_survey_for_node(by_node[row[:file_key]])
      case status
      when :not_found
        warnings << "No survey found for node ID #{row[:file_key]} (#{row[:filename]})"
        next
      when :ambiguous
        warnings << "Multiple surveys for node ID #{row[:file_key]}; using most recent (#{row[:filename]})"
      end
      next if survey_id.nil? || survey_id.empty?

      resolved << row.merge(obj_key: survey_id)
    end
  else
    resolved = photo_files.map do |row|
      row.merge(obj_key: row[:file_key])
    end
  end

  raise 'No files matched to a manhole survey' if resolved.empty?

  [resolved, warnings]
end

def build_header_rows(photo_rows)
  surveys = {}
  duplicates = []

  photo_rows.each do |row|
    next unless HEADER_FIELDS.key?(row[:slot_index])

    id = row[:obj_key]
    surveys[id] ||= HEADER_CSV_HEADERS.each_with_object({}) { |h, memo| memo[h] = '' }
    surveys[id]['id'] = id

    mapping = HEADER_FIELDS[row[:slot_index]]
    image_field = mapping[:image]
    if !surveys[id][image_field].to_s.empty?
      duplicates << "#{id} index (#{row[:slot_index]}) (#{row[:filename]})"
    end

    surveys[id][mapping[:image]] = row[:filename]
    surveys[id][mapping[:filename]] = row[:filename]
    surveys[id][mapping[:ref]] = row[:description]
  end

  [surveys.values.sort_by { |r| r['id'] }, duplicates]
end

def build_attachment_rows(photo_rows)
  attachment_rows = photo_rows
    .select { |row| row[:slot_index] >= 4 }
    .map do |row|
      {
        'id' => row[:obj_key],
        'attachments.db_ref' => row[:filename],
        'attachments.filename' => row[:filename],
        'attachments.description' => row[:description],
        'attachments.purpose' => ATTACHMENT_PURPOSE,
        :slot_index => row[:slot_index]
      }
    end

  attachment_rows
    .group_by { |r| r['id'] }
    .sort_by { |id, _| id.to_s.upcase }
    .flat_map do |_id, rows|
      rows.sort_by { |r| [r[:slot_index], r['attachments.filename'].to_s.downcase] }
        .map { |r| r.reject { |k, _| k == :slot_index } }
    end
end

def write_csv(path, headers, rows)
  File.open(path, 'w:UTF-8') do |f|
    f.puts headers.map { |h| csv_escape(h) }.join(',')
    rows.each do |row|
      f.puts headers.map { |h| csv_escape(row[h]) }.join(',')
    end
  end
end

def write_text(path, content)
  File.open(path, 'w:UTF-8') { |f| f.write(content) }
end

def odic_options(image_folder, error_file, update_only, blob_merge)
  {
    'Error File' => error_file,
    'Image Folder' => image_folder,
    'Import Images' => true,
    'Duplication Behaviour' => 'Merge',
    'Update Only' => update_only,
    'Blob Merge' => blob_merge,
    'Units Behaviour' => 'Native'
  }
end

def run_odic_import(net, cfg_path, csv_path, options, odic_table, label)
  puts "ODIC import: #{label}"
  puts "  Table:  #{odic_table}"
  puts "  Config: #{cfg_path}"
  puts "  Data:   #{csv_path}"
  net.odic_import_ex('CSV', cfg_path, options, odic_table, csv_path)
  puts "  Completed: #{label}"
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

begin
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  settings = prompt_values
  net = WSApplication.current_network
  prompt_cancel('No network is open') if net.nil?

  photo_rows, match_warnings = resolve_photo_rows(
    read_photo_files(settings[:image_folder]),
    net,
    settings[:match_by_node_id]
  )
  header_rows, header_duplicates = build_header_rows(photo_rows)
  attachment_rows = build_attachment_rows(photo_rows)

  output_dir = settings[:image_folder]
  header_csv = File.join(output_dir, 'ODIC_Header_Images.csv')
  attachments_csv = File.join(output_dir, 'ODIC_Attachments.csv')
  header_cfg = File.join(output_dir, 'ODIC_Header_Images.cfg')
  attachments_cfg = File.join(output_dir, 'ODIC_Attachments.cfg')
  header_error_log = File.join(output_dir, 'ODIC_HeaderImport_Errors.txt')
  attachments_error_log = File.join(output_dir, 'ODIC_AttachmentsImport_Errors.txt')

  write_csv(header_csv, HEADER_CSV_HEADERS, header_rows)
  write_csv(attachments_csv, ATTACHMENT_CSV_HEADERS, attachment_rows)
  write_text(header_cfg, build_header_cfg(net))
  write_text(attachments_cfg, build_attachments_cfg(net))

  puts 'Generated ODIC files:'
  puts "  #{header_csv} (#{header_rows.length} surveys)"
  puts "  #{attachments_csv} (#{attachment_rows.length} attachments)"
  puts "  #{header_cfg}"
  puts "  #{attachments_cfg}"

  header_duplicates.each { |msg| puts "WARNING duplicate header slot: #{msg}" }
  match_warnings.first(20).each { |msg| puts "WARNING #{msg}" }
  puts "WARNING #{match_warnings.length} file(s) could not be matched to a survey" if match_warnings.length > 20

  import_summary = []
  if settings[:run_odic]
    if header_rows.any?
      run_odic_import(
        net, header_cfg, header_csv,
        odic_options(settings[:image_folder], header_error_log, settings[:update_only], false),
        ODIC_SURVEY_TABLE,
        'header images'
      )
      import_summary << "#{header_rows.length} header survey row(s)"
    else
      puts 'Skipped header ODIC import (no index 1-3 files)'
    end

    if attachment_rows.any?
      run_odic_import(
        net, attachments_cfg, attachments_csv,
        odic_options(settings[:image_folder], attachments_error_log, settings[:update_only], false),
        ODIC_ATTACHMENTS_TABLE,
        'attachments'
      )
      import_summary << "#{attachment_rows.length} attachment row(s)"
    else
      puts 'Skipped attachment ODIC import (no index 4+ files)'
    end
  else
    import_summary << 'ODIC import skipped (prompt option)'
  end

  elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(1)
  summary = [
    "Source files: #{photo_rows.length}",
    "Match mode: #{settings[:match_by_node_id] ? 'node ID' : 'survey ID'}",
    "Unmatched files: #{match_warnings.length}",
    "Header surveys: #{header_rows.length}",
    "Attachments: #{attachment_rows.length}",
    "Folder: #{output_dir}",
    import_summary.any? ? "Imported: #{import_summary.join('; ')}" : nil,
    "Elapsed: #{elapsed}s",
    File.file?(header_error_log) ? "Header errors:\n#{header_error_log}" : nil,
    File.file?(attachments_error_log) ? "Attachment errors:\n#{attachments_error_log}" : nil
  ].compact.join("\n")

  WSApplication.message_box(summary, 'OK', 'Information', false)
rescue StandardError => e
  puts "#{e.class}: #{e.message}"
  puts e.backtrace
  WSApplication.message_box("Import failed:\n#{e.message}", 'OK', '!', false)
end
