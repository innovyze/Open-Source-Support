# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-UpdateAssetsFromFloodDefenceSurvey.rb
# Purpose: For each of the asset types in the user_text_40 field, find the latest
#          unprocessed flood defence survey (used_in_network = false) linked
#          to each asset via user_text_39 (asset ID) and user_text_40 (asset
#          type), copy the survey fields to the asset, then mark the survey
#          as used_in_network = true.
# Run from: Network > Run Ruby Script (with a Collection Network open)
# ============================================================================

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network

# ---------------------------------------------------------------------------
# Mapping from the value stored in user_text_40 to the cams_ table name.
# Handles both cams_ table names and common display-name variants so that
# either format stored in the survey field will resolve correctly.
# Adjust the display-name keys if your user_text_40 uses different wording.
# ---------------------------------------------------------------------------
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
# Pass 1: scan ALL flood defence surveys (processed or not) and track the
# single latest survey per (cams_table, asset_id) by survey_date, regardless
# of used_in_network status.  A separate hash records whether that latest
# survey is still unprocessed — only those assets will be updated.
# This prevents an older unprocessed survey being applied when a newer one
# has already been marked used_in_network = true.
# ---------------------------------------------------------------------------
# all_latest[cams_table][asset_id]  = survey row object (latest overall)
all_latest   = Hash.new { |h, k| h[k] = {} }
skipped_type = []

net.row_objects('cams_flood_defence_survey').each do |survey|
  raw_type = survey.user_text_40
  asset_id = survey.user_text_39
  next if raw_type.nil? || raw_type.strip.empty?
  next if asset_id.nil? || asset_id.strip.empty?

  table = ASSET_TYPE_MAP[raw_type.strip.downcase]
  if table.nil?
    skipped_type << raw_type unless skipped_type.include?(raw_type)
    next
  end

  current_best = all_latest[table][asset_id]
  if current_best.nil? || survey.survey_date > current_best.survey_date
    all_latest[table][asset_id] = survey
  end
end

# Keep only assets whose latest survey has not yet been processed.
latest_by_asset = Hash.new { |h, k| h[k] = {} }
all_latest.each do |table, by_id|
  by_id.each do |asset_id, survey|
    if survey.used_in_network == true
      puts "Skipping #{table} '#{asset_id}': latest survey '#{survey.id}' is already marked used_in_network."
    else
      latest_by_asset[table][asset_id] = survey
    end
  end
end

unless skipped_type.empty?
  puts "WARNING: unrecognised asset type value(s) in user_text_40 — skipped:"
  skipped_type.each { |t| puts "  '#{t}'" }
end

total_surveys = latest_by_asset.values.map(&:size).sum
puts "Latest unprocessed survey found for #{total_surveys} asset(s) across #{latest_by_asset.size} table(s)."

if total_surveys == 0
  puts "Nothing to update."
else

  # -------------------------------------------------------------------------
  # Pass 2: build an id→row_object lookup for each asset table we need.
  # -------------------------------------------------------------------------
  asset_lookup = {}
  latest_by_asset.each_key do |table|
    lookup = {}
    net.row_objects(table).each { |a| lookup[a.id] = a }
    asset_lookup[table] = lookup
    puts "Loaded #{lookup.size} row(s) from #{table}."
  end

  # -------------------------------------------------------------------------
  # Pass 3: update assets and mark surveys processed — single transaction.
  # -------------------------------------------------------------------------
  updated = 0
  not_found = 0

  net.transaction_begin

  latest_by_asset.each do |table, by_id|
    by_id.each do |asset_id, survey|
      asset = asset_lookup[table][asset_id]

      if asset.nil?
        puts "WARNING: #{table} asset '#{asset_id}' not found in network — skipping."
        not_found += 1
        next
      end

      date_str = survey.survey_date.strftime('%Y-%m-%d %H:%M') rescue survey.survey_date.to_s

      # -- Copy survey fields to asset -----------------------------------------
      asset.survey_date     = survey.survey_date
      asset.material        = survey.user_text_4
      asset.user_text_5     = survey.user_text_5
      asset.user_text_6     = survey.user_text_6
      asset.user_text_7     = survey.user_text_3
      asset.user_number_1   = survey.user_number_1
      asset.location        = survey.location
      asset.name            = survey.user_text_8
      asset.user_text_4     = survey.repeat_period
      asset.user_text_1     = survey.user_text_1
      asset.user_text_9     = survey.user_text_9
      asset.user_text_10    = survey.user_text_11
      asset.condition_grade = survey.condition_grading_score

      # Append survey date and notes to existing asset notes, mirroring:
      # notes = notes + nl() + survey_date + nl() + survey.notes
      existing_notes = asset.notes.to_s
      survey_notes   = survey.notes.to_s
      asset.notes    = existing_notes.empty? ? "#{date_str}\r\n#{survey_notes}" : "#{existing_notes}\r\n#{date_str}\r\n#{survey_notes}"

      asset.write

      # -- Update survey -------------------------------------------------------
      survey.contractor      = survey.surveyed_by
      survey.used_in_network = true
      survey.write

      puts "Updated #{table} '#{asset_id}' from survey '#{survey.id}' (#{date_str})."
      updated += 1
    end
  end

  net.transaction_commit

  endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed    = endingTime - startingTime

  puts "\nDone. #{updated} asset(s) updated, #{not_found} not found in network."
  puts "Time taken: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"

end
