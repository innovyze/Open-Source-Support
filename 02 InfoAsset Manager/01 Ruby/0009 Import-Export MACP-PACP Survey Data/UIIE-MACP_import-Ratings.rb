## Import MACP manhole survey data, then populate MACP ratings from the
## Access database MACP_Ratings table (linked via InspectionID in MH_Inspections).
##
## The MACP_import method is available in InfoAsset Manager (+Exchange) V2022.1 & later.
## Requires Microsoft Access Database Engine (ACE/Jet) for the ratings import step.

require 'win32ole'

# ---------------------------------------------------------------------------
# Access database helpers
# ---------------------------------------------------------------------------
def open_access_connection(mdb_path)
  conn = WIN32OLE.new('ADODB.Connection')
  %w[Microsoft.ACE.OLEDB.12.0 Microsoft.Jet.OLEDB.4.0].each do |provider|
    begin
      conn.Open("Provider=#{provider};Data Source=#{mdb_path};")
      puts "Connected to Access database using #{provider}"
      return conn
    rescue StandardError
      next
    end
  end
  raise 'Could not connect to Access database. Install Microsoft Access Database Engine.'
end

def ado_rows(conn, sql)
  rows = []
  rs = conn.Execute(sql)
  until rs.EOF
    row = {}
    (0...rs.Fields.Count).each do |i|
      f = rs.Fields.Item(i)
      v = f.Value
      row[f.Name] = v.nil? ? nil : v
    end
    rows << row
    rs.MoveNext
  end
  rs.Close
  rows
end

def ado_datetime(date_val, time_val)
  return nil if date_val.nil?
  d = date_val.respond_to?(:year) ? date_val : Time.parse(date_val.to_s)
  h = 0
  m = 0
  s = 0
  unless time_val.nil?
    t = time_val.respond_to?(:hour) ? time_val : Time.parse(time_val.to_s)
    h = t.hour
    m = t.min
    s = t.sec
  end
  Time.new(d.year, d.month, d.day, h, m, s)
end

def datetime_key(dt)
  return nil if dt.nil?
  t = dt.respond_to?(:strftime) ? dt : Time.parse(dt.to_s)
  t.strftime('%Y%m%d%H%M%S')
end

CUSTOM_FIELD_NAMES = {
  1 => 'Custom_Field_One',
  2 => 'Custom_Field_Two',
  3 => 'Custom_Field_Three',
  4 => 'Custom_Field_Four',
  5 => 'Custom_Field_Five',
  6 => 'Custom_Field_Six',
  7 => 'Custom_Field_Seven',
  8 => 'Custom_Field_Eight',
  9 => 'Custom_Field_Nine',
  10 => 'Custom_Field_Ten'
}.freeze

RATINGS_FIELD_MAP = {
  'STMHRating'            => 'macp_struct_rating',
  'OMMHRating'            => 'macp_oandm_rating',
  'OverallMHRating'       => 'macp_overall_rating',
  'STQuickRating'         => 'macp_struct_quick_rating',
  'OMQuickRating'         => 'macp_oandm_quick_rating',
  'MACPQuickRating'       => 'macp_overall_quick_rating',
  'STMHRatingsIndex'      => 'macp_struct_index_rating',
  'OMMHRatingsIndex'      => 'macp_oandm_index_rating',
  'OverallMHRatingsIndex' => 'macp_overall_index_rating'
}.freeze

ID_MODE_CHOICES = %w[
  ManholeNumberDateAndTime
  ManholeNumberAndIndex
  InspectionID
  CustomField
].freeze

def survey_datetime(survey)
  %w[when_surveyed survey_date].each do |field|
    begin
      v = survey[field]
      return v if v && v != 0
    rescue StandardError
      next
    end
  end
  nil
end

def survey_datetime_normalized(survey)
  dt = survey_datetime(survey)
  return nil if dt.nil?
  dt.respond_to?(:year) ? dt : Time.parse(dt.to_s)
rescue StandardError
  nil
end

def datetimes_equal?(a, b)
  return false if a.nil? || b.nil?
  datetime_key(a) == datetime_key(b)
