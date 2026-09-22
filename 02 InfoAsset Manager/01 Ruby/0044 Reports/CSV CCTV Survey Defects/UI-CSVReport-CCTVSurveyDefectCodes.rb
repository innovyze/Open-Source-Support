# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-CSVReport-CCTVSurveyDefectCodes.rb
# Purpose: Export gravity sewer and rising main CCTV survey defect records to
#          CSV with one row per detail observation. Supports latest survey per
#          pipe, survey and parent pipe attributes, defect grades/codes, and
#          video/report references where held on the survey.
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

require 'csv'
require 'date'
require 'fileutils'

TABLE_NAME = 'cams_cctv_survey'.freeze

SURVEY_FIELDS = %w[
  start_manhole
  finish_manhole
  plr
  when_surveyed
  pipe_type
  use
  size_1
  size_2
  material
  total_length
  surveyed_length
  anticipated_length
  peak_score
  total_score
  mean_score
  hard_wired_structural_grade
  service_peak_score
  service_total_score
  service_mean_score
  hard_wired_service_grade
  pacp_struct_quick_rating
  pacp_oandm_quick_rating
  pacp_overall_quick_rating
  road_name
  place_name
  district
  catchment
  location
  purpose
  job_number
  contract_no
  surveyed_by
  contractor
  method
  standard
  scoring_method
  video_file_in
  video_file_out
  video_recorder
  reviewed_by
  comments
  splitsurvey
  current
  task_status
  task_phase
  completed
  date_completed
].freeze

PIPE_FIELDS = %w[
  asset_id
  us_node_id
  ds_node_id
  link_suffix
  pipe_type
  system_type
  length
  material
  size_1
  year_laid
  strategic
].freeze

DETAIL_FIELDS = %w[
  distance
  code
  characterisation1
  characterisation2
  percentage
  diameter
  clock_at
  clock_to
  remarks
  joint
  cd
  structural_score
  service_score
  video_file
  detail_image
  video_no2
  photo_ref
].freeze

COMPUTED_COLUMNS = %w[
  asset_class
  pipe_asset_key
].freeze

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def prompt_bool(val)
  val == true || val.to_s.strip.downcase == 'true'
end

def prompt_val(prompt_result, index, default = nil)
  return default if prompt_result.nil?
  return prompt_result[index] if prompt_result.is_a?(Array)
  default
end

def win_join(*parts)
  parts.map { |p| p.to_s.strip.gsub('/', '\\').chomp('\\') }
       .reject(&:empty?)
       .join('\\')
end

def network_rows(net, table_name, selection_only)
  if selection_only
    if net.respond_to?(:row_object_collection_selection)
      return net.row_object_collection_selection(table_name)
    end
    if net.respond_to?(:row_objects_selection)
      return net.row_objects_selection(table_name)
    end
    return []
  end
  return net.row_objects(table_name) if net.respond_to?(:row_objects)
  return net.row_object_collection(table_name) if net.respond_to?(:row_object_collection)
  nil
end

def load_survey(net, survey)
  id = row_id(survey)
  return survey if id.empty? || !net.respond_to?(:row_object)

  begin
    full = net.row_object(TABLE_NAME, id)
    return full if full
  rescue StandardError
  end

  survey
end

def survey_details(survey)
  begin
    details = survey.respond_to?(:details) ? survey.details : survey['details']
    return details unless details.nil?
  rescue StandardError
  end
  nil
end

def network_display_name(net)
  begin
    mo = net.model_object if net.respond_to?(:model_object)
    return mo.name.to_s if mo && mo.respond_to?(:name)
  rescue StandardError
  end
  begin
    return net.name.to_s if net.respond_to?(:name)
  rescue StandardError
  end
  '(current network)'
end

def row_id(ro)
  return ro.id.to_s if ro.respond_to?(:id)
  return ro['id'].to_s if ro.respond_to?(:[])
  ''
rescue StandardError
  ''
end

def row_field(ro, field_name)
  return ro.send(field_name) if ro.respond_to?(field_name)
  return ro[field_name] if ro.respond_to?(:[])
  nil
rescue StandardError
  nil
end

