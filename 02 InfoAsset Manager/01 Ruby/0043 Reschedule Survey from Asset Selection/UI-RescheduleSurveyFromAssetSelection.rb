# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-RescheduleSurveyFromAssetSelection.rb
# Purpose: For each selected asset, copy the most recent **completed** survey
#          (latest date_completed) of a chosen survey type — all top-level fields
#          and blob sub-tables — and create a new planned survey with ID
#          {asset_id}-{date_planned}. Prompts when incomplete related surveys exist.
#          Network field structure is discovered at runtime so user-defined
#          object and survey types are supported when present in the network.
# Run from: Network > Run Ruby Script (with asset object(s) selected)
# ============================================================================

require 'date'

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network

# Known survey tables (standard CAMS). Also discovers user-defined survey tables
# (table name starts with cams__ and either the table name or display name
# contains "survey") and any other *_survey tables present in the open network.
KNOWN_SURVEY_TABLES = %w[
  cams_cctv_survey
  cams_cross_section_survey
  cams_drain_test
  cams_dye_test
  cams_flood_defence_survey
  cams_fog_inspection
  cams_gps_survey
  cams_general_survey
  cams_general_survey_line
  cams_manhole_survey
  cams_mon_survey
  cams_pump_station_survey
  cams_smoke_defect
  cams_smoke_test
].freeze

# Standard field names used to rank completed surveys by recency. Custom Date fields
# whose name or display description contains "inspection date" or "survey date" are
# inserted in the matching positions (see build_recency_fields).
RECENCY_FIELD_CANDIDATES = %w[
  when_surveyed
  survey_date
  date_completed
].freeze

DATE_FIELD_TYPE = 'Date'.freeze

# Copied to the new survey as blank (field and field_flag when present on the table).
FIELDS_TO_CLEAR_ON_NEW = %w[
  date_started
  completed
  date_completed
  closed
  date_closed
  actual_duration
  actual_cost
  estimated_completion_date
  task_status
  task_phase
].freeze

# Main survey fields populated from the source survey actual values (not copied directly).
MAIN_ESTIMATED_FROM_ACTUAL = {
  'actual_duration' => 'estimated_duration',
  'actual_cost'     => 'estimated_cost'
}.freeze

# Never copied — assigned automatically by InfoAsset Manager.
SYSTEM_MANAGED_FIELDS = %w[
  date_opened
  date_opened_flag
  mobile_uid
  uid
].freeze

# Flood-defence survey asset-type values (user_text_40) → cams asset table.
ASSET_TYPE_MAP = {
  'cams_channel'           => 'cams_channel',
  'channel'                => 'cams_channel',
  'cams_defence_structure' => 'cams_defence_structure',
  'defence structure'      => 'cams_defence_structure',
  'defense structure'      => 'cams_defence_structure',
  'cams_general_asset'     => 'cams_general_asset',
  'general asset'          => 'cams_general_asset',
  'cams_manhole'           => 'cams_manhole',
  'node'                   => 'cams_manhole',
  'cams_outlet'            => 'cams_outlet',
  'outlet'                 => 'cams_outlet',
  'cams_screen'            => 'cams_screen',
  'screen'                 => 'cams_screen',
  'cams_storage'           => 'cams_storage',
  'storage'                => 'cams_storage',
  'storage area'           => 'cams_storage',
  'cams_weir'              => 'cams_weir',
  'weir'                   => 'cams_weir'
}.freeze

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def non_blank?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def asset_row_id(asset)
  asset.id.to_s
end

def asset_match_values(asset, asset_table)
  values = [asset_row_id(asset)]
  values << asset.asset_id.to_s if asset_table_info_field?(asset, 'asset_id') && non_blank?(asset.asset_id)
  values << asset.node_id.to_s if asset_table_info_field?(asset, 'node_id') && non_blank?(asset.node_id)
  if asset_table == 'cams_pipe'
    pipe_id = "#{asset.us_node_id}.#{asset.ds_node_id}.#{asset.link_suffix}"
    values << pipe_id
  end
  values.map(&:strip).reject(&:empty?).uniq
end

def asset_table_info_field?(asset, field_name)
  asset.table_info.fields.any? { |f| f.name == field_name }
rescue StandardError
  false
end

def user_defined_survey_table?(table_name, description)
  return false unless table_name.start_with?('cams__')

  table_name.downcase.include?('survey') ||
    description.to_s.downcase.include?('survey')
end