end

def survey_manhole_number(survey)
  begin
    node = survey.navigate1('node')
    if node
      nid = node['node_id'].to_s.strip
      return nid unless nid.empty?
    end
  rescue StandardError
    # survey may not be linked to a node yet
  end

  begin
    v = survey['employers_job_ref'].to_s.strip
    return v unless v.empty?
  rescue StandardError
    # field may not exist
  end

  sid = survey.id.to_s.strip
  if sid =~ /^(.+?)_\d{8}_\d+/
    return $1
  elsif sid =~ /^(.+?)_\d{4}[-\/]\d{2}[-\/]\d{2}/
    return $1
  end

  sid
end

def survey_index_value(survey)
  begin
    idx = survey['survey_index']
    return idx.to_s.strip unless idx.nil? || idx.to_s.strip.empty?
  rescue StandardError
    # field may not exist
  end
  nil
end

def survey_user_text_value(survey, custom_field_num)
  field = "user_text_#{custom_field_num}"
  survey[field].to_s.strip
rescue StandardError
  ''
end

def custom_values_by_inspection(mh_custom_rows, custom_field_num)
  cf_name = CUSTOM_FIELD_NAMES[custom_field_num]
  return {} if cf_name.nil? || mh_custom_rows.nil?

  lookup = {}
  mh_custom_rows.each do |r|
    lookup[r['InspectionID'].to_i] = r[cf_name]
  end
  lookup
end

# Build candidate network survey IDs from an MH_Inspections row, mirroring MACP_import.
def survey_id_candidates_from_mh(mh_row, ids_mode, custom_value)
  mh_num  = mh_row['Manhole_Number'].to_s.strip
  dt      = ado_datetime(mh_row['Inspection_Date'], mh_row['Inspection_Time'])
  insp_id = mh_row['InspectionID'].to_i

  case ids_mode
  when 'InspectionID'
    [insp_id.to_s]

  when 'ManholeNumberDateAndTime'
    return [] if mh_num.empty? || dt.nil?
    [
      "#{mh_num}_#{dt.strftime('%Y%m%d')}_#{dt.strftime('%H%M%S')}",
      "#{mh_num}_#{dt.strftime('%Y%m%d')}_#{dt.strftime('%H%M')}",
      "#{mh_num}_#{dt.strftime('%Y%m%d')}_#{dt.strftime('%H:%M')}",
      "#{mh_num}_#{dt.strftime('%d/%m/%Y')}_#{dt.strftime('%H:%M:%S')}",
      "#{mh_num}#{dt.strftime('%Y%m%d%H%M%S')}",
      "#{mh_num}_#{dt.strftime('%Y-%m-%d %H:%M:%S')}",
      "#{mh_num}_#{dt.strftime('%Y%m%d%H%M%S')}",
      "#{mh_num}_#{dt.strftime('%m/%d/%Y')}_#{dt.strftime('%H:%M:%S')}"
    ]

  when 'ManholeNumberAndIndex'
    return [] if mh_num.empty?
    sheet = mh_row['Sheet_Number']
    keys = [mh_num]
    unless sheet.nil?
      keys << "#{mh_num}#{sheet}"
      keys << "#{mh_num}_#{sheet}"
      keys << "#{mh_num}-#{sheet}"
    end
    keys

  when 'CustomField'
    val = custom_value.to_s.strip
    val.empty? ? [] : [val]

  else
    []
  end
end

