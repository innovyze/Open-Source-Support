## Import PACP/LACP CCTV survey data from CSV files in PACP7 exchange table format.
## CSV filenames must match the Access table names (for example PACP_Inspections.csv).
## Only PACP_Inspections/PACP_Conditions (or LACP equivalents) are required; media and
## custom-field CSVs are optional and loaded when present.
## A temporary Access MDB is built by copying a PACP7 template MDB and loading CSV data
## into the data tables, then pacp_import_cctv_surveys is run. The template is taken from
## the optional prompt, an .mdb in the CSV folder, or PACP_LACPv702.mdb in Program Files.
##
## Requires InfoAsset Manager 2023.0+ and Microsoft Access Database Engine (ACE/Jet).

require 'csv'
require 'fileutils'
require 'win32ole'

PACP_REQUIRED_TABLES = %w[
  PACP_Inspections
  PACP_Conditions
].freeze

PACP_OPTIONAL_TABLES = %w[
  PACP_Media_Inspections
  PACP_Media_Conditions
  PACP_Custom_Fields
  PACP_Ratings
].freeze

LACP_REQUIRED_TABLES = %w[
  LACP_Inspections
  LACP_Conditions
].freeze

LACP_OPTIONAL_TABLES = %w[
  LACP_Media_Inspections
  LACP_Media_Conditions
  LACP_Custom_Fields
].freeze

# Child tables must be cleared before parent tables because of Access relationships.
PACP_DATA_TABLE_DELETE_ORDER = %w[
  PACP_Ratings
  PACP_Media_Conditions
  PACP_Media_Inspections
  PACP_Custom_Fields
  PACP_Conditions
  PACP_Inspections
].freeze

LACP_DATA_TABLE_DELETE_ORDER = %w[
  LACP_Media_Conditions
  LACP_Media_Inspections
  LACP_Custom_Fields
  LACP_Conditions
  LACP_Inspections
].freeze

PACP7_TEMPLATE_FILENAME = 'PACP_LACPv702.mdb'

def program_files_roots
  [
    ENV['ProgramFiles'],
    ENV['ProgramFiles(x86)'],
    'C:/Program Files',
    'C:/Program Files (x86)'
  ].compact.map { |path| File.expand_path(path) }.uniq.select { |path| File.directory?(path) }
end

def find_installed_pacp7_template_mdb
  program_files_roots.each do |root|
    pattern = File.join(root, 'Autodesk', 'InfoAsset Manager *', PACP7_TEMPLATE_FILENAME)
    matches = Dir.glob(pattern).select { |path| File.file?(path) }
    return matches.max if matches.any?
  end

  nil
end

def sort_tables_for_delete(table_names)
  order = PACP_DATA_TABLE_DELETE_ORDER + LACP_DATA_TABLE_DELETE_ORDER
  table_names.sort_by { |name| idx = order.index(name); idx.nil? ? order.length : idx }
end

def sort_tables_for_insert(table_names)
  sort_tables_for_delete(table_names).reverse
end

ID_MODE_CHOICES = [
  '1 - Upstream MH, Direction, Date and Time',
  '2 - Upstream MH, Direction and Index',
  '3 - Inspection ID',
  '4 - Custom field 1',
  '5 - Custom field 2',
  '6 - Custom field 3',
  '7 - Custom field 4',
  '8 - Custom field 5',
  '9 - Custom field 6',
  '10 - Custom field 7',
  '11 - Custom field 8',
  '12 - Custom field 9',
  '13 - Custom field 10'
].freeze

DUPLICATE_MODE_CHOICES = [
  'Do not import duplicates (ignore)',
  'Update existing surveys (update)'
].freeze

# ADO DataTypeEnum values used when writing SQL literals.
ADO_INTEGER_TYPES = [2, 3, 17, 20].freeze
ADO_FLOAT_TYPES = [4, 5, 6].freeze

def sql_path(path)
  File.expand_path(path).tr('/', '\\').gsub("'", "''")
end