def discover_survey_tables(network_table_names, table_descriptions)
  from_known = KNOWN_SURVEY_TABLES.select { |name| network_table_names.key?(name) }

  from_suffix = network_table_names.keys.select do |name|
    name.end_with?('_survey') && !from_known.include?(name)
  end

  from_user_defined = network_table_names.keys.select do |name|
    user_defined_survey_table?(name, table_descriptions[name])
  end

  (from_known + from_suffix + from_user_defined).uniq.sort
end

def table_prompt_label(table_name, table_descriptions)
  desc = table_descriptions[table_name].to_s.strip
  desc.empty? ? table_name : "#{desc} (#{table_name})"
end

def resolve_table_from_prompt(selection, table_names, table_descriptions)
  selected = selection.to_s
  return selected if table_names.include?(selected)

  table_names.find do |name|
    table_prompt_label(name, table_descriptions) == selected
  end
end

def relationship_name_for_survey(survey_table)
  # User-defined survey tables (cams__*) rarely expose a standard navigate name.
  return nil if survey_table.start_with?('cams__')

  base = survey_table.sub(/^cams_/, '').sub(/_survey$/, '')
  "#{base}_surveys"
end

def recency_fields_for_table(survey_field_defs)
  build_recency_fields(survey_field_defs)
end

def normalised_field_label(text)
  text.to_s.downcase.gsub(/[_\-\s]+/, ' ').strip
end

def date_rank_field?(field)
  field.data_type == DATE_FIELD_TYPE
end

def field_matches_recency_label?(field, keyword)
  pattern = normalised_field_label(keyword)
  [
    normalised_field_label(field.name),
    normalised_field_label(field.description)
  ].any? { |label| label.include?(pattern) }
end

def append_recency_field(fields, name)
  fields << name unless fields.include?(name)
end

def custom_date_fields_matching(survey_field_defs, excluded, keyword)
  survey_field_defs.select do |f|
    date_rank_field?(f) &&
      !excluded.include?(f.name) &&
      field_matches_recency_label?(f, keyword)
  end.map(&:name)
end

def build_recency_fields(survey_field_defs)
  by_name = {}
  survey_field_defs.each { |f| by_name[f.name] = f }
  fields  = []

  append_recency_field(fields, 'when_surveyed') if by_name.key?('when_surveyed')

  custom_date_fields_matching(survey_field_defs, fields, 'inspection date').each do |name|
    append_recency_field(fields, name)
  end

  append_recency_field(fields, 'survey_date') if by_name.key?('survey_date')

  custom_date_fields_matching(survey_field_defs, fields, 'survey date').each do |name|
    append_recency_field(fields, name)
  end

  append_recency_field(fields, 'date_completed') if by_name.key?('date_completed')

  fields
end

def recency_fields_display(survey_field_defs, recency_fields)
  by_name = {}
  survey_field_defs.each { |f| by_name[f.name] = f }

  recency_fields.map do |name|
    field = by_name[name]
    next name unless field

    desc = field.description.to_s.strip
    if desc.empty? || RECENCY_FIELD_CANDIDATES.include?(name)
      name
    else
      "#{desc} (#{name})"
    end
  end.join(' -> ')
end

def recency_field_value(value)
  return nil if value.nil?
  return nil if value.to_s.strip.empty?

  value
end

def compare_field_values(left_val, right_val)
  left_val  = recency_field_value(left_val)
  right_val = recency_field_value(right_val)

  return 0  if left_val.nil? && right_val.nil?
  return -1 if left_val.nil?
  return 1  if right_val.nil?

  left_val <=> right_val
end

def compare_surveys_by_recency(left, right, recency_fields)
  recency_fields.each do |field_name|
    left_val  = recency_field_value(left[field_name])
    right_val = recency_field_value(right[field_name])
    next if left_val.nil? && right_val.nil?

    cmp = compare_field_values(left_val, right_val)
    return cmp if !cmp.nil? && cmp != 0
  end

  # Stable tie-breaker when all ranked date fields are blank or equal.
  left_val  = recency_field_value(left['date_completed'])
  right_val = recency_field_value(right['date_completed'])
  cmp = compare_field_values(left_val, right_val)
  return cmp if !cmp.nil? && cmp != 0

  left.id.to_s <=> right.id.to_s
end

def survey_is_completed?(survey, survey_field_map)
  return false unless survey_field_map.key?('date_completed')

  !survey.date_completed.nil?
end

def survey_is_incomplete?(survey, survey_field_map)
  !survey_is_completed?(survey, survey_field_map)
end