# Match a network survey to an MH_Inspections row using header / ID-generation fields.
def survey_matches_mh?(survey, mh_row, ids_mode, custom_value, custom_field_num)
  mh_num = mh_row['Manhole_Number'].to_s.strip
  mh_dt  = ado_datetime(mh_row['Inspection_Date'], mh_row['Inspection_Time'])

  case ids_mode
  when 'InspectionID'
    survey.id.to_s.strip == mh_row['InspectionID'].to_i.to_s

  when 'ManholeNumberDateAndTime'
    return false if mh_num.empty? || mh_dt.nil?
    survey_manhole_number(survey) == mh_num &&
      datetimes_equal?(survey_datetime_normalized(survey), mh_dt)

  when 'ManholeNumberAndIndex'
    return false if mh_num.empty?
    survey_mh = survey_manhole_number(survey)
    return false unless survey_mh == mh_num

    sid = survey.id.to_s.strip
    return true if sid == mh_num

    idx = survey_index_value(survey)
    unless idx.nil? || idx.empty?
      return true if [mh_num + idx, "#{mh_num}_#{idx}", "#{mh_num}-#{idx}"].include?(sid)
    end

    # Same manhole surveyed more than once – use date/time to distinguish.
    !mh_dt.nil? && datetimes_equal?(survey_datetime_normalized(survey), mh_dt)

  when 'CustomField'
    cf_val = custom_value.to_s.strip
    return false if cf_val.empty?
    survey_user_text_value(survey, custom_field_num) == cf_val ||
      survey.id.to_s.strip == cf_val

  else
    false
  end
end

def find_survey_for_mh(mh_row, surveys_by_id, all_surveys, ids_mode, custom_field_num, custom_by_insp)
  insp_id      = mh_row['InspectionID'].to_i
  custom_value = custom_by_insp[insp_id]

  survey_id_candidates_from_mh(mh_row, ids_mode, custom_value).each do |key|
    return surveys_by_id[key] if surveys_by_id[key]
  end

  matches = all_surveys.select do |survey|
    survey_matches_mh?(survey, mh_row, ids_mode, custom_value, custom_field_num)
  end

  return matches[0] if matches.length == 1

  if matches.length > 1
    mh_dt = ado_datetime(mh_row['Inspection_Date'], mh_row['Inspection_Time'])
    if mh_dt
      dt_matches = matches.select { |s| datetimes_equal?(survey_datetime_normalized(s), mh_dt) }
      return dt_matches[0] if dt_matches.length == 1
    end
    puts "  WARNING: #{matches.length} surveys match InspectionID #{insp_id} (#{mh_row['Manhole_Number']}) – using first"
    return matches[0]
  end

  nil
end

def print_import_log(log_path)
  puts '=== MACP Import Log ==='
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
  dbnet = db.model_object_from_type_and_id 'Collection Network', 2
  net = dbnet.open
end

val = WSApplication.prompt(
  'Import MACP + Ratings',
  [
    ['MDB filename:', 'String', nil, nil, 'FILE', true, 'mdb', 'MACP Import File', false],
    ['Generate IDs from:', 'String', 'ManholeNumberDateAndTime', nil, 'LIST', ID_MODE_CHOICES],
    ['Custom field (1-10, if IDs=CustomField):', 'Number', 1, nil, 'RANGE', 1, 10],
    ['If blank use InspectionID?', 'Boolean', false],
    ['Update duplicate surveys?', 'Boolean', false],
    ['Import images?', 'Boolean', true],
    ['Flag for imported fields:', 'String', 'BDGR']
  ],
  false
)

if val.nil?
  WSApplication.message_box("Parameters dialog closed\nScript cancelled", 'OK', '!', false)
  exit
end

import_file       = val[0].to_s
ids_mode          = val[1].to_s.strip
custom_field      = val[2].to_i
if_blank_use_insp = val[3]
update_duplicates = val[4]
import_images     = val[5]
import_flag       = val[6].to_s

if import_file.nil? || import_file.empty?
  WSApplication.message_box("Import file required\nScript cancelled", 'OK', '!', false)
  exit
end

unless File.exist?(import_file)
  WSApplication.message_box("File not found:\n#{import_file}", 'OK', '!', false)
  exit
end

import_log = File.join(
  File.dirname(import_file),
  "MACPimport_#{File.basename(import_file, '.*')}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log"
)

import_options = {
  'IDs'               => ids_mode,
  'IfBlankUseInspectionID' => if_blank_use_insp,
  'UpdateDuplicates'  => update_duplicates,
  'Images'            => import_images,
  'LogFile'           => import_log,
  'Flag'              => import_flag
}
import_options['CustomField'] = custom_field if ids_mode == 'CustomField'