def open_ace_connection(data_source, extended_properties = nil)
  conn = WIN32OLE.new('ADODB.Connection')
  providers = %w[Microsoft.ACE.OLEDB.12.0 Microsoft.Jet.OLEDB.4.0]
  providers.each do |provider|
    begin
      conn_string = "Provider=#{provider};Data Source=#{data_source};"
      conn_string += "Extended Properties=\"#{extended_properties}\";" unless extended_properties.nil?
      conn.Open(conn_string)
      puts "Connected using #{provider}"
      return conn
    rescue StandardError
      next
    end
  end
  raise 'Could not open ACE/Jet connection. Install Microsoft Access Database Engine.'
end

def open_access_connection(mdb_path)
  open_ace_connection(sql_path(mdb_path))
end

def csv_stem(path)
  File.basename(path).sub(/\.[^.]+\z/i, '')
end

def normalize_table_token(name)
  name.to_s.strip.gsub(/\s+/, '_')
end

def table_names_match?(file_stem, table_name)
  normalize_table_token(file_stem).casecmp?(normalize_table_token(table_name))
end

def list_csv_files(csv_dir)
  root = File.expand_path(csv_dir)
  patterns = [
    File.join(root, '*.csv'),
    File.join(root, '*.CSV'),
    File.join(root, '**', '*.csv'),
    File.join(root, '**', '*.CSV')
  ]
  patterns.flat_map { |pattern| Dir.glob(pattern) }.uniq.select { |path| File.file?(path) }
end

def find_csv_for_table(csv_dir, table_name)
  list_csv_files(csv_dir).find { |path| table_names_match?(csv_stem(path), table_name) }
end

def csv_file_dir(csv_path)
  File.expand_path(File.dirname(csv_path))
end

def resolve_import_tables(csv_dir, import_pacp, import_lacp)
  required = []
  optional = []

  if import_pacp
    required.concat(PACP_REQUIRED_TABLES)
    optional.concat(PACP_OPTIONAL_TABLES)
  end
  if import_lacp
    required.concat(LACP_REQUIRED_TABLES)
    optional.concat(LACP_OPTIONAL_TABLES)
  end

  missing_required = required.select { |table| find_csv_for_table(csv_dir, table).nil? }
  tables_to_load = required + optional.select { |table| find_csv_for_table(csv_dir, table) }
  skipped_optional = optional.select { |table| find_csv_for_table(csv_dir, table).nil? }

  [tables_to_load, missing_required, skipped_optional]
end

def csv_basename(csv_path)
  File.basename(csv_path)
end

def escape_access_name(name)
  name.to_s.gsub(']', ']]')
end

def blank_value?(value)
  value.nil? || value.to_s.strip.empty?
end

def invalid_inspection_time?(value)
  s = value.to_s.strip
  return true if s.empty?
  return true if s.match?(/\A00\/01\/1900\z/i)
  return true if s.match?(/\/1900\z/i) && !s.match?(/\d{1,2}:\d{2}/)

  false
end

def access_time_literal_from_video_name(video_name)
  return nil if blank_value?(video_name)

  match = video_name.to_s.match(/_(\d{4})\.(MPG|MP4|AVI|WMV|MKV|MOV)/i)
  return nil if match.nil?

  hhmm = match[1]
  "#1899-12-30 #{hhmm[0..1]}:#{hhmm[2..3]}:00#"
end

def build_media_time_lookup(csv_dir)
  csv_path = find_csv_for_table(csv_dir, 'PACP_Media_Inspections')
  return {} if csv_path.nil?

  lookup = {}
  read_csv_rows(csv_path).each do |row|
    inspection_id = row['InspectionID'].to_s.strip
    time_literal = access_time_literal_from_video_name(row['Video_Name'])
    lookup[inspection_id] = time_literal unless inspection_id.empty? || time_literal.nil?
  end
  lookup
end