def row_has_field?(ro, field_name)
  return true if ro.respond_to?(field_name)
  return ro.field(field_name) if ro.respond_to?(:field)
  ro.respond_to?(:[])
rescue StandardError
  false
end

def detail_field(detail, field_name)
  return detail.send(field_name) if detail.respond_to?(field_name)
  return detail[field_name] if detail.respond_to?(:[])
  nil
rescue StandardError
  nil
end

def non_blank?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def format_csv_value(value)
  return '' if value.nil?

  if value.is_a?(TrueClass)
    return 'true'
  elsif value.is_a?(FalseClass)
    return 'false'
  end

  if value.respond_to?(:strftime)
    return value.strftime('%Y-%m-%d')
  end

  value.to_s
end

def parse_prompt_date(value, default)
  return default if value.nil?

  if value.is_a?(DateTime) || value.is_a?(Time)
    return value.to_date
  end

  if value.is_a?(Date)
    return value
  end

  text = value.to_s.strip
  return default if text.empty?

  Date.parse(text)
rescue StandardError
  default.is_a?(Date) ? default : default.to_date
end

def parse_prompt_integer(value, default = 0)
  return default if value.nil?

  if value.is_a?(Integer)
    return value
  end

  text = value.to_s.strip
  return default if text.empty?

  Integer(text)
rescue StandardError
  default
end

def survey_date_value(ro)
  %w[when_surveyed survey_date].each do |field|
    begin
      val = ro[field]
      return val if val && val != 0
    rescue StandardError
      next
    end
  end
  nil
end

def normalize_to_date(value)
  return nil if value.nil? || value == 0

  return value if value.is_a?(Date)

  if value.is_a?(DateTime) || value.is_a?(Time)
    return Date.new(value.year, value.month, value.day)
  end

  if value.respond_to?(:year) && value.respond_to?(:month) && value.respond_to?(:day)
    year = value.year.to_i
    return Date.new(year, value.month, value.day) if year > 0
  end

  if value.respond_to?(:to_date)
    return value.to_date
  end

  text = value.to_s.strip
  return nil if text.empty?

  Date.parse(text)
rescue StandardError
  nil
end

def date_on_or_after?(value, cutoff_date)
  survey_date = normalize_to_date(value)
  return false if survey_date.nil? || cutoff_date.nil?

  survey_date >= cutoff_date
end

def survey_datetime_sort_key(ro)
  dt = survey_date_value(ro)
  return [0, ''] if dt.nil?

  if dt.respond_to?(:to_time)
    return [1, dt.to_time.to_i]
  end

  d = normalize_to_date(dt)
  return [1, d.jd] if d

  [0, '']
rescue StandardError
  [0, '']
end

def survey_is_newer?(candidate, incumbent)
  c_key = survey_datetime_sort_key(candidate)
  i_key = survey_datetime_sort_key(incumbent)
  return true if c_key[0] > i_key[0]
  return false if c_key[0] < i_key[0]

  if c_key[1] != i_key[1]
    return c_key[1] > i_key[1]
  end

  row_id(candidate) > row_id(incumbent)
end

def integer_field_value(ro, field_name)
  val = row_field(ro, field_name)
  return nil if val.nil? || val.to_s.strip.empty?
  Integer(val)
rescue StandardError
  nil
end

def linked_pipe(survey)
  %w[pipe joined].each do |nav_type|
    begin
      next unless survey.respond_to?(:navigate1)

      pipe = survey.navigate1(nav_type)
      return pipe if pipe
    rescue StandardError
      next
    end
  end
  nil
end

def pipe_asset_key(pipe, survey)
  if pipe
    %w[asset_id id].each do |field|
      val = row_field(pipe, field).to_s.strip
      return "asset:#{val}" unless val.empty?
    end

    us = row_field(pipe, 'us_node_id').to_s.strip
    ds = row_field(pipe, 'ds_node_id').to_s.strip
    suf = row_field(pipe, 'link_suffix').to_s.strip
    return "link:#{us}.#{ds}.#{suf}" if non_blank?(us) && non_blank?(ds)
  end

  plr = row_field(survey, 'plr').to_s.strip
  return "plr:#{plr}" if non_blank?(plr)

  start_mh = row_field(survey, 'start_manhole').to_s.strip
  finish_mh = row_field(survey, 'finish_manhole').to_s.strip
  return "mh:#{start_mh}-#{finish_mh}" if non_blank?(start_mh) && non_blank?(finish_mh)

  sid = row_id(survey)
  return "survey:#{sid}" if non_blank?(sid)

  nil
