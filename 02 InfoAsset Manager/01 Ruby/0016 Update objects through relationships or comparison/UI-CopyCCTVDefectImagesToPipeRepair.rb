# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-CopyCCTVDefectImagesToPipeRepair.rb
# Purpose: Copy CCTV survey defect images onto pipe repair attachments by
#          matching cctv_survey_id, defect type (via mapping), and start_length
#          to defect distance (within a configurable buffer).
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

require 'csv'
require 'fileutils'
require 'time'

REPAIR_TABLE = 'cams_pipe_repair'.freeze
SURVEY_TABLE = 'cams_cctv_survey'.freeze

CCTV_SURVEY_ID_FIELD = 'cctv_survey_id'.freeze
DEFECT_TYPE_FIELD = 'defect_type'.freeze
START_LENGTH_FIELD = 'start_length'.freeze
ATTACHMENTS_FIELD = 'attachments'.freeze

DETAIL_CODE_FIELD = 'code'.freeze
DETAIL_DISTANCE_FIELD = 'distance'.freeze
DETAIL_IMAGE_FIELD = 'detail_image'.freeze

DEFAULT_DISTANCE_BUFFER_M = 0.5

LOG_HEADERS = %w[
  status
  reason
  pipe_repair_id
  cctv_survey_id
  defect_type
  start_length
  matched_defect_row
  matched_defect_code
  matched_defect_distance
  detail_image
  attachment_db_ref
].freeze

# ---------------------------------------------------------------------------
# Defect type mapping: pipe repair defect_type, then CCTV defect code(s)
# Matching is case-insensitive. Add one line per repair defect type.
# ---------------------------------------------------------------------------
DEFECT_TYPE_MAPPINGS = [
  'BREAK,B,H,CR',
  'JOINT,J,JNT',
  'ROOTS,R,ROOT',
  'CRACK,CR,CK',
  'COL,COL,C'
].freeze

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def non_blank?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def normalise_token(value)
  value.to_s.strip.upcase
end

def row_field(row, field_name)
  return row.send(field_name) if row.respond_to?(field_name)
  return row[field_name] if row.respond_to?(:[])
  nil
rescue StandardError
  nil
end

def row_id(row)
  return row.id.to_s.strip if row.respond_to?(:id)
  return row['id'].to_s.strip if row.respond_to?(:[])
  ''
rescue StandardError
  ''
end

def detail_field(detail, field_name)
  return detail.send(field_name) if detail.respond_to?(field_name)
  return detail[field_name] if detail.respond_to?(:[])
  nil
rescue StandardError
  nil
end

def survey_details(survey)
  return survey.details if survey.respond_to?(:details)
  return survey['details'] if survey.respond_to?(:[])
  nil
rescue StandardError
  nil
end

def table_has_field?(net, table_name, field_name)
  net.table(table_name).fields.any? { |f| f.name == field_name }
rescue StandardError
  false
end

def build_defect_type_map(mapping_lines)
  map = {}

  mapping_lines.each_with_index do |line, idx|
    text = line.to_s.strip
    next if text.empty? || text.start_with?('#')

    parts = text.split(',').map(&:strip).reject(&:empty?)
    if parts.length < 2
      puts "Warning: defect mapping line #{idx + 1} ignored — expected repair_type,cctv_code[,cctv_code...]: #{line}"
      next
    end

    repair_type = normalise_token(parts[0])
    cctv_codes = parts[1..-1].map { |code| normalise_token(code) }.uniq
    map[repair_type] = cctv_codes
  end

  map
end

def parse_positive_float(value, default)
  text = value.to_s.strip
  return default if text.empty?

  Float(text)
rescue StandardError
  default
end

def distance_match?(repair_start, defect_distance, buffer)
  return false if repair_start.nil? || defect_distance.nil?

  repair_val = repair_start.to_f
  defect_val = defect_distance.to_f
  (defect_val - repair_val).abs <= buffer
end

def details_size(details)
  return 0 if details.nil?

  return details.size if details.respond_to?(:size)
  return details.length if details.respond_to?(:length)

  0
rescue StandardError
  0
end

def detail_at(details, index)
  details[index]
rescue StandardError
  nil
end

