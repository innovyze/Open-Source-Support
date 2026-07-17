# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-ImportManholeSurveyPhotosFromCSV.rb
# Purpose: Read a PHOTO_Node export CSV (OBJ_Key, A, OBS_SortOrder, B), split
#          into ODIC header-image and attachment CSVs in the image folder,
#          then import images into cams_manhole_survey via ODIC.
#
# SortOrder mapping:
#   1 = internal_image
#   2 = location_sketch
#   3 = location_image
#   4 = plan_sketch
#   5+ = attachments (purpose = Other Image)
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

require 'csv'

HEADER_FIELDS = {
  1 => { image: 'internal_image', filename: 'internal_image_filename', ref: 'internal_image_ref' },
  2 => { image: 'location_sketch', filename: 'location_sketch_filename', ref: 'location_sketch_ref' },
  3 => { image: 'location_image', filename: 'location_image_filename', ref: 'location_image_ref' },
  4 => { image: 'plan_sketch', filename: 'plan_sketch_filename', ref: 'plan_sketch_ref' }
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

ATTACHMENT_PURPOSE = 'Other Image'.freeze
ODIC_SURVEY_TABLE = 'ManholeSurvey'.freeze
ODIC_ATTACHMENTS_TABLE = 'ManholeSurveyAttachments'.freeze
SURVEY_TABLE = 'cams_manhole_survey'.freeze
ATTACHMENTS_TABLE = 'cams_manhole_survey:attachments'.freeze

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

def normalise_header(name)
  name.to_s.sub(/\A\uFEFF/, '').strip
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
    'Import Manhole Survey Photos',
    [
      ['Source PHOTO_Node CSV:', 'String', nil, nil, 'FILE', true, 'csv', 'PHOTO_Node CSV', false],
      ['Image folder (ODIC output folder):', 'String', nil, nil, 'FOLDER', 'Image folder'],
      ['Update existing surveys only', 'Boolean', true],
      ['Run ODIC import after generating CSVs', 'Boolean', true]
    ],
    false
  )
  prompt_cancel('Parameters dialog closed') if val.nil?

  source_csv = win_path(val[0])
  image_folder = win_path(val[1])
  prompt_cancel('Source CSV is required') if source_csv.nil? || source_csv.empty?
  prompt_cancel('Image folder is required') if image_folder.nil? || image_folder.empty?
  prompt_cancel("Source CSV not found:\n#{source_csv}") unless File.file?(source_csv)
  prompt_cancel("Image folder not found:\n#{image_folder}") unless File.directory?(image_folder)

  {
    source_csv: source_csv,
    image_folder: image_folder,
    update_only: val[2] == true,
    run_odic: val[3] == true
  }
end

def header_index(headers)
  headers.each_with_index.to_h { |name, idx| [normalise_header(name), idx] }
end

def column_index(index, *candidates)
  candidates.each do |candidate|
    idx = index[normalise_header(candidate)]
    return idx unless idx.nil?
  end
  idx = index.keys.find { |k| k =~ /OBJ_Key$/i }
  return index[idx] unless idx.nil?
  nil
end

def read_photo_rows(source_csv)
  rows = []
  raw_headers = nil
  col = {}

  CSV.foreach(source_csv, headers: true, encoding: 'BOM|UTF-8') do |row|
    raw_headers ||= row.headers
    if col.empty?
      index = header_index(raw_headers)
      col[:obj_key] = column_index(index, 'OBJ_Key', 'OBJ_KEY')
      col[:filename] = column_index(index, 'A')
      col[:description] = column_index(index, 'B')
      col[:sort_order] = column_index(index, 'OBS_SortOrder')
      missing = %i[obj_key filename sort_order].select { |k| col[k].nil? }
      raise "Missing required column(s): #{missing.join(', ')}" unless missing.empty?
    end

    obj_key = row.fields[col[:obj_key]].to_s.strip
    next if obj_key.empty?

    sort_order = row.fields[col[:sort_order]].to_s.strip.to_i
    filename = row.fields[col[:filename]].to_s.strip
    description = col[:description].nil? ? '' : row.fields[col[:description]].to_s.strip

    rows << {
      obj_key: obj_key,
      filename: filename,
      description: description,
      sort_order: sort_order
    }
  end

  raise 'No data rows found in source CSV' if rows.empty?
  rows
rescue CSV::MalformedCSVError => e
  raise "Failed to read CSV: #{e.message}"
end

def build_header_rows(photo_rows)
  surveys = {}
  duplicates = []

  photo_rows.each do |row|
    next if row[:sort_order] < 1 || row[:sort_order] > 4

    id = row[:obj_key]
    surveys[id] ||= HEADER_CSV_HEADERS.each_with_object({}) { |h, memo| memo[h] = '' }
    surveys[id]['id'] = id

    mapping = HEADER_FIELDS[row[:sort_order]]
    image_field = mapping[:image]
    if !surveys[id][image_field].to_s.empty?
      duplicates << "#{id} sort #{row[:sort_order]} (#{row[:filename]})"
    end

    surveys[id][mapping[:image]] = row[:filename]
    surveys[id][mapping[:filename]] = row[:filename]
    surveys[id][mapping[:ref]] = row[:description]
  end

  [surveys.values.sort_by { |r| r['id'] }, duplicates]
end

def build_attachment_rows(photo_rows)
  attachment_rows = photo_rows
    .select { |row| row[:sort_order] >= 5 }
    .map do |row|
      {
        'id' => row[:obj_key],
        'attachments.db_ref' => row[:filename],
        'attachments.filename' => row[:filename],
        'attachments.description' => row[:description],
        'attachments.purpose' => ATTACHMENT_PURPOSE,
        :sort_order => row[:sort_order]
      }
    end

  attachment_rows
    .group_by { |r| r['id'] }
    .sort_by { |id, _| id.to_s.upcase }
    .flat_map do |_id, rows|
      rows.sort_by { |r| [r[:sort_order], r['attachments.filename'].to_s.downcase] }
        .map { |r| r.reject { |k, _| k == :sort_order } }
    end
end

def write_csv(path, headers, rows)
  CSV.open(path, 'w', write_headers: true, headers: headers, encoding: 'UTF-8') do |csv|
    rows.each do |row|
      csv << headers.map { |h| row[h] }
    end
  end
end

def write_text(path, content)
  File.open(path, 'w:UTF-8') { |f| f.write(content) }
end

def missing_images(image_folder, photo_rows)
  photo_rows
    .map { |row| row[:filename] }
    .uniq
    .select { |filename| !filename.empty? && !File.file?(File.join(image_folder, filename)) }
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

  photo_rows = read_photo_rows(settings[:source_csv])
  header_rows, header_duplicates = build_header_rows(photo_rows)
  attachment_rows = build_attachment_rows(photo_rows)
  missing_files = missing_images(settings[:image_folder], photo_rows)

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
  missing_files.first(20).each { |file| puts "WARNING missing image: #{file}" }
  puts "WARNING #{missing_files.length} image file(s) not found in folder" if missing_files.length > 20

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
      puts 'Skipped header ODIC import (no SortOrder 1-4 rows)'
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
      puts 'Skipped attachment ODIC import (no SortOrder 5+ rows)'
    end
  else
    import_summary << 'ODIC import skipped (prompt option)'
  end

  elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(1)
  summary = [
    "Source rows: #{photo_rows.length}",
    "Header surveys: #{header_rows.length}",
    "Attachments: #{attachment_rows.length}",
    "Missing images: #{missing_files.length}",
    "Output folder: #{output_dir}",
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