end

def classify_asset(survey, pipe)
  parts = [
    row_field(survey, 'pipe_type'),
    row_field(survey, 'use'),
    pipe ? row_field(pipe, 'pipe_type') : nil,
    pipe ? row_field(pipe, 'system_type') : nil
  ].compact.map { |v| v.to_s.downcase }

  text = parts.join(' ')
  return 'Rising Main' if text =~ /rising|pressure|force main|forcemain|pumped main|rising main/
  return 'Gravity Sewer' if text =~ /gravity|foul|sanitary|combined|surface water|storm|sewer/

  non_blank?(row_field(survey, 'pipe_type')) ? 'Gravity Sewer / Other' : 'Unclassified'
end

def survey_passes_filters?(ro, cutoff_date, min_survey_structural_grade, exclude_split, require_pipe_type)
  return false unless date_on_or_after?(survey_date_value(ro), cutoff_date)

  if require_pipe_type
    return false unless non_blank?(row_field(ro, 'pipe_type'))
  end

  if exclude_split && row_has_field?(ro, 'splitsurvey')
    split = row_field(ro, 'splitsurvey')
    return false if split == true
  end

  if min_survey_structural_grade > 0
    grade = integer_field_value(ro, 'hard_wired_structural_grade')
    return false if grade.nil? || grade < min_survey_structural_grade
  end

  true
end

def defect_passes_filter?(detail, min_defect_structural_score)
  return true if min_defect_structural_score <= 0

  score = detail_field(detail, 'structural_score')
  return false if score.nil?

  Integer(score) >= min_defect_structural_score
rescue StandardError
  false
end

def build_pipe_columns(pipe, available_pipe_fields)
  cols = {}
  available_pipe_fields.each do |field|
    cols["pipe_#{field}"] = pipe ? format_csv_value(row_field(pipe, field)) : ''
  end
  cols
end

def build_survey_columns(ro, pipe, pipe_key, available_survey_fields)
  cols = { 'survey_id' => row_id(ro) }
  cols['asset_class'] = classify_asset(ro, pipe)
  cols['pipe_asset_key'] = pipe_key.to_s

  available_survey_fields.each do |field|
    cols[field] = format_csv_value(row_field(ro, field))
  end
  cols
end

def build_detail_columns(detail, defect_row, available_detail_fields)
  cols = { 'defect_row' => defect_row.to_s }
  available_detail_fields.each do |field|
    cols[field] = format_csv_value(detail_field(detail, field))
  end
  cols
end

def available_fields(net, table_name, candidates)
  names = net.table(table_name).fields.map { |f| f.name }
  candidates.select { |f| names.include?(f) }
rescue StandardError
  candidates
end

def select_surveys_for_export(surveys, net, date_from, min_survey_structural_grade,
                              exclude_split, require_pipe_type, latest_per_pipe)
  latest_by_pipe = {}
  surveys_checked = 0
  surveys_passed_filters = 0
  surveys_skipped_no_key = 0
  surveys_superseded = 0

  surveys.each do |survey|
    next if survey.nil?

    surveys_checked += 1
    full_survey = load_survey(net, survey)
    next unless survey_passes_filters?(full_survey, date_from, min_survey_structural_grade,
                                       exclude_split, require_pipe_type)

    surveys_passed_filters += 1
    pipe = linked_pipe(full_survey)
    pipe_key = pipe_asset_key(pipe, full_survey)

    if pipe_key.nil? || pipe_key.empty?
      surveys_skipped_no_key += 1
      next
    end

    if latest_per_pipe
      existing = latest_by_pipe[pipe_key]
      if existing.nil?
        latest_by_pipe[pipe_key] = [full_survey, pipe, pipe_key]
      elsif survey_is_newer?(full_survey, existing[0])
        latest_by_pipe[pipe_key] = [full_survey, pipe, pipe_key]
        surveys_superseded += 1
      else
        surveys_superseded += 1
      end
    else
      latest_by_pipe["#{pipe_key}|#{row_id(full_survey)}"] = [full_survey, pipe, pipe_key]
    end
  end

  selected = latest_by_pipe.values
  stats = {
    surveys_checked: surveys_checked,
    surveys_passed_filters: surveys_passed_filters,
    surveys_skipped_no_key: surveys_skipped_no_key,
    surveys_superseded: surveys_superseded,
    pipes_exported: latest_per_pipe ? selected.length : 0,
    surveys_exported: latest_per_pipe ? 0 : selected.length
  }
  [selected, stats]
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

