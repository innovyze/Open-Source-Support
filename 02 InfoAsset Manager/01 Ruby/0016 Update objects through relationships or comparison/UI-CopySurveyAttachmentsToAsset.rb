# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-CopySurveyAttachmentsToAsset.rb
# Purpose: Copy attachments from selected survey objects to their associated
#          asset object. Duplicate attachments on the asset (same db_ref) are
#          skipped. Attachment files on disk are not copied — only blob metadata
#          referencing the same db_ref is written to the asset.
#
# Run from: Network > Run Ruby Script (with survey object(s) selected)
# ============================================================================

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box(
    "No open network found.\n\nOpen a Collection Network, then run via Network > Run Ruby Script.",
    'OK', '!', false
  )
  raise 'abort'
end

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

ASSET_TYPE_MAP = {
  'cams_ancillary'         => 'cams_ancillary',
  'cams_channel'           => 'cams_channel',
  'channel'                => 'cams_channel',
  'cams_connection_node'   => 'cams_connection_node',
  'cams_connection_pipe'   => 'cams_connection_pipe',
  'cams_defence_structure' => 'cams_defence_structure',
  'defence structure'      => 'cams_defence_structure',
  'defense structure'      => 'cams_defence_structure',
  'cams_general_asset'     => 'cams_general_asset',
  'general asset'          => 'cams_general_asset',
  'cams_manhole'           => 'cams_manhole',
  'node'                   => 'cams_manhole',
  'cams_outlet'            => 'cams_outlet',
  'outlet'                 => 'cams_outlet',
  'cams_pipe'              => 'cams_pipe',
  'pipe'                   => 'cams_pipe',
  'cams_property'          => 'cams_property',
  'property'               => 'cams_property',
  'cams_pump_station'      => 'cams_pump_station',
  'cams_screen'            => 'cams_screen',
  'screen'                 => 'cams_screen',
  'cams_storage'           => 'cams_storage',
  'storage'                => 'cams_storage',
  'storage area'           => 'cams_storage',
  'cams_weir'              => 'cams_weir',
  'weir'                   => 'cams_weir'
}.freeze

ASSET_ID_MATCH_FIELDS = %w[id asset_id node_id property_id].freeze

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def non_blank?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def table_field_names(table_info)
  table_info.fields.map { |f| f.name }
rescue StandardError
  []
end

def table_has_field?(table_info, field_name)
  table_field_names(table_info).include?(field_name)
end

def object_has_attachments_blob?(row_object)
  table_has_field?(row_object.table_info, 'attachments')
rescue StandardError
  row_object.respond_to?(:attachments)
end

def network_rows(net, table_name)
  return net.row_object_collection(table_name) if net.respond_to?(:row_object_collection)
  return net.row_objects(table_name) if net.respond_to?(:row_objects)
  nil
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

def selected_rows(net, table_name)
  if net.respond_to?(:row_object_collection_selection)
    rows = net.row_object_collection_selection(table_name)
    return rows if rows && rows.length > 0
  end

  if net.respond_to?(:row_objects_selection)
    rows = net.row_objects_selection(table_name)
    return rows if rows && !rows.empty?
  end

  if net.respond_to?(:row_object_collection)
    selected = []
    net.row_object_collection(table_name).each do |ro|
      selected << ro if ro && ro.selected?
    end
    return selected unless selected.empty?
  end

  nil
end

def collect_selected_surveys(net, survey_tables)
  pairs = []

  survey_tables.each do |table_name|
    rows = selected_rows(net, table_name)
    next if rows.nil?

    rows.each do |survey|
      next if survey.nil?
      pairs << [table_name, survey]
    end
  end

  pairs
end

def survey_field_set(survey)
  survey.table_info.fields.map { |f| f.name }.to_h { |name| [name, true] }
rescue StandardError
  {}
end

def resolve_asset_table_name(raw_type, network_table_names, table_descriptions)
  return nil unless non_blank?(raw_type)

  normalized = raw_type.to_s.strip
  return normalized if network_table_names.key?(normalized)

  mapped = ASSET_TYPE_MAP[normalized.downcase]
  return mapped if mapped && network_table_names.key?(mapped)

  underscored = "cams_#{normalized.downcase.gsub(/\s+/, '_')}"
  return underscored if network_table_names.key?(underscored)

  table_descriptions.each do |table_name, description|
    next unless network_table_names.key?(table_name)
    return table_name if !description.to_s.strip.empty? && normalized.casecmp?(description.to_s.strip)
  end

  ASSET_TYPE_MAP.each do |label, table_name|
    next unless network_table_names.key?(table_name)
    return table_name if normalized.casecmp?(label)
  end

  nil