def pick_latest_completed_survey(surveys, survey_field_map, recency_fields)
  completed = surveys.select { |s| survey_is_completed?(s, survey_field_map) }
  return nil if completed.empty?
  return completed.first if recency_fields.empty?

  completed.max { |a, b| compare_surveys_by_recency(a, b, recency_fields) }
end

def survey_recency_label(survey, recency_fields, survey_field_defs)
  by_name = {}
  survey_field_defs.each { |f| by_name[f.name] = f }

  recency_fields.map do |field_name|
    field = by_name[field_name]
    label = if field && !field.description.to_s.strip.empty? && !RECENCY_FIELD_CANDIDATES.include?(field_name)
              field.description.to_s.strip
            else
              field_name
            end
    "#{label}=#{survey[field_name]}"
  end.join(', ')
end

def format_date_for_id(date_value)
  case date_value
  when DateTime, Time
    date_value.strftime('%Y%m%d')
  when Date
    date_value.strftime('%Y%m%d')
  else
    date_value.to_s.strip.gsub(/[^\d]/, '')
  end
end

def survey_row_exists?(net, survey_table, survey_id)
  !net.row_object(survey_table, survey_id).nil?
end

def next_suffixed_survey_id(net, survey_table, base_id)
  suffix = 1
  loop do
    candidate = "#{base_id}_#{suffix}"
    return candidate unless survey_row_exists?(net, survey_table, candidate)

    suffix += 1
    if suffix > 999
      raise "Could not find a free survey ID for '#{base_id}' (checked _1 to _999)."
    end
  end
end

DUPLICATE_ID_POLICY_LABELS = [
  'Skip all duplicates',
  'Create with suffix (_1, _2, ...) for all duplicates',
  'Ask for each duplicate'
].freeze

DUPLICATE_ID_POLICIES = {
  'Skip all duplicates' => :skip_all,
  'Create with suffix (_1, _2, ...) for all duplicates' => :suffix_all,
  'Ask for each duplicate' => :ask_each
}.freeze

def duplicate_id_policy_description(policy)
  case policy
  when :skip_all then 'skip all duplicates'
  when :suffix_all then 'create suffixed IDs for all duplicates'
  when :ask_each then 'ask for each duplicate'
  else 'use base ID'
  end
end

def prompt_duplicate_id_policy(duplicate_count, create_count, date_planned_id)
  summary = "#{duplicate_count} of #{create_count} planned survey(s) already have the target ID " 
  detail = "{asset_id}-#{date_planned_id}."

  val = WSApplication.prompt(
    'Duplicate Survey IDs',
    [
      [summary, 'Readonly', detail],
      ['How should duplicates be handled?', 'String',
       'Create with suffix (_1, _2, ...) for all duplicates', nil, 'LIST',
       DUPLICATE_ID_POLICY_LABELS]
    ],
    false
  )
  return nil if val.nil?

  DUPLICATE_ID_POLICIES[val[1].to_s]
end

def resolve_new_survey_id_with_policy(net, survey_table, base_id, asset_table, asset_id, duplicate_policy)
  return base_id unless survey_row_exists?(net, survey_table, base_id)

  case duplicate_policy
  when :skip_all
    nil
  when :suffix_all
    next_suffixed_survey_id(net, survey_table, base_id)
  when :ask_each
    confirm = WSApplication.message_box(
      "Survey '#{base_id}' already exists for #{asset_table} '#{asset_id}'.\n\n" \
      "Create another survey using the next available ID (#{base_id}_1, #{base_id}_2, ...)?",
      'YesNo', '?', false
    )
    return nil unless confirm == 'Yes'

    next_suffixed_survey_id(net, survey_table, base_id)
  else
    nil
  end
end

def normalize_prompt_date(date_value)
  case date_value
  when DateTime
    date_value
  when Time
    DateTime.new(date_value.year, date_value.month, date_value.day,
                 date_value.hour, date_value.min, date_value.sec)
  when Date
    DateTime.new(date_value.year, date_value.month, date_value.day)
  else
    DateTime.parse(date_value.to_s)
  end
rescue StandardError
  DateTime.now
end

def copy_scalar_field(source, target, field_name)
  target[field_name] = source[field_name]
rescue StandardError => e
  puts "  WARNING: could not copy scalar field '#{field_name}': #{e.message}"
end

def copy_structure_field(source, target, field_def)
  blob_name   = field_def.name
  src_blob    = source[blob_name]
  tgt_blob    = target[blob_name]
  blob_fields = field_def.fields.map(&:name)

  tgt_blob.length = src_blob.size
  (0...src_blob.size).each do |i|
    blob_fields.each do |bf|
      tgt_blob[i][bf] = src_blob[i][bf]
    end
  end
  tgt_blob.write
