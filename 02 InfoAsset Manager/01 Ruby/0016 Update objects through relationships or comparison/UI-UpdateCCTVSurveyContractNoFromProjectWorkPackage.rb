# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-UpdateCCTVSurveyContractNoFromProjectWorkPackage.rb
# Purpose: Set contract_no on CCTV surveys from project and work_package using
#          the CONTRACT_MAPPINGS list below.
#
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

TABLE_NAME = 'cams_cctv_survey'.freeze
PROJECT_FIELD = 'project'.freeze
WORK_PACKAGE_FIELD = 'work_package'.freeze
CONTRACT_NO_FIELD = 'contract_no'.freeze

# ---------------------------------------------------------------------------
# Mapping: one line per match — project, work_package, contract_no
# Values are trimmed; project and work_package matching is case-insensitive.
# ---------------------------------------------------------------------------
CONTRACT_MAPPINGS = [
  'proj1,wp1,con101',
  'proj1,wp2,con102',
  'proj2,wp1,con201'
].freeze

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def non_blank?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def normalise_key_part(value)
  value.to_s.strip.downcase
end

def build_contract_map(mapping_lines)
  map = {}
  mapping_lines.each_with_index do |line, idx|
    text = line.to_s.strip
    next if text.empty? || text.start_with?('#')

    parts = text.split(',', 3)
    if parts.length < 3
      puts "Warning: mapping line #{idx + 1} ignored — expected project,work_package,contract_no: #{line}"
      next
    end

    project = normalise_key_part(parts[0])
    work_package = normalise_key_part(parts[1])
    contract_no = parts[2].to_s.strip
    key = [project, work_package]

    if map.key?(key)
      puts "Warning: duplicate mapping for #{parts[0]},#{parts[1]} — using last entry"
    end
    map[key] = contract_no
  end
  map
end

def verbose_log(verbose, message)
  puts message if verbose
end

def parse_positive_integer(value)
  text = value.to_s.strip
  return nil if text.empty?

  int_val = text.to_i
  return nil if int_val <= 0 || int_val.to_s != text

  int_val
end

def resolve_asset_group(db, group_id)
  group = db.model_object_from_type_and_id('Asset Group', group_id)
  return group unless group.nil?

  db.model_object_from_type_and_id('Asset group', group_id)
end

def select_surveys(net, survey_ids)
  net.clear_selection
  selected = 0

  survey_ids.each do |survey_id|
    survey = net.row_object(TABLE_NAME, survey_id)
    next if survey.nil?

    survey.selected = true
    selected += 1
  end

  selected
end

def create_selection_list(asset_group, base_name)
  name = base_name
  suffix = 2

  begin
    selection_list = asset_group.new_model_object('Selection List', name)
  rescue RuntimeError => e
    raise unless e.message.to_s.downcase.include?('name already in use')

    name = "#{base_name} (#{suffix})"
    suffix += 1
    retry
  end

  [selection_list, name]
end

def create_outcome_selection_lists(net, asset_group, outcome_ids, run_prefix, verbose)
  created = []

  outcome_ids.each do |label, survey_ids|
    next if survey_ids.empty?

    selected = select_surveys(net, survey_ids)
    if selected == 0
      verbose_log(verbose, "Selection List not created for '#{label}' — no surveys could be selected")
      next
    end

    base_name = "#{run_prefix} - #{label}"
    selection_list, list_name = create_selection_list(asset_group, base_name)
    net.save_selection(selection_list)
    created << { name: list_name, id: selection_list.id, count: selected }
    verbose_log(
      verbose,
      "Selection List created: '#{list_name}' (ID #{selection_list.id}, #{selected} survey(s))"
    )
  end

  created
end

def survey_rows(net, selection_only)
  if selection_only
    rows = net.row_objects_selection(TABLE_NAME)
    if rows.nil? || rows.length == 0
      WSApplication.message_box(
        "No CCTV surveys are selected.\n\nSelect one or more CCTV surveys on the GeoPlan, or uncheck 'Process selection only'.",
        'OK', '!', false
      )
      raise 'abort'
    end
    return rows
  end

  net.row_objects(TABLE_NAME)
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

db = WSApplication.current_database

contract_map = build_contract_map(CONTRACT_MAPPINGS)
if contract_map.empty?
  WSApplication.message_box(
    "No valid entries found in CONTRACT_MAPPINGS.\n\nAdd project,work_package,contract_no lines to the script and run again.",
    'OK', '!', false
  )
  raise 'abort'
end

val = WSApplication.prompt(
  'Update CCTV Survey contract_no',
  [
    ['Process SELECTION only?', 'Boolean', false],
    ['Overwrite existing contract_no values?', 'Boolean', false],
    ['Verbose logging?', 'Boolean', false],
    ['Asset Group ID (optional - create outcome Selection Lists)', 'String', '']
  ],
  false
)