def find_template_mdb(csv_dir, prompt_path)
  path = prompt_path.to_s.strip
  return File.expand_path(path) if !path.empty? && File.file?(path)

  Dir.glob(File.join(File.expand_path(csv_dir), '*.mdb')).each do |mdb|
    next if File.basename(mdb) =~ /^PACP_import_/i

    return mdb
  end

  find_installed_pacp7_template_mdb
end

def access_date_literal(value)
  s = value.to_s.strip
  return nil if s.empty?

  if s.match?(/\A\d{1,2}:\d{2}(:\d{2})?\z/)
    return "#1899-12-30 #{s}#"
  end

  match = s.match(/\A(\d{1,2})\/(\d{1,2})\/(\d{4})(?:\s+(\d{1,2}:\d{2}(?::\d{2})?))?\z/)
  if match
    day, month, year, time = match[1], match[2], match[3], match[4]
    return time ? "##{month}/#{day}/#{year} #{time}#" : "##{month}/#{day}/#{year}#"
  end

  match = s.match(/\A(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}:\d{2}(?::\d{2})?))?\z/)
  if match
    return match[4] ? "##{match[2]}/#{match[3]}/#{match[1]} #{match[4]}#" : "##{match[2]}/#{match[3]}/#{match[1]}#"
  end

  nil
end

def sql_literal_for_ado(ado_type, value)
  return 'NULL' if blank_value?(value)

  if ADO_INTEGER_TYPES.include?(ado_type)
    value.to_s.strip.to_i.to_s
  elsif ADO_FLOAT_TYPES.include?(ado_type)
    numeric = value.to_s.strip.delete(',')
    numeric.empty? ? '0' : numeric
  elsif ado_type == 7
    literal = access_date_literal(value)
    literal.nil? ? 'NULL' : literal
  elsif ado_type == 11
    %w[true yes y 1 -1].include?(value.to_s.strip.downcase) ? '-1' : '0'
  else
    "'#{value.to_s.gsub("'", "''")}'"
  end
end

def read_csv_rows(csv_path)
  CSV.read(csv_path, headers: true, encoding: 'bom|utf-8')
end

def table_field_info(conn, table_name)
  rs = conn.Execute("SELECT TOP 1 * FROM [#{table_name}]")
  info = {}
  (0...rs.Fields.Count).each do |i|
    field = rs.Fields.Item(i)
    info[field.Name] = { type: field.Type, size: field.DefinedSize }
  end
  rs.Close
  info
end

def import_csv_into_existing_table(conn, csv_path, table_name, media_time_lookup)
  rows = read_csv_rows(csv_path)
  headers = rows.headers
  raise "No header row found in #{csv_path}" if headers.nil? || headers.empty?

  fields = table_field_info(conn, table_name)
  insert_headers = headers.select { |header| fields.key?(header) }
  skipped_headers = headers - insert_headers
  unless skipped_headers.empty?
    puts "    WARNING: CSV columns not in #{table_name}: #{skipped_headers.join(', ')}"
  end

  headers_sql = insert_headers.map { |header| "[#{escape_access_name(header)}]" }.join(', ')
  rows.each_with_index do |row, idx|
    values = insert_headers.map do |header|
      value = row[header]
      if table_name == 'PACP_Inspections' && header == 'Inspection_Time' && invalid_inspection_time?(value)
        inspection_id = row['InspectionID'].to_s.strip
        media_time_lookup[inspection_id] || '#1899-12-30 00:00:00#'
      else
        sql_literal_for_ado(fields[header][:type], value)
      end
    end
    conn.Execute("INSERT INTO [#{table_name}] (#{headers_sql}) VALUES (#{values.join(', ')})")
  rescue StandardError => e
    raise "Failed inserting row #{idx + 2} into #{table_name}: #{e.message}"
  end
end