rescue StandardError => e
  puts "  WARNING: could not copy blob '#{field_def.name}': #{e.message}"
end

def copy_row_object(source, target, field_defs, exclude_fields)
  field_defs.each do |field|
    next if exclude_fields.include?(field.name)

    if field.data_type == 'WSStructure'
      copy_structure_field(source, target, field)
    else
      copy_scalar_field(source, target, field.name)
    end
  end
end

def blank_value_for_field(field_def)
  case field_def.data_type
  when 'Boolean'
    false
  when 'String'
    ''
  else
    nil
  end
end

def fields_to_clear_on_new(survey_field_map)
  names = []
  FIELDS_TO_CLEAR_ON_NEW.each do |base|
    names << base if survey_field_map.key?(base)
    flag = "#{base}_flag"
    names << flag if survey_field_map.key?(flag)
  end
  names.uniq
end

def build_exclude_on_copy(survey_field_map)
  excluded = ['id']
  excluded.concat(SYSTEM_MANAGED_FIELDS.select { |name| survey_field_map.key?(name) })
  excluded.concat(fields_to_clear_on_new(survey_field_map))
  MAIN_ESTIMATED_FROM_ACTUAL.each_value do |estimated|
    excluded << estimated if survey_field_map.key?(estimated)
  end
  excluded.uniq
end

def apply_actual_to_estimated_on_main(source, target, survey_field_map)
  MAIN_ESTIMATED_FROM_ACTUAL.each do |actual, estimated|
    next unless survey_field_map.key?(actual) && survey_field_map.key?(estimated)

    begin
      target[estimated] = source[actual]
    rescue StandardError => e
      puts "  WARNING: could not set #{estimated} from #{actual}: #{e.message}"
    end
  end
end

def resource_or_materials_blob?(field_def)
  [field_def.name.to_s, field_def.description.to_s].any? do |label|
    normalised = normalised_field_label(label)
    normalised.include?('resource') || normalised.include?('material')
  end
end

def estimated_blob_field_for(actual_name, blob_field_names)
  [
    actual_name.sub(/^actual_/, 'estimated_'),
    actual_name.sub(/\Aactual/, 'estimated')
  ].uniq.find { |name| blob_field_names.include?(name) && name != actual_name }
end

def transform_resource_materials_blobs(survey, survey_field_defs)
  survey_field_defs.each do |field_def|
    next unless field_def.data_type == 'WSStructure'
    next unless resource_or_materials_blob?(field_def)

    blob             = survey[field_def.name]
    blob_field_defs  = field_def.fields
    blob_field_names = blob_field_defs.map(&:name)
    actual_to_estimated = {}
    actual_field_defs   = []

    blob_field_defs.each do |bf|
      next unless bf.name.downcase.include?('actual')

      actual_field_defs << bf
      estimated = estimated_blob_field_for(bf.name, blob_field_names)
      actual_to_estimated[bf.name] = estimated if estimated
    end

    (0...blob.size).each do |i|
      actual_to_estimated.each do |actual, estimated|
        blob[i][estimated] = blob[i][actual]
      end
      actual_field_defs.each do |bf|
        blob[i][bf.name] = blank_value_for_field(bf)
      end
    end

    begin
      blob.write
    rescue StandardError => e
      puts "  WARNING: could not transform blob '#{field_def.name}': #{e.message}"
    end
  end
end

def apply_cleared_fields_on_new(survey, survey_field_map)
  fields_to_clear_on_new(survey_field_map).each do |field_name|
    field_def = survey_field_map[field_name]
    next unless field_def

    begin
      survey[field_name] = blank_value_for_field(field_def)
    rescue StandardError => e
      puts "  WARNING: could not clear '#{field_name}' on new survey: #{e.message}"
    end
  end
end

def surveys_from_asset_relationship(asset, survey_table)
  rel = relationship_name_for_survey(survey_table)
  return [] if rel.nil?

  found = []

  begin
    if asset.respond_to?(rel)
      linked = asset.send(rel)
      if linked.respond_to?(:each)
        linked.each { |s| found << s unless s.nil? }
      elsif !linked.nil?
        found << linked
      end
    end
  rescue StandardError
    # Relationship not available on this asset type — fall through.
  end

  begin
    nav = asset.navigate(rel)
    if nav.respond_to?(:each)
      nav.each { |s| found << s unless s.nil? }
    end
  rescue StandardError
    # navigate not available — fall through.
  end

  found.uniq { |s| s.id.to_s }