end

def row_matches_asset_id?(row_object, asset_id, match_fields)
  match_fields.each do |field_name|
    next unless table_has_field?(row_object.table_info, field_name)

    value = row_object[field_name].to_s.strip
    return true if non_blank?(value) && value.casecmp?(asset_id)
  rescue StandardError
  end

  false
end

def find_asset(net, asset_table, asset_id)
  id = asset_id.to_s.strip
  return nil if id.empty?

  begin
    asset = net.row_object(asset_table, id)
    return asset unless asset.nil?
  rescue StandardError
  end

  begin
    matches = net.row_objects_from_asset_id(asset_table, id)
    return matches.first if matches && !matches.empty?
  rescue StandardError
  end

  rows = network_rows(net, asset_table)
  return nil if rows.nil?

  rows.each do |row_object|
    next if row_object.nil?
    return row_object if row_matches_asset_id?(row_object, id, ASSET_ID_MATCH_FIELDS)
  end

  nil
end

def navigate_asset(survey, navigate_type)
  return nil unless survey.respond_to?(:navigate1)

  asset = survey.navigate1(navigate_type)
  return asset unless asset.nil?
rescue StandardError
end

def asset_from_pipe_link(net, survey, survey_fields)
  return nil unless survey_fields.key?('us_node_id') &&
                    survey_fields.key?('ds_node_id') &&
                    survey_fields.key?('link_suffix')
  return nil unless non_blank?(survey.us_node_id) && non_blank?(survey.ds_node_id)

  pipe_id = "#{survey.us_node_id}.#{survey.ds_node_id}.#{survey.link_suffix}"
  find_asset(net, 'cams_pipe', pipe_id)
end

def asset_from_asset_fields(net, survey, survey_fields, network_table_names, table_descriptions)
  return nil unless survey_fields.key?('asset_type') && survey_fields.key?('asset_id')
  return nil unless non_blank?(survey.asset_type) && non_blank?(survey.asset_id)

  asset_table = resolve_asset_table_name(survey.asset_type, network_table_names, table_descriptions)
  return nil if asset_table.nil?

  find_asset(net, asset_table, survey.asset_id)
end

def asset_from_flood_defence_fields(net, survey, survey_table, network_table_names, table_descriptions)
  return nil unless survey_table == 'cams_flood_defence_survey'

  asset_id = survey.user_text_39.to_s.strip
  raw_type = survey.user_text_40.to_s.strip
  return nil unless non_blank?(asset_id) && non_blank?(raw_type)

  asset_table = resolve_asset_table_name(raw_type, network_table_names, table_descriptions)
  return nil if asset_table.nil?

  find_asset(net, asset_table, asset_id)
end

def asset_from_node_id(net, survey, survey_fields)
  return nil unless survey_fields.key?('node_id') && non_blank?(survey.node_id)

  find_asset(net, 'cams_manhole', survey.node_id) ||
    find_asset(net, 'cams_connection_node', survey.node_id)
end

def acceptable_asset?(asset)
  !asset.nil? && object_has_attachments_blob?(asset)
end

def resolve_asset_for_survey(net, survey, survey_table, network_table_names, table_descriptions)
  survey_fields = survey_field_set(survey)

  candidates = [
    asset_from_asset_fields(net, survey, survey_fields, network_table_names, table_descriptions),
    asset_from_flood_defence_fields(net, survey, survey_table, network_table_names, table_descriptions),
    asset_from_pipe_link(net, survey, survey_fields),
    asset_from_node_id(net, survey, survey_fields),
    navigate_asset(survey, 'property'),
    navigate_asset(survey, 'node'),
    navigate_asset(survey, 'pipe')
  ]

  candidates.compact.find { |asset| acceptable_asset?(asset) }
end

def attachment_field(attachment, name)
  return attachment.send(name).to_s if attachment.respond_to?(name)
  return attachment[name].to_s if attachment.respond_to?(:[])
  ''
rescue StandardError
  ''
end

def existing_db_refs(asset)
  refs = []
  return refs unless object_has_attachments_blob?(asset)

  asset.attachments.each do |attachment|
    next if attachment.nil?
    db_ref = attachment_field(attachment, 'db_ref').strip
    refs << db_ref.downcase unless db_ref.empty?
  end
  refs
end

def effective_db_ref(attachment)
  db_ref = attachment_field(attachment, 'db_ref').strip
  return db_ref if non_blank?(db_ref)

  attachment_field(attachment, 'filename').strip
end