def find_matching_defect(details, allowed_codes, start_length, buffer)
  best = nil
  best_distance_delta = nil

  return nil if details.nil?

  (0...details_size(details)).each do |index|
    detail = detail_at(details, index)
    next if detail.nil?

    code = normalise_token(detail_field(detail, DETAIL_CODE_FIELD))
    next if code.empty?
    next unless allowed_codes.include?(code)

    distance = detail_field(detail, DETAIL_DISTANCE_FIELD)
    next unless distance_match?(start_length, distance, buffer)

    delta = (distance.to_f - start_length.to_f).abs
    image = detail_field(detail, DETAIL_IMAGE_FIELD).to_s.strip

    if best.nil?
      best = { detail: detail, index: index, code: code, distance: distance, image: image }
      best_distance_delta = delta
      next
    end

    best_has_image = non_blank?(best[:image])
    current_has_image = non_blank?(image)

    if current_has_image && !best_has_image
      best = { detail: detail, index: index, code: code, distance: distance, image: image }
      best_distance_delta = delta
    elsif current_has_image == best_has_image && delta < best_distance_delta
      best = { detail: detail, index: index, code: code, distance: distance, image: image }
      best_distance_delta = delta
    end
  end

  best
end

def existing_attachment_refs(repair)
  refs = []
  blob = row_field(repair, ATTACHMENTS_FIELD)
  return refs if blob.nil?

  blob.each do |attachment|
    next if attachment.nil?

    db_ref = row_field(attachment, 'db_ref').to_s.strip
    refs << db_ref.downcase unless db_ref.empty?
  end
  refs
rescue StandardError
  []
end

def append_attachment(repair, db_ref, description)
  blob = repair.attachments
  index = blob.length
  blob.length = index + 1
  blob[index].purpose = 'Before repair photo'
  blob[index].filename = db_ref
  blob[index].description = description
  blob[index].db_ref = db_ref
  blob.write
  repair.write
end

def repair_rows(net, selection_only)
  if selection_only
    rows = net.row_objects_selection(REPAIR_TABLE)
    if rows.nil? || rows.length == 0
      WSApplication.message_box(
        "No pipe repairs are selected.\n\nSelect one or more pipe repairs on the GeoPlan, or uncheck 'Process selection only'.",
        'OK', '!', false
      )
      raise 'abort'
    end
    return rows
  end

  net.row_objects(REPAIR_TABLE)
end

def index_surveys(net)
  map = {}
  net.row_objects(SURVEY_TABLE).each do |survey|
    id = row_id(survey)
    next if id.empty?

    map[id] = survey
    map[id.downcase] = survey
  end
  map
end

def lookup_survey(surveys_by_id, survey_id)
  key = survey_id.to_s.strip
  return nil if key.empty?

  surveys_by_id[key] || surveys_by_id[key.downcase]
end

def build_log_row(repair_id, survey_id, defect_type, start_length, status, reason,
                  matched_row: '', matched_code: '', matched_distance: '',
                  detail_image: '', attachment_db_ref: '')
  [
    status,
    reason,
    repair_id,
    survey_id,
    defect_type,
    start_length,
    matched_row,
    matched_code,
    matched_distance,
    detail_image,
    attachment_db_ref
  ]
end

def format_log_row(row)
  CSV.generate_line(row.map { |value| value.nil? ? '' : value }).strip
end

def record_log_entry(log_rows, verbose, row)
  log_rows << row
  puts format_log_row(row) if verbose
end

def write_log_csv(log_path, log_rows)
  FileUtils.mkdir_p(File.dirname(log_path))

  CSV.open(log_path, 'w', write_headers: true, force_quotes: false, headers: LOG_HEADERS) do |csv|
    log_rows.each { |row| csv << row }
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box(
    "No open network found.\n\nOpen a Collection Network, then run via Network > Run Ruby Script.",
    'OK', '!', false
  )
  raise 'abort'
end

unless table_has_field?(net, REPAIR_TABLE, ATTACHMENTS_FIELD)
  WSApplication.message_box(
    "Table #{REPAIR_TABLE} does not have an attachments field on this network.",
    'OK', '!', false
  )
  raise 'abort'
end

defect_type_map = build_defect_type_map(DEFECT_TYPE_MAPPINGS)
if defect_type_map.empty?
  WSApplication.message_box(
    "No valid entries found in DEFECT_TYPE_MAPPINGS.\n\nAdd repair_type,cctv_code lines to the script and run again.",
    'OK', '!', false
  )
  raise 'abort'
end

val = WSApplication.prompt(
  'Copy CCTV defect images to pipe repairs',
  [
    ['Process SELECTION only?', 'Boolean', true],
    ['Distance buffer (m)', 'String', DEFAULT_DISTANCE_BUFFER_M.to_s],
    ['Verbose logging?', 'Boolean', false],
    ['CSV log file folder (optional - leave blank to skip)', 'String', '', nil, 'FOLDER', 'Select log folder']
  ],
  false
)