end

def asset_type_matches_table?(survey_type, asset_table, table_descriptions)
  return false unless non_blank?(survey_type)

  normalized = survey_type.to_s.strip
  desc       = table_descriptions[asset_table].to_s.strip

  return true if normalized.casecmp?(asset_table)
  return true if !desc.empty? && normalized.casecmp?(desc)

  ASSET_TYPE_MAP.each do |label, table|
    next unless table == asset_table
    return true if normalized.casecmp?(label)
  end

  false
end

def survey_asset_id_matches?(survey_asset_id, match_values)
  return false unless non_blank?(survey_asset_id)

  match_values.any? { |v| v.casecmp?(survey_asset_id.to_s.strip) }
end

def survey_matches_asset?(survey, asset, asset_table, survey_fields, table_descriptions)
  match_values = asset_match_values(asset, asset_table)

  if survey.table_info.name == 'cams_flood_defence_survey'
    raw_type = survey.user_text_40.to_s.strip
    asset_id = survey.user_text_39.to_s.strip
    mapped   = ASSET_TYPE_MAP[raw_type.downcase]
    return true if mapped == asset_table && match_values.any? { |v| v == asset_id }
  end

  if asset_table == 'cams_pipe' &&
     survey_fields.key?('us_node_id') &&
     survey_fields.key?('ds_node_id') &&
     survey_fields.key?('link_suffix')
    pipe_key = "#{survey.us_node_id}.#{survey.ds_node_id}.#{survey.link_suffix}"
    return true if match_values.any? { |v| v == pipe_key }
  end

  if survey_fields.key?('asset_type') && survey_fields.key?('asset_id')
    return true if asset_type_matches_table?(survey.asset_type, asset_table, table_descriptions) &&
                   survey_asset_id_matches?(survey.asset_id, match_values)
  end

  false
end

def survey_blank_asset_type_with_asset_id?(survey, asset, asset_table, survey_fields)
  return false unless survey_fields.key?('asset_type') && survey_fields.key?('asset_id')
  return false if non_blank?(survey.asset_type)

  survey_asset_id_matches?(survey.asset_id, asset_match_values(asset, asset_table))
end

# ---------------------------------------------------------------------------
# Discover selected asset types
# ---------------------------------------------------------------------------

network_table_names = {}
table_descriptions  = {}
net.tables.each do |t|
  network_table_names[t.name] = true
  table_descriptions[t.name]  = t.description.to_s
end

selected_asset_types = []
net.tables.each do |t|
  has_selection = false
  net.row_object_collection(t.name).each do |ro|
    if ro.selected?
      has_selection = true
      break
    end
  end
  selected_asset_types << t.name if has_selection
end
selected_asset_types.sort!

if selected_asset_types.empty?
  WSApplication.message_box(
    'No selected objects were found in the network. Select asset object(s) on the GeoPlan and run the script again.',
    'OK', '!', false
  )
  puts 'Script cancelled - no selected objects.'
  exit
end

# ---------------------------------------------------------------------------
# Discover survey tables present in this network
# ---------------------------------------------------------------------------

survey_tables = discover_survey_tables(network_table_names, table_descriptions)

if survey_tables.empty?
  WSApplication.message_box(
    'No survey tables were found in the current network.',
    'OK', '!', false
  )
  puts 'Script cancelled - no survey tables in network.'
  exit
end

user_defined_surveys = survey_tables.select do |name|
  user_defined_survey_table?(name, table_descriptions[name])
end

#unless user_defined_surveys.empty?
#  puts 'User-defined survey table(s) detected:'
#  user_defined_surveys.each do |name|
#    puts "  #{table_descriptions[name]} (#{name})"
#  end
#  puts ''
#end

survey_table_labels = survey_tables.map do |name|
  table_prompt_label(name, table_descriptions)
end.sort_by { |label| label.downcase }

default_asset = selected_asset_types.first
default_asset_label = table_prompt_label(default_asset, table_descriptions)
asset_type_labels = selected_asset_types.map do |name|
  table_prompt_label(name, table_descriptions)
end.sort_by { |label| label.downcase }

# ---------------------------------------------------------------------------
# Prompt: asset type, survey type, date planned
# ---------------------------------------------------------------------------

default_survey_label = table_prompt_label(
  survey_tables.include?('cams_manhole_survey') ? 'cams_manhole_survey' : survey_tables.first,
  table_descriptions
)