selection_only = val[0] == true
overwrite_existing = val[1] == true
verbose = val[2] == true
asset_group_id = parse_positive_integer(val[3])
create_selection_lists = !asset_group_id.nil?

asset_group = nil
if create_selection_lists
  asset_group = resolve_asset_group(db, asset_group_id)
  if asset_group.nil?
    WSApplication.message_box(
      "Asset Group ID #{asset_group_id} was not found.\n\nOutcome Selection Lists will not be created.\nContract_no updates will still run.",
      'OK', '!', false
    )
    create_selection_lists = false
  end
end

run_prefix = "CCTV contract_no #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"

outcome_ids = {
  'Updated' => [],
  'Skipped blank project/work_package' => [],
  'Skipped no mapping match' => [],
  'Skipped existing contract_no' => [],
  'Skipped unchanged' => []
}

updated = 0
skipped_blank_fields = 0
skipped_no_match = 0
skipped_existing = 0
skipped_already_set = 0

net.transaction_begin

survey_rows(net, selection_only).each do |survey|
  survey_id = survey.id
  raw_project = survey[PROJECT_FIELD].to_s.strip
  raw_work_package = survey[WORK_PACKAGE_FIELD].to_s.strip
  project = normalise_key_part(raw_project)
  work_package = normalise_key_part(raw_work_package)

  if project.empty? || work_package.empty?
    skipped_blank_fields += 1
    outcome_ids['Skipped blank project/work_package'] << survey_id if create_selection_lists
    verbose_log(
      verbose,
      "SKIP blank fields: survey #{survey_id} (#{PROJECT_FIELD}='#{raw_project}', #{WORK_PACKAGE_FIELD}='#{raw_work_package}')"
    )
    next
  end

  contract_no = contract_map[[project, work_package]]
  if contract_no.nil?
    skipped_no_match += 1
    outcome_ids['Skipped no mapping match'] << survey_id if create_selection_lists
    verbose_log(
      verbose,
      "SKIP no mapping: survey #{survey_id} (#{PROJECT_FIELD}='#{raw_project}', #{WORK_PACKAGE_FIELD}='#{raw_work_package}')"
    )
    next
  end

  current_contract_no = survey[CONTRACT_NO_FIELD].to_s.strip
  if !overwrite_existing && non_blank?(current_contract_no)
    skipped_existing += 1
    outcome_ids['Skipped existing contract_no'] << survey_id if create_selection_lists
    verbose_log(
      verbose,
      "SKIP existing #{CONTRACT_NO_FIELD}: survey #{survey_id} (#{CONTRACT_NO_FIELD}='#{current_contract_no}')"
    )
    next
  end

  if current_contract_no == contract_no
    skipped_already_set += 1
    outcome_ids['Skipped unchanged'] << survey_id if create_selection_lists
    verbose_log(
      verbose,
      "SKIP unchanged: survey #{survey_id} (#{CONTRACT_NO_FIELD} already '#{contract_no}')"
    )
    next
  end

  survey[CONTRACT_NO_FIELD] = contract_no
  survey.write
  updated += 1
  outcome_ids['Updated'] << survey_id if create_selection_lists
  verbose_log(
    verbose,
    "UPDATE: survey #{survey_id} (#{PROJECT_FIELD}='#{raw_project}', #{WORK_PACKAGE_FIELD}='#{raw_work_package}') #{CONTRACT_NO_FIELD} '#{current_contract_no}' -> '#{contract_no}'"
  )
end

net.transaction_commit

created_selection_lists = []
if create_selection_lists
  created_selection_lists = create_outcome_selection_lists(
    net, asset_group, outcome_ids, run_prefix, verbose
  )
end

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

puts 'CCTV Survey contract_no update complete'
puts "Scope: #{selection_only ? 'selection' : 'all surveys in network'}"
puts "Overwrite existing: #{overwrite_existing}"
puts "Verbose logging: #{verbose}"
if create_selection_lists
  puts "Outcome Selection Lists: Asset Group ID #{asset_group_id}"
elsif !asset_group_id.nil?
  puts 'Outcome Selection Lists: not created (Asset Group not found)'
else
  puts 'Outcome Selection Lists: not requested'
end
puts "Mappings loaded: #{contract_map.length}"
puts "Updated: #{updated}"
puts "Skipped (blank #{PROJECT_FIELD} or #{WORK_PACKAGE_FIELD}): #{skipped_blank_fields}"
puts "Skipped (no mapping match): #{skipped_no_match}"
puts "Skipped (existing contract_no): #{skipped_existing}"
puts "Skipped (already set to mapped value): #{skipped_already_set}"
if create_selection_lists
  if created_selection_lists.empty?
    puts 'Selection Lists created: 0'
  else
    puts "Selection Lists created: #{created_selection_lists.length}"
    created_selection_lists.each do |entry|
      puts "  #{entry[:name]} (ID #{entry[:id]}, #{entry[:count]} survey(s))"
    end
  end
end
puts format('Elapsed: %.2f s', elapsed)
