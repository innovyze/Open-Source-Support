# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-UpdateFloodDefenceSurveyFromAsset_Selection.rb
# Purpose: For each selected cams_flood_defence_survey, look up the linked
#          asset via user_text_39 (asset ID) and user_text_40 (asset type),
#          then copy asset fields back onto the survey.
# Run from: Network > Run Ruby Script (with flood defence surveys selected)
# ============================================================================

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network

# ---------------------------------------------------------------------------
# Mapping from the value stored in user_text_40 to the cams_ table name.
# Handles both cams_ table names and common display-name variants.
# Adjust the display-name keys if your user_text_40 uses different wording.
# ---------------------------------------------------------------------------
ASSET_TYPE_MAP_REV = {
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
# Pass 1: read the selected surveys and collect the asset tables needed.
# ---------------------------------------------------------------------------
selected_surveys = net.row_objects_selection('cams_flood_defence_survey')

if selected_surveys.nil? || selected_surveys.length == 0
  puts 'No flood defence surveys are selected. Please select surveys and re-run.'
else

  tables_needed = {}
  skipped_type  = []

  selected_surveys.each do |survey|
    raw_type = survey.user_text_40
    asset_id = survey.user_text_39
    next if raw_type.nil? || raw_type.strip.empty?
    next if asset_id.nil? || asset_id.strip.empty?

    table = ASSET_TYPE_MAP_REV[raw_type.strip.downcase]
    if table.nil?
      skipped_type << raw_type unless skipped_type.include?(raw_type)
      next
    end

    tables_needed[table] = true
  end

  unless skipped_type.empty?
    puts 'WARNING: unrecognised asset type value(s) in user_text_40 — those surveys will be skipped:'
    skipped_type.each { |t| puts "  '#{t}'" }
  end

  # -------------------------------------------------------------------------
  # Pass 2: build an id->row_object lookup for each required asset table.
  # -------------------------------------------------------------------------
  asset_lookup = {}
  tables_needed.each_key do |table|
    lookup = {}
    net.row_objects(table).each { |a| lookup[a.id] = a }
    asset_lookup[table] = lookup
    puts "Loaded #{lookup.size} row(s) from #{table}."
  end

  # -------------------------------------------------------------------------
  # Pass 3: update each selected survey from its linked asset.
  # -------------------------------------------------------------------------
  updated   = 0
  not_found = 0
  skipped   = 0

  net.transaction_begin

  selected_surveys.each do |survey|
    raw_type = survey.user_text_40
    asset_id = survey.user_text_39

    if raw_type.nil? || raw_type.strip.empty? || asset_id.nil? || asset_id.strip.empty?
      puts "Skipping survey '#{survey.id}': user_text_39 or user_text_40 is blank."
      skipped += 1
      next
    end

    table = ASSET_TYPE_MAP_REV[raw_type.strip.downcase]
    if table.nil?
      skipped += 1
      next
    end

    asset = asset_lookup[table][asset_id]
    if asset.nil?
      puts "WARNING: #{table} asset '#{asset_id}' not found for survey '#{survey.id}' — skipping."
      not_found += 1
      next
    end

    # -- Copy asset fields to survey ------------------------------------------
    survey.user_text_15 = asset.user_text_12
    survey.priority     = asset.user_text_16
    survey.user_text_14 = asset.owner
    survey.user_text_7  = asset.user_text_4

    survey.write

    puts "Updated survey '#{survey.id}' from #{table} asset '#{asset_id}'."
    updated += 1
  end

  net.transaction_commit

  endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed    = endingTime - startingTime

  puts "\nDone. #{updated} survey(s) updated, #{not_found} asset(s) not found, #{skipped} survey(s) skipped."
  puts "Time taken: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"

end