val = WSApplication.prompt(
  'Reschedule Survey from Asset Selection',
  [
    ['Asset object type (from current selection)', 'String', default_asset_label, nil, 'LIST', asset_type_labels],
    ['Survey type to copy', 'String', nil, nil, 'LIST', survey_table_labels],
    ['Date planned for new survey(s)', 'DATE', DateTime.now]
  ],
  false
)

if val.nil?
  puts 'Script cancelled by user.'
  exit
end

asset_table  = resolve_table_from_prompt(val[0], selected_asset_types, table_descriptions)
survey_table = resolve_table_from_prompt(val[1], survey_tables, table_descriptions)
date_planned = normalize_prompt_date(val[2])
date_planned_id = format_date_for_id(date_planned)

if survey_table.nil?
  WSApplication.message_box('Could not resolve the selected survey type.', 'OK', '!', false)
  puts 'Script cancelled - unrecognised survey type selection.'
  exit
end

unless network_table_names.key?(asset_table) && network_table_names.key?(survey_table)
  WSApplication.message_box('Selected asset or survey table is not present in this network.', 'OK', '!', false)
  exit
end

# ---------------------------------------------------------------------------
# Discover survey table structure at runtime
# ---------------------------------------------------------------------------

survey_field_defs = net.table(survey_table).fields
survey_field_map  = {}
blob_fields       = []
scalar_fields     = []

survey_field_defs.each do |f|
  survey_field_map[f.name] = f
  if f.data_type == 'WSStructure'
    blob_fields << f.name
  else
    scalar_fields << f.name
  end
end

unless survey_field_map.key?('id')
  WSApplication.message_box(
    "Survey table '#{survey_table}' has no 'id' field - cannot create rescheduled surveys.",
    'OK', '!', false
  )
  exit
end

unless survey_field_map.key?('date_completed')
  WSApplication.message_box(
    "Survey table '#{survey_table}' has no 'date_completed' field.\n\n" \
    "date_completed is required to identify completed surveys - script cancelled.",
    'OK', '!', false
  )
  exit
end

has_completed_field = survey_field_map.key?('completed')
has_date_planned    = survey_field_map.key?('date_planned')
recency_fields      = recency_fields_for_table(survey_field_defs)

puts '=== Network structure (survey table) ==='
puts "Survey table    : #{survey_table}"
#puts "Scalar fields   : #{scalar_fields.size}"
#puts "Blob fields     : #{blob_fields.empty? ? '(none)' : blob_fields.join(', ')}"
puts "Recency ranking : #{recency_fields.empty? ? '(none - first completed survey found)' : recency_fields_display(survey_field_defs, recency_fields)}"
#puts "date_completed  : found (populated value defines a completed survey)"
#puts "completed       : #{has_completed_field ? 'found (ignored when date_completed is set)' : 'NOT found'}"
#puts "date_planned    : #{has_date_planned ? 'found' : 'NOT found (new surveys will still be created)'}"
puts ''

unless has_date_planned
  confirm = WSApplication.message_box(
    "Field 'date_planned' was not found on '#{survey_table}'.\n\nContinue anyway?",
    'YesNo', '?', false
  )
  if confirm != 'Yes'
    puts 'Script cancelled - date_planned field not found.'
    exit
  end
end

# ---------------------------------------------------------------------------
# Collect selected assets
# ---------------------------------------------------------------------------

selected_assets = []
net.row_object_collection(asset_table).each do |ro|
  selected_assets << ro if ro.selected?
end

if selected_assets.empty?
  WSApplication.message_box(
    "No selected objects were found in '#{asset_table}'.",
    'OK', '!', false
  )
  puts 'Script cancelled - no selected assets in chosen table.'
  exit
end

puts "Processing #{selected_assets.size} selected asset(s) in #{asset_table}."
puts "New survey ID format: {asset_id}-#{date_planned_id}"
puts ''

# ---------------------------------------------------------------------------
# Build survey index per asset: all related, latest completed, incomplete
# ---------------------------------------------------------------------------

surveys_by_asset              = Hash.new { |h, k| h[k] = {} }
potential_blank_type_by_asset = Hash.new { |h, k| h[k] = {} }
linked_via_relationship       = 0

selected_assets.each do |asset|
  asset_key = asset_row_id(asset)
  rel_surveys = surveys_from_asset_relationship(asset, survey_table)
  unless rel_surveys.empty?
    linked_via_relationship += 1
    rel_surveys.each { |survey| surveys_by_asset[asset_key][survey.id.to_s] = survey }
  end
end