puts '=== MACP Import ==='
puts "File   : #{import_file}"
puts "IDs    : #{ids_mode}"
puts "Log    : #{import_log}"
puts ''

net.MACP_import(import_file, import_options)
puts 'MACP import complete.'
puts ''
print_import_log(import_log)

# ---------------------------------------------------------------------------
# Import MACP_Ratings from the same Access database
# ---------------------------------------------------------------------------
puts '=== MACP Ratings Import ==='

survey_fields = {}
net.table('cams_manhole_survey').fields.each { |f| survey_fields[f.name] = true }

available_targets = RATINGS_FIELD_MAP.values.select { |f| survey_fields.key?(f) }
missing_targets   = RATINGS_FIELD_MAP.values - available_targets

if available_targets.empty?
  WSApplication.message_box(
    "No MACP rating fields found on cams_manhole_survey.\nRatings import skipped.",
    'OK', '!', false
  )
  exit
end

puts "Rating fields available: #{available_targets.join(', ')}"
unless missing_targets.empty?
  puts "Rating fields not found (skipped): #{missing_targets.join(', ')}"
end
puts ''

conn = open_access_connection(import_file)

mh_rows = ado_rows(conn, 'SELECT InspectionID, Manhole_Number, Inspection_Date, Inspection_Time, Sheet_Number FROM MH_Inspections')
puts "MH_Inspections records: #{mh_rows.length}"

mh_custom_rows = []
if ids_mode == 'CustomField'
  begin
    mh_custom_rows = ado_rows(conn, 'SELECT * FROM MH_Custom_Fields')
    puts "MH_Custom_Fields records: #{mh_custom_rows.length}"
  rescue StandardError => e
    puts "WARNING: Could not read MH_Custom_Fields: #{e.message}"
  end
end

ratings_rows = ado_rows(conn, 'SELECT * FROM MACP_Ratings')
puts "MACP_Ratings records: #{ratings_rows.length}"
conn.Close

ratings_by_insp = {}
ratings_rows.each do |row|
  insp_id = row['InspectionID']
  next if insp_id.nil?
  ratings_by_insp[insp_id.to_i] = row
end

custom_by_insp = ids_mode == 'CustomField' ? custom_values_by_inspection(mh_custom_rows, custom_field) : {}

all_surveys = net.row_objects('cams_manhole_survey').to_a
surveys_by_id = {}
all_surveys.each { |s| surveys_by_id[s.id.to_s.strip] = s }

puts "Network manhole surveys: #{all_surveys.length}"
puts "MACP_Ratings to import  : #{ratings_by_insp.length}"
puts ''

count_written   = 0
count_no_survey = 0
count_no_rating = 0

net.transaction_begin

mh_rows.each do |mh_row|
  insp_id = mh_row['InspectionID'].to_i
  mh_num  = mh_row['Manhole_Number'].to_s.strip

  rating_row = ratings_by_insp[insp_id]
  if rating_row.nil?
    puts "  No MACP_Ratings row for InspectionID #{insp_id} (#{mh_num})"
    count_no_rating += 1
    next
  end

  survey = find_survey_for_mh(mh_row, surveys_by_id, all_surveys, ids_mode, custom_field, custom_by_insp)
  if survey.nil?
    puts "  No network survey for InspectionID #{insp_id} (#{mh_num})"
    count_no_survey += 1
    next
  end

  RATINGS_FIELD_MAP.each do |access_field, iam_field|
    next unless available_targets.include?(iam_field)
    survey[iam_field] = rating_row[access_field]
  end

  survey.write
  count_written += 1
  puts "  Updated: #{survey.id}  <-  InspectionID #{insp_id} (#{mh_num})"
end

net.transaction_commit

puts ''
puts '=== Summary ==='
puts "  Ratings rows updated         : #{count_written}"
puts "  No matching network survey   : #{count_no_survey}"
puts "  MH rows with no ratings data : #{count_no_rating}"
puts ''
puts 'Script completed.'