def build_mdb_from_csvs(csv_dir, mdb_path, table_names, template_mdb)
  imported = []
  missing = []
  media_time_lookup = build_media_time_lookup(csv_dir)

  FileUtils.copy(template_mdb, mdb_path)
  puts "  Copied PACP7 template: #{template_mdb}"

  conn = open_access_connection(mdb_path)
  begin
    sort_tables_for_delete(table_names).each do |table_name|
      next unless find_csv_for_table(csv_dir, table_name)

      conn.Execute("DELETE FROM [#{table_name}]")
    end

    sort_tables_for_insert(table_names).each do |table_name|
      csv_path = find_csv_for_table(csv_dir, table_name)
      if csv_path.nil?
        missing << table_name
        next
      end

      puts "  Importing #{csv_basename(csv_path)} -> #{table_name}"
      conn.Execute("DELETE FROM [#{table_name}]")
      import_csv_into_existing_table(conn, csv_path, table_name, media_time_lookup)
      imported << table_name
    end
  ensure
    close_ole_connection(conn)
  end

  [imported, missing]
end

def validate_pacp_inspections(mdb_path)
  conn = open_access_connection(mdb_path)
  rs = conn.Execute('SELECT TOP 1 * FROM [PACP_Inspections]')
  raise 'PACP_Inspections contains no rows' if rs.EOF

  columns = (0...rs.Fields.Count).map { |i| rs.Fields.Item(i).Name }
  puts "  PACP_Inspections columns: #{columns.join(', ')}"

  %w[InspectionID Inspection_Date Inspection_Time].each do |col|
    unless columns.any? { |name| name.casecmp?(col) }
      raise "PACP_Inspections missing required column: #{col}"
    end
  end

  id_field = rs.Fields('InspectionID')
  date_field = rs.Fields('Inspection_Date')
  time_field = rs.Fields('Inspection_Time')
  id_val = id_field.Value
  date_val = date_field.Value
  time_val = time_field.Value

  puts "  Sample inspection: InspectionID=#{id_val}, Inspection_Date=#{date_val}, Inspection_Time=#{time_val}"
  puts "  Field types: InspectionID=#{id_field.Type}, Inspection_Date=#{date_field.Type}, Inspection_Time=#{time_field.Type}"

  raise 'InspectionID is blank in PACP_Inspections' if blank_value?(id_val)
  raise 'Inspection_Date is blank in PACP_Inspections' if blank_value?(date_val)
  raise 'Inspection_Time is blank in PACP_Inspections' if blank_value?(time_val)
  raise "InspectionID must be numeric (got #{id_val.inspect})" unless id_val.is_a?(Numeric)

  text_type_codes = [202, 130, 203]
  if text_type_codes.include?(id_field.Type)
    raise 'InspectionID was imported as TEXT; PACP import requires a numeric LONG field'
  end

  rs.Close
ensure
  close_ole_connection(conn)
end

def close_ole_connection(conn)
  return if conn.nil?

  begin
    conn.Close
  rescue StandardError
    nil
  end
end

def delete_temp_mdb_with_retry(mdb_path, attempts = 8)
  attempts.times do |attempt|
    begin
      File.delete(mdb_path)
      return true
    rescue Errno::EACCES, Errno::EPERM, SystemCallError
      GC.start if attempt == 2
      sleep(0.5)
    end
  end
  false
end

def ado_scalar(conn, sql)
  rs = conn.Execute(sql)
  value = rs.Fields(0).Value
  rs.Close
  value
rescue StandardError
  nil
end

def mdb_table_row_counts(mdb_path, table_names)
  conn = open_access_connection(mdb_path)
  counts = {}
  table_names.each do |table_name|
    count = ado_scalar(conn, "SELECT COUNT(*) FROM [#{table_name}]")
    counts[table_name] = count.nil? ? 0 : count.to_i
  end
  counts
ensure
  close_ole_connection(conn)
end

def read_log_text(log_path)
  return '' unless File.exist?(log_path)

  begin
    File.read(log_path, encoding: 'UTF-8')
  rescue StandardError
    File.read(log_path)
  end
rescue StandardError
  ''
end