net.row_objects(survey_table).each do |survey|
  selected_assets.each do |asset|
    asset_key = asset_row_id(asset)

    if survey_matches_asset?(survey, asset, asset_table, survey_field_map, table_descriptions)
      surveys_by_asset[asset_key][survey.id.to_s] = survey
    end

    if survey_blank_asset_type_with_asset_id?(survey, asset, asset_table, survey_field_map)
      potential_blank_type_by_asset[asset_key][survey.id.to_s] = survey
    end
  end
end

latest_completed_by_asset = {}
incomplete_by_asset       = {}

selected_assets.each do |asset|
  asset_key = asset_row_id(asset)
  related   = surveys_by_asset[asset_key].values

  latest_completed_by_asset[asset_key] = pick_latest_completed_survey(related, survey_field_map, recency_fields)
  incomplete_by_asset[asset_key]       = related.select { |s| survey_is_incomplete?(s, survey_field_map) }
end

assets_only_incomplete = selected_assets.select do |asset|
  asset_key = asset_row_id(asset)
  incomplete_by_asset[asset_key].any? &&
    latest_completed_by_asset[asset_key].nil? &&
    surveys_by_asset[asset_key].any?
end

assets_with_incomplete_and_source = selected_assets.select do |asset|
  asset_key = asset_row_id(asset)
  incomplete_by_asset[asset_key].any? && !latest_completed_by_asset[asset_key].nil?
end

create_when_incomplete = true

unless assets_only_incomplete.empty?
  puts 'Asset(s) with related survey(s) but none completed (no date_completed) - will skip (no prompt):'
  assets_only_incomplete.each do |asset|
    asset_key = asset_row_id(asset)
    incomplete_by_asset[asset_key].each do |survey|
      puts "  #{asset_key}: survey '#{survey.id}' - date_completed=(blank)"
    end
  end
  puts ''
end

unless assets_with_incomplete_and_source.empty?
  puts 'Asset(s) with incomplete related survey(s) and a completed survey available to copy:'
  assets_with_incomplete_and_source.each do |asset|
    asset_key = asset_row_id(asset)
    incomplete_by_asset[asset_key].each do |survey|
      date_completed = survey.date_completed.nil? ? '(blank)' : survey.date_completed.to_s
      extra = has_completed_field ? ", completed=#{survey.completed}" : ''
      puts "  #{asset_key}: incomplete survey '#{survey.id}' - date_completed=#{date_completed}#{extra}"
    end
    source = latest_completed_by_asset[asset_key]
    puts "  #{asset_key}: will copy from completed survey '#{source.id}' if you continue"
  end
  puts ''

  confirm = WSApplication.message_box(
    "#{assets_with_incomplete_and_source.size} selected asset(s) have incomplete related survey(s) " \
    "but also have a completed survey that can be copied.\n\n" \
    "Create new planned surveys for these asset(s) anyway?",
    'YesNo', '?', false
  )
  create_when_incomplete = (confirm == 'Yes')

  unless create_when_incomplete
    puts 'User chose not to create new surveys for asset(s) with incomplete related survey(s).'
    puts ''
  end
end

linked_count = surveys_by_asset.count { |_k, v| !v.empty? }
puts "Linked #{linked_count} asset(s) to related survey(s) (#{linked_via_relationship} via asset relationship)."
puts "Latest completed source found for #{latest_completed_by_asset.count { |_k, v| !v.nil? }} asset(s)."

potential_blank_type_count = potential_blank_type_by_asset.values.sum(&:size)
if potential_blank_type_count > 0
  puts ''
  puts "Review suggested - #{potential_blank_type_count} survey(s) have a matching asset_id but blank asset_type " \
       '(not matched on asset_type alone; review older survey data):'
  potential_blank_type_by_asset.each do |asset_key, by_id|
    next if by_id.empty?

    by_id.each_value do |survey|
      if surveys_by_asset[asset_key].key?(survey.id.to_s)
        link_note = 'included only via asset relationship - asset_type is blank'
      else
        link_note = 'not linked - asset_type is blank'
      end
      puts "  #{asset_key}: survey '#{survey.id}' (asset_id=#{survey.asset_id}) - #{link_note}"
    end
  end
end
puts ''

# ---------------------------------------------------------------------------
# Create rescheduled survey copies
# ---------------------------------------------------------------------------

created = 0
skipped_no_source = 0
skipped_exists    = 0
skipped_incomplete = 0
errors            = 0

exclude_on_copy = build_exclude_on_copy(survey_field_map)
clear_on_new      = fields_to_clear_on_new(survey_field_map)