default_output = begin
  WSApplication.local_root.to_s.strip
rescue StandardError
  'C:\\Temp'
end

default_date_from = Date.new(2000, 1, 1)
prompt_date_default = DateTime.new(2000, 1, 1, 0, 0, 0)

prompt = WSApplication.prompt(
  'CCTV Survey Defect Codes CSV Report',
  [
    ['Process SELECTION only?', 'Boolean', false],
    ['Survey date from:', 'DATE', prompt_date_default],
    ['Latest survey per pipe only?', 'Boolean', true],
    ['Require pipe type on survey?', 'Boolean', true],
    ['Minimum survey structural grade (0 = all):', 'Number', 0],
    ['Minimum defect structural score (0 = all):', 'Number', 0],
    ['Exclude split surveys?', 'Boolean', true],
    ['Include surveys with no defect rows?', 'Boolean', false],
    ['Output folder:', 'String', default_output, nil, 'FOLDER', 'Select output folder'],
    ['Output filename:', 'String', 'CCTV_Survey_Defects.csv'],
  ],
  false
)

if prompt.nil?
  WSApplication.message_box("Dialog closed\nScript cancelled.", 'OK', '!', false)
  raise 'abort'
end

selection_only               = prompt_bool(prompt_val(prompt, 0, false))
date_from                    = parse_prompt_date(prompt_val(prompt, 1, default_date_from), default_date_from)
latest_per_pipe              = prompt_bool(prompt_val(prompt, 2, true))
require_pipe_type            = prompt_bool(prompt_val(prompt, 3, true))
min_survey_structural_grade  = parse_prompt_integer(prompt_val(prompt, 4, 0), 0)
min_defect_structural_score  = parse_prompt_integer(prompt_val(prompt, 5, 0), 0)
exclude_split                = prompt_bool(prompt_val(prompt, 6, true))
include_empty_details        = prompt_bool(prompt_val(prompt, 7, false))
output_folder                = prompt_val(prompt, 8, default_output).to_s.strip
output_name                  = prompt_val(prompt, 9, 'CCTV_Survey_Defects.csv').to_s.strip
output_name                  = 'CCTV_Survey_Defects.csv' if output_name.empty?
output_name                 += '.csv' unless output_name.downcase.end_with?('.csv')
output_csv                   = win_join(output_folder, output_name)

if output_folder.empty?
  WSApplication.message_box("Output folder is required.\nScript cancelled.", 'OK', '!', false)
  raise 'abort'
end

available_survey_fields = available_fields(net, TABLE_NAME, SURVEY_FIELDS)
available_pipe_fields = available_fields(net, 'cams_pipe', PIPE_FIELDS)
available_detail_fields = begin
  ti = net.table(TABLE_NAME)
  details_field = ti.fields.find { |f| f.name == 'details' }
  if details_field
    detail_names = details_field.fields.map { |f| f.name }
    DETAIL_FIELDS.select { |f| detail_names.include?(f) }
  else
    DETAIL_FIELDS
  end
rescue StandardError
  DETAIL_FIELDS
end

pipe_columns = available_pipe_fields.map { |f| "pipe_#{f}" }
csv_columns = (
  ['survey_id'] +
  COMPUTED_COLUMNS +
  available_survey_fields +
  pipe_columns +
  ['defect_row'] +
  available_detail_fields
)