def log_summary(log_path, max_lines = 12)
  text = read_log_text(log_path)
  return '(no import log written)' if text.strip.empty?

  lines = text.each_line.map(&:strip).reject(&:empty?)
  return text.strip if lines.length <= max_lines

  "#{lines.first(max_lines).join("\n")}\n... (#{lines.length - max_lines} more lines in log file)"
end

def parse_id_mode(choice)
  choice.to_s.strip.split('-', 2)[0].to_i
end

def duplicate_mode_value(choice)
  case choice.to_s.strip.downcase
  when '0'
    'ignore'
  when '1'
    'update'
  else
    choice.to_s.downcase.include?('update') ? 'update' : 'ignore'
  end
end

def print_import_log(log_path)
  puts '=== PACP Import Log ==='
  unless File.exist?(log_path)
    puts "(Log file not found: #{log_path})"
    puts ''
    return
  end

  begin
    File.readlines(log_path, encoding: 'UTF-8').each { |line| puts line.chomp }
  rescue StandardError
    File.readlines(log_path).each { |line| puts line.chomp }
  end
  puts ''
  puts "Log saved to: #{log_path}"
  puts ''
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if WSApplication.ui?
  net = WSApplication.current_network
else
  db = WSApplication.open
  dbnet = db.model_object_from_type_and_id 'Collection Network', 1
  net = dbnet.open
end

val = WSApplication.prompt(
  'Import PACP/LACP from CSV',
  [
    ['Folder containing CSV files:', 'String', nil, nil, 'FOLDER', 'Choose CSV folder'],
    ['PACP7 template MDB (optional):', 'String', nil, nil, 'FILE', false, 'mdb', 'PACP7 template MDB', false],
    ['Import PACP pipe surveys?', 'Boolean', true],
    ['Import LACP lateral surveys?', 'Boolean', false],
    ['Import images?', 'Boolean', true],
    ['Mark imported surveys as completed?', 'Boolean', false],
    ['Generate IDs from:', 'String', ID_MODE_CHOICES[0], nil, 'LIST', ID_MODE_CHOICES],
    ['Duplicate survey handling:', 'String', DUPLICATE_MODE_CHOICES[1], nil, 'LIST', DUPLICATE_MODE_CHOICES],
    ['Flag for imported fields:', 'String', 'BDGR'],
    ['Keep temporary MDB file?', 'Boolean', false]
  ],
  false
)

if val.nil?
  WSApplication.message_box("Parameters dialog closed\nScript cancelled", 'OK', '!', false)
  exit
end

csv_dir         = File.expand_path(val[0].to_s.strip)
template_mdb    = val[1].to_s.strip
import_pacp     = val[2]
import_lacp     = val[3]
import_images   = val[4]
mark_completed  = val[5]
id_mode         = parse_id_mode(val[6])
duplicate_mode  = duplicate_mode_value(val[7])
import_flag     = val[8].to_s
keep_temp_mdb   = val[9]

if csv_dir.nil? || csv_dir.empty?
  WSApplication.message_box("CSV folder required\nScript cancelled", 'OK', '!', false)
  exit
end

unless File.directory?(csv_dir)
  WSApplication.message_box("Folder not found:\n#{csv_dir}", 'OK', '!', false)
  exit
end

unless import_pacp || import_lacp
  WSApplication.message_box('Select Import PACP and/or Import LACP.', 'OK', '!', false)
  exit
end

tables_to_load, missing_required, skipped_optional = resolve_import_tables(csv_dir, import_pacp, import_lacp)
found_csv_files = list_csv_files(csv_dir)

unless missing_required.empty?
  message = "Required CSV file(s) not found in:\n#{csv_dir}\n\nMissing: #{missing_required.join(', ')}"
  if found_csv_files.empty?
    message += "\n\nNo CSV files were found in this folder or its subfolders."
  else
    message += "\n\nCSV files found (#{found_csv_files.length}):\n"
    message += found_csv_files.map { |path| File.basename(path) }.join("\n")
  end
  message += "\n\nExpected names such as PACP_Inspections.csv and PACP_Conditions.csv"
  WSApplication.message_box(message, 'OK', '!', false)
  exit