selection_only = val[0] == true
distance_buffer = parse_positive_float(val[1], DEFAULT_DISTANCE_BUFFER_M)
verbose = val[2] == true
log_folder = val[3].to_s.strip
write_csv_log = non_blank?(log_folder)
log_path = write_csv_log ? File.join(log_folder, "CCTVDefectImagesToPipeRepair_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv") : nil

surveys_by_id = index_surveys(net)

transferred = 0
already_present = 0
failed = 0
log_rows = []

if verbose
  puts format_log_row(LOG_HEADERS)
end

net.transaction_begin

repair_rows(net, selection_only).each do |repair|
  repair_id = row_id(repair)
  survey_id = row_field(repair, CCTV_SURVEY_ID_FIELD).to_s.strip
  defect_type = row_field(repair, DEFECT_TYPE_FIELD).to_s.strip
  start_length = row_field(repair, START_LENGTH_FIELD)

  if survey_id.empty?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(repair_id, survey_id, defect_type, start_length, 'FAILED', 'Blank cctv_survey_id')
    )
    next
  end

  survey = lookup_survey(surveys_by_id, survey_id)
  if survey.nil?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(repair_id, survey_id, defect_type, start_length, 'FAILED', "CCTV survey not found: #{survey_id}")
    )
    next
  end

  if defect_type.empty?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(repair_id, survey_id, defect_type, start_length, 'FAILED', 'Blank defect_type')
    )
    next
  end

  if start_length.nil? || start_length.to_s.strip.empty?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(repair_id, survey_id, defect_type, start_length, 'FAILED', 'Blank start_length')
    )
    next
  end

  allowed_codes = defect_type_map[normalise_token(defect_type)]
  if allowed_codes.nil?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(repair_id, survey_id, defect_type, start_length, 'FAILED', "No defect type mapping for '#{defect_type}'")
    )
    next
  end

  details = survey_details(survey)
  if details.nil? || details_size(details) == 0
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(repair_id, survey_id, defect_type, start_length, 'FAILED', 'CCTV survey has no defect details')
    )
    next
  end

  match = find_matching_defect(details, allowed_codes, start_length, distance_buffer)
  if match.nil?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(
        repair_id, survey_id, defect_type, start_length, 'FAILED',
        "No defect matched codes #{allowed_codes.join('/')} within #{distance_buffer} m of start_length #{start_length}"
      )
    )
    next
  end

  image_ref = match[:image]
  if image_ref.empty?
    failed += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(
        repair_id, survey_id, defect_type, start_length, 'FAILED',
        "Matched defect row #{match[:index] + 1} (#{match[:code]} at #{match[:distance]} m) has no detail_image",
        matched_row: match[:index] + 1,
        matched_code: match[:code],
        matched_distance: match[:distance]
      )
    )
    next
  end

  refs = existing_attachment_refs(repair)
  if refs.include?(image_ref.downcase)
    already_present += 1
    record_log_entry(
      log_rows, verbose,
      build_log_row(
        repair_id, survey_id, defect_type, start_length, 'ALREADY_PRESENT',
        'Image already present on pipe repair attachments',
        matched_row: match[:index] + 1,
        matched_code: match[:code],
        matched_distance: match[:distance],
        detail_image: image_ref,
        attachment_db_ref: image_ref
      )
    )
    next
  end

  description = "CCTV survey #{survey_id} defect #{match[:code]} at #{match[:distance]} m"
  append_attachment(repair, image_ref, description)
  transferred += 1
  record_log_entry(
    log_rows, verbose,
    build_log_row(
      repair_id, survey_id, defect_type, start_length, 'TRANSFERRED',
      'Image copied to pipe repair attachments',
      matched_row: match[:index] + 1,
      matched_code: match[:code],
      matched_distance: match[:distance],
      detail_image: image_ref,
      attachment_db_ref: image_ref
    )
  )
end

net.transaction_commit

write_log_csv(log_path, log_rows) if write_csv_log

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

puts 'CCTV defect image transfer complete'
puts "Scope: #{selection_only ? 'selection' : 'all pipe repairs in network'}"
puts "Distance buffer: #{distance_buffer} m"
puts "Verbose logging: #{verbose}"
puts "Defect type mappings loaded: #{defect_type_map.length}"
puts "Transferred: #{transferred}"
puts "Already present: #{already_present}"
puts "Failed / not transferred: #{failed}"
if write_csv_log
  puts "Log file: #{log_path}"
else
  puts 'Log file: not written (no folder entered)'
end
puts format('Elapsed: %.2f s', elapsed)