puts "Network                     : #{network_display_name(net)}"
puts "Scope                       : #{selection_only ? 'Selection only' : 'All CCTV surveys'}"
puts "Survey date from            : #{date_from.strftime('%Y-%m-%d')}"
puts "Latest survey per pipe      : #{latest_per_pipe}"
puts "Require pipe type           : #{require_pipe_type}"
puts "Min survey structural grade : #{min_survey_structural_grade <= 0 ? 'all' : min_survey_structural_grade}"
puts "Min defect structural score : #{min_defect_structural_score <= 0 ? 'all' : min_defect_structural_score}"
puts "Exclude split surveys       : #{exclude_split}"
puts "Output file                 : #{output_csv}"
puts ''

surveys = network_rows(net, TABLE_NAME, selection_only)
if surveys.nil?
  WSApplication.message_box(
    "Could not read CCTV Survey objects on this IAM build.\nScript cancelled.",
    'OK', '!', false
  )
  raise 'abort'
end

if selection_only && surveys.size == 0
  WSApplication.message_box(
    "Selection-only mode is enabled but no CCTV Survey objects are selected.\n\nSelect surveys first, or run again without selection-only mode.",
    'OK', '!', false
  )
  raise 'abort'
end

selected_surveys, selection_stats = select_surveys_for_export(
  surveys, net, date_from, min_survey_structural_grade,
  exclude_split, require_pipe_type, latest_per_pipe
)

export_rows = []
surveys_without_details = 0
surveys_included = 0
defect_rows_written = 0
rising_main_rows = 0
gravity_rows = 0

selected_surveys.each do |full_survey, pipe, pipe_key|
  survey_cols = build_survey_columns(full_survey, pipe, pipe_key, available_survey_fields)
  survey_cols.merge!(build_pipe_columns(pipe, available_pipe_fields))

  asset_class = survey_cols['asset_class']
  rising_main_rows += 1 if asset_class == 'Rising Main'
  gravity_rows += 1 if asset_class.start_with?('Gravity')

  details = survey_details(full_survey)
  detail_count = details.nil? ? 0 : details.size

  if detail_count == 0
    surveys_without_details += 1
    next unless include_empty_details

    row = survey_cols.dup
    row['defect_row'] = ''
    available_detail_fields.each { |f| row[f] = '' }
    export_rows << row
    surveys_included += 1
    next
  end

  survey_row_count = 0
  defect_row = 0

  details.each do |detail|
    next if detail.nil?
    next unless defect_passes_filter?(detail, min_defect_structural_score)

    defect_row += 1
    row = survey_cols.dup
    row.merge!(build_detail_columns(detail, defect_row, available_detail_fields))
    export_rows << row
    survey_row_count += 1
    defect_rows_written += 1
  end

  surveys_included += 1 if survey_row_count > 0
end

FileUtils.mkdir_p(output_folder)

CSV.open(output_csv, 'w', write_headers: true, headers: csv_columns) do |csv|
  export_rows.each do |row|
    csv << csv_columns.map { |col| row[col].to_s }
  end
end

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

summary = [
  "CCTV Survey defect CSV export complete.",
  '',
  "Network: #{network_display_name(net)}",
  "Surveys checked: #{selection_stats[:surveys_checked]}",
  "Surveys passed filters: #{selection_stats[:surveys_passed_filters]}",
  latest_per_pipe ? "Pipes exported (latest survey): #{selection_stats[:pipes_exported]}" : "Surveys exported: #{selection_stats[:surveys_exported]}",
  "Older surveys superseded: #{selection_stats[:surveys_superseded]}",
  "Surveys skipped (no pipe key): #{selection_stats[:surveys_skipped_no_key]}",
  "Surveys with no defect rows: #{surveys_without_details}",
  "Surveys included in CSV: #{surveys_included}",
  "Defect rows written: #{defect_rows_written}",
  "Gravity sewer survey rows: #{gravity_rows}",
  "Rising main survey rows: #{rising_main_rows}",
  '',
  "Output file:",
  output_csv,
  '',
  "Elapsed: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}",
].join("\n")

puts summary
WSApplication.message_box(summary, 'OK', 'Information', false)