end

template_mdb = find_template_mdb(csv_dir, template_mdb)
if template_mdb.nil?
  WSApplication.message_box(
    "A PACP7 template MDB is required.\n\nBrowse to a PACP7 .mdb, place one in the CSV folder, or install InfoAsset Manager (which includes PACP_LACPv702.mdb in Program Files).",
    'OK',
    '!',
    false
  )
  exit
end

temp_mdb = File.join(
  ENV['TEMP'] || ENV['TMP'] || csv_dir,
  "PACP_import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.mdb"
)
import_log = File.join(
  csv_dir,
  "PACPimport_#{File.basename(csv_dir)}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log"
)

puts '=== Build temporary PACP MDB from CSV ==='
puts "CSV folder : #{csv_dir}"
puts "Template   : #{template_mdb}"
puts "CSV files  : #{found_csv_files.map { |path| File.basename(path) }.join(', ')}"
puts "Temp MDB   : #{temp_mdb}"
puts "Tables     : #{tables_to_load.join(', ')}"
puts ''

begin
  imported_tables, = build_mdb_from_csvs(csv_dir, temp_mdb, tables_to_load, template_mdb)

  puts ''
  puts "Imported tables (#{imported_tables.length}): #{imported_tables.join(', ')}"
  unless skipped_optional.empty?
    puts "Skipped optional tables (#{skipped_optional.length}): #{skipped_optional.join(', ')}"
  end
  puts ''

  unless File.exist?(temp_mdb)
    raise "Temporary MDB was not created: #{temp_mdb}"
  end

  validate_pacp_inspections(temp_mdb) if import_pacp && imported_tables.include?('PACP_Inspections')

  row_counts = mdb_table_row_counts(temp_mdb, imported_tables + ['DB_Version'])
  row_counts.each { |table, count| puts "  #{table}: #{count} row(s)" }

  inspection_tables = imported_tables.select { |t| t.end_with?('_Inspections') }
  inspection_total = inspection_tables.sum { |t| row_counts[t].to_i }
  if inspection_total.zero?
    raise "Temporary MDB contains no inspection rows (#{inspection_tables.join(', ')}). Check the CSV content."
  end

  puts ''
  puts '=== PACP/LACP import into InfoAsset Manager ==='
  puts "Log file: #{import_log}"
  puts "Duplicate handling: #{duplicate_mode}"
  puts ''

  net.transaction_begin
  net.pacp_import_cctv_surveys(
    temp_mdb,
    import_flag,
    import_images,
    id_mode,
    duplicate_mode,
    import_pacp,
    import_lacp,
    import_log,
    mark_completed
  )
  net.transaction_commit

  puts 'Import complete.'
  print_import_log(import_log)

  summary = [
    "Built MDB from #{imported_tables.length} CSV table(s).",
    "Inspection rows in MDB: #{inspection_total}"
  ]
  summary << "Skipped optional CSVs: #{skipped_optional.join(', ')}" unless skipped_optional.empty?
  summary << ''
  summary << 'Import log:'
  summary << log_summary(import_log)
rescue StandardError => e
  begin
    net.transaction_rollback if net
  rescue StandardError
    nil
  end

  log_hint = File.exist?(import_log) ? "\n\nImport log:\n#{log_summary(import_log)}" : ''
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n") if e.backtrace
  WSApplication.message_box("Import failed:\n#{e.message}#{log_hint}", 'OK', '!', false)
  raise
end

unless keep_temp_mdb
  if delete_temp_mdb_with_retry(temp_mdb)
    cleanup_note = 'Temporary MDB deleted.'
  else
    cleanup_note = "Temporary MDB left in place:\n#{temp_mdb}"
    puts "WARNING: Could not delete temporary MDB: #{temp_mdb}"
  end
else
  cleanup_note = "Temporary MDB:\n#{temp_mdb}"
end

WSApplication.message_box("#{summary.join("\n")}\n\n#{cleanup_note}", 'OK', 'Information', false)
