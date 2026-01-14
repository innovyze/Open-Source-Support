# Test Copy to Single Database
# Test the copy operation on one database before batch processing

SOURCE_DB = 'cloud://user@id/region'.freeze  # Edit: Source database
TARGET_DB = 'cloud://user@id/test'.freeze    # Edit: Test database
GROUP_TYPE = 'MODG'.freeze                   # Edit: 'MODG' (Model), 'MASG' (Master), 'AG' (Asset)
GROUP_NAME = 'Automation'.freeze             # Edit: Group name
APPEND_DATE = true                           # Edit: Append date to copied group name
DRY_RUN = false                              # Set to true to preview changes without executing

# Valid group types and their display names
VALID_GROUP_TYPES = ['MODG', 'MASG', 'AG'].freeze
GROUP_TYPE_NAMES = {
  'MODG' => 'Model Group',
  'MASG' => 'Master Group',
  'AG' => 'Asset Group'
}.freeze

# Validate GROUP_TYPE at script start
unless VALID_GROUP_TYPES.include?(GROUP_TYPE)
  puts "ERROR: Invalid GROUP_TYPE '#{GROUP_TYPE}'. Must be one of: #{VALID_GROUP_TYPES.join(', ')}"
  exit 1
end

def log(msg)
  puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}"
end

begin
  log "Source: #{SOURCE_DB}"
  log "Target: #{TARGET_DB}"
  log "Type: #{GROUP_TYPE}, Group: #{GROUP_NAME}"
  
  # Determine target group name
  if APPEND_DATE
    date_suffix = Time.now.strftime('%Y%m%d')
    target_name = "#{GROUP_NAME}_#{date_suffix}"
    log "Date appending enabled: target name = #{target_name}"
  else
    target_name = GROUP_NAME
  end
  
  # Open source
  log "\nOpening source database..."
  db_source = WSApplication.open(SOURCE_DB, true)
  
  source_group = db_source.model_object(">#{GROUP_TYPE}~#{GROUP_NAME}")
  if source_group.nil?
    log "ERROR: Group '#{GROUP_NAME}' (type: #{GROUP_TYPE}) not found in source database"
    log "  Expected path: >#{GROUP_TYPE}~#{GROUP_NAME}"
    db_source.close
    exit 1
  end
  log "Found source group (ID: #{source_group.id})"
  
  # Open target
  log "\nOpening target database..."
  db_target = WSApplication.open(TARGET_DB, false)
  
  # Delete old versions
  if APPEND_DATE
    deleted_count = 0
    group_type_name = GROUP_TYPE_NAMES[GROUP_TYPE]
    date_pattern = /\A#{Regexp.escape(GROUP_NAME)}_\d{8}\z/
    db_target.root_model_objects.each do |mo|
      if mo.type == group_type_name && mo.name.match?(date_pattern)
        if DRY_RUN
          log "[DRY RUN] Would delete: #{mo.name} (ID: #{mo.id})"
        else
          log "Deleting old version: #{mo.name} (ID: #{mo.id})"
          mo.delete
        end
        deleted_count += 1
      end
    end
    log "Deleted #{deleted_count} old version(s)" if deleted_count > 0 && !DRY_RUN
    log "[DRY RUN] Would delete #{deleted_count} old version(s)" if deleted_count > 0 && DRY_RUN
  else
    existing = db_target.model_object(">#{GROUP_TYPE}~#{GROUP_NAME}")
    if existing
      if DRY_RUN
        log "[DRY RUN] Would delete existing group: #{existing.name} (ID: #{existing.id})"
      else
        log "Deleting existing group (ID: #{existing.id})..."
        existing.delete
      end
    else
      log "No existing group to delete"
    end
  end
  
  # Copy
  if DRY_RUN
    log "\n[DRY RUN] Would copy group to target"
    copied = nil
  else
    log "\nCopying group..."
    copied = db_target.copy_into_root(source_group, true, true)
  end
  
  # Rename if appending date
  if APPEND_DATE && copied
    copied.name = target_name
    log "Renamed to: #{target_name}"
  end
  
  # Verify
  log "Verifying..."
  if DRY_RUN
    log "[DRY RUN] Would succeed"
  elsif copied
    log "SUCCESS: Group copied (ID: #{copied.id}, Name: #{copied.name})"
  else
    log "ERROR: copy_into_root returned nil"
  end
  
  log "\nTest complete. Verify in UI before running batch."
  
  if DRY_RUN
    log "\n[DRY RUN MODE] No changes were made. Review the above and set DRY_RUN = false to execute."
  end
  
rescue => e
  log "ERROR: #{e.message}"
  log "Backtrace:"
  e.backtrace.first(5).each { |line| log "  #{line}" }
  exit 1
ensure
  # Always close databases
  begin
    db_source.close if db_source
  rescue => close_error
    log "Warning: Error closing source - #{close_error.message}"
  end
  
  begin
    db_target.close if db_target
  rescue => close_error
    log "Warning: Error closing target - #{close_error.message}"
  end
end