resource_materials_blobs = survey_field_defs.select do |f|
  f.data_type == 'WSStructure' && resource_or_materials_blob?(f)
end.map(&:name)

#unless clear_on_new.empty?
#  puts "Fields cleared on new survey: #{clear_on_new.join(', ')}"
#end
#unless (MAIN_ESTIMATED_FROM_ACTUAL.values & survey_field_map.keys).empty?
#  puts 'Estimated from source actual on new survey: ' \
#       "#{(MAIN_ESTIMATED_FROM_ACTUAL.values & survey_field_map.keys).join(', ')}"
#end
#unless resource_materials_blobs.empty?
#  puts "Resource/materials blob(s) transformed (actual -> estimated, all actual fields cleared): " \
#       "#{resource_materials_blobs.join(', ')}"
#end
#unless (SYSTEM_MANAGED_FIELDS & survey_field_map.keys).empty?
#  puts "System-managed fields (not copied): #{(SYSTEM_MANAGED_FIELDS & survey_field_map.keys).join(', ')}"
#end
#puts ''

assets_to_create = selected_assets.select do |asset|
  asset_id = asset_row_id(asset)
  source = latest_completed_by_asset[asset_id]
  next false unless source

  has_incomplete = incomplete_by_asset[asset_id].any?
  !(has_incomplete && !create_when_incomplete)
end

duplicate_id_assets = assets_to_create.select do |asset|
  base_id = "#{asset_row_id(asset)}-#{date_planned_id}"
  survey_row_exists?(net, survey_table, base_id)
end

duplicate_id_policy = nil
unless duplicate_id_assets.empty?
  duplicate_id_policy = prompt_duplicate_id_policy(
    duplicate_id_assets.size, assets_to_create.size, date_planned_id
  )
  if duplicate_id_policy.nil?
    puts 'Script cancelled - duplicate ID policy not chosen.'
    exit
  end

  puts "Duplicate ID policy: #{duplicate_id_policy_description(duplicate_id_policy)} " \
       "(#{duplicate_id_assets.size} asset(s))"
  puts ''
end

net.transaction_begin

selected_assets.each do |asset|
  asset_id = asset_row_id(asset)
  source   = latest_completed_by_asset[asset_id]
  has_incomplete = incomplete_by_asset[asset_id].any?

  if has_incomplete && source && !create_when_incomplete
    puts "SKIP: #{asset_table} '#{asset_id}' - incomplete related survey(s); user declined to create."
    skipped_incomplete += 1
    next
  end

  unless source
    if surveys_by_asset[asset_id].empty?
      puts "SKIP: #{asset_table} '#{asset_id}' - no matching '#{survey_table}' survey found."
    else
      puts "SKIP: #{asset_table} '#{asset_id}' - related survey(s) found but none completed (date_completed required)."
    end
    skipped_no_source += 1
    next
  end

  base_id = "#{asset_id}-#{date_planned_id}"
  new_id  = if survey_row_exists?(net, survey_table, base_id)
              resolve_new_survey_id_with_policy(
                net, survey_table, base_id, asset_table, asset_id, duplicate_id_policy
              )
            else
              base_id
            end

  if new_id.nil?
    puts "SKIP: #{asset_table} '#{asset_id}' - survey '#{base_id}' already exists."
    skipped_exists += 1
    next
  end

  begin
    new_survey = net.new_row_object(survey_table)
    new_survey.id = new_id

    copy_row_object(source, new_survey, survey_field_defs, exclude_on_copy)

    new_survey.id = new_id
    new_survey.date_planned = date_planned if has_date_planned
    apply_actual_to_estimated_on_main(source, new_survey, survey_field_map)
    transform_resource_materials_blobs(new_survey, survey_field_defs)
    apply_cleared_fields_on_new(new_survey, survey_field_map)

    new_survey.write

    id_note = new_id == base_id ? '' : " [requested ID '#{base_id}' already existed]"
    puts "OK: #{asset_id} - copied completed survey '#{source.id}' (#{survey_recency_label(source, recency_fields, survey_field_defs)}) -> '#{new_id}'#{id_note}"
    created += 1
  rescue StandardError => e
    puts "ERROR: #{asset_id} - #{e.message}"
    errors += 1
  end
end

net.transaction_commit

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

puts ''
puts "Done. #{created} survey(s) created, #{skipped_no_source} asset(s) without a completed source survey, " \
     "#{skipped_incomplete} skipped (incomplete related survey(s), user declined), " \
     "#{skipped_exists} skipped (duplicate ID), #{errors} error(s)."
puts "Time taken: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"