def survey_attachments_to_copy(survey)
  rows = []
  return rows unless object_has_attachments_blob?(survey)

  survey.attachments.each do |attachment|
    next if attachment.nil?
    db_ref = effective_db_ref(attachment)
    next if db_ref.empty?

    purpose = attachment_field(attachment, 'purpose')
    filename = attachment_field(attachment, 'filename')
    description = attachment_field(attachment, 'description')
    filename = db_ref if filename.empty?

    rows << [purpose, filename, description, db_ref]
  end
  rows
end

def copy_attachments_to_asset(asset, attachment_rows, survey_label)
  refs = existing_db_refs(asset)
  added = 0
  skipped = 0

  attachment_rows.each do |purpose, filename, description, db_ref|
    if refs.include?(db_ref.downcase)
      skipped += 1
      puts "#{survey_label} -> #{asset.table_info.name} #{asset.id}: db_ref=#{db_ref} already on asset, skipping."
      next
    end

    blob = asset.attachments
    index = blob.length
    blob.length = index + 1
    blob[index].purpose = purpose
    blob[index].filename = filename
    blob[index].description = description
    blob[index].db_ref = db_ref
    blob.write
    asset.write

    refs << db_ref.downcase
    added += 1
    puts "#{survey_label} -> #{asset.table_info.name} #{asset.id}: added '#{filename}' (db_ref=#{db_ref})"
  end

  [added, skipped]
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

network_table_names = {}
table_descriptions  = {}
net.tables.each do |table|
  network_table_names[table.name] = true
  table_descriptions[table.name]  = table.description.to_s
end

survey_tables = discover_survey_tables(network_table_names, table_descriptions)
selected_surveys = collect_selected_surveys(net, survey_tables)

if selected_surveys.empty?
  WSApplication.message_box(
    "No survey objects are selected.\n\nSelect one or more survey objects on the GeoPlan, then re-run.",
    'OK', '!', false
  )
  raise 'abort'
end

puts "Selected surveys: #{selected_surveys.size}"
puts ''

stats = {
  surveys_processed: 0,
  surveys_skipped_no_attachments: 0,
  surveys_skipped_no_asset: 0,
  surveys_skipped_asset_no_attachments: 0,
  attachments_added: 0,
  attachments_skipped_duplicate: 0
}

net.transaction_begin

selected_surveys.each do |survey_table, survey|
  survey_label = "#{survey_table} '#{survey.id}'"
  attachment_rows = survey_attachments_to_copy(survey)

  if attachment_rows.empty?
    stats[:surveys_skipped_no_attachments] += 1
    puts "#{survey_label}: no attachments with db_ref/filename — skipped."
    next
  end

  asset = resolve_asset_for_survey(
    net, survey, survey_table, network_table_names, table_descriptions
  )

  if asset.nil?
    stats[:surveys_skipped_no_asset] += 1
    asset_type = survey.respond_to?(:asset_type) ? survey.asset_type.to_s.strip : ''
    asset_id = survey.respond_to?(:asset_id) ? survey.asset_id.to_s.strip : ''
    resolved_table = resolve_asset_table_name(asset_type, network_table_names, table_descriptions)
    puts "#{survey_label}: could not resolve associated asset — skipped."
    if non_blank?(asset_type) || non_blank?(asset_id)
      puts "  asset_type=#{asset_type.empty? ? '(blank)' : asset_type}"
      puts "  asset_id=#{asset_id.empty? ? '(blank)' : asset_id}"
      puts "  resolved_table=#{resolved_table || '(unrecognised asset_type)'}"
    end
    next
  end

  unless object_has_attachments_blob?(asset)
    stats[:surveys_skipped_asset_no_attachments] += 1
    puts "#{survey_label}: asset #{asset.table_info.name} '#{asset.id}' has no attachments field — skipped."
    next
  end

  added, skipped = copy_attachments_to_asset(asset, attachment_rows, survey_label)
  stats[:surveys_processed] += 1
  stats[:attachments_added] += added
  stats[:attachments_skipped_duplicate] += skipped
end

net.transaction_commit

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

summary = [
  'Copy survey attachments to asset — complete.',
  '',
  "Surveys selected       : #{selected_surveys.size}",
  "Surveys updated        : #{stats[:surveys_processed]}",
  "Attachments added      : #{stats[:attachments_added]}",
  "Duplicates skipped     : #{stats[:attachments_skipped_duplicate]}",
  "No attachments         : #{stats[:surveys_skipped_no_attachments]}",
  "Asset not found        : #{stats[:surveys_skipped_no_asset]}",
  "Asset has no blob field: #{stats[:surveys_skipped_asset_no_attachments]}",
  '',
  "Time taken: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"
].join("\n")

puts ''
puts summary

WSApplication.message_box(summary, 'OK', 'Information', false)
