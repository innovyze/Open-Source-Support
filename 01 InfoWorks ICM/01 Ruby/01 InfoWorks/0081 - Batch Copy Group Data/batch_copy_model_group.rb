# Batch Copy Model Group to Multiple Databases
# Copies a model group from source database to multiple target databases

require 'csv'

# ============================================================================
# CONFIGURATION
# ============================================================================

SOURCE_DB = 'cloud://user@id/region'.freeze  # Source database path
GROUP_TYPE = 'MASG'.freeze                    # Group type: 'MASG' (Group), 'MODG' (Model Group), 'AG' (Asset Group)
GROUP_NAME = 'Automation'.freeze              # Group name to copy
APPEND_DATE = true                            # Append date to copied group name (e.g., Automation_20251212)
DATABASE_LIST_CSV = 'database_list.csv'.freeze
DRY_RUN = false                               # Set to true to preview changes without executing

# Valid group types and their display names
VALID_GROUP_TYPES = ['MODG', 'MASG', 'AG'].freeze
GROUP_TYPE_NAMES = {
  'MODG' => 'Model Group',
  'MASG' => 'Master Group',
  'AG' => 'Asset Group'
}.freeze

# ============================================================================

# Validate GROUP_TYPE at script start
unless VALID_GROUP_TYPES.include?(GROUP_TYPE)
  puts "ERROR: Invalid GROUP_TYPE '#{GROUP_TYPE}'. Must be one of: #{VALID_GROUP_TYPES.join(', ')}"
  exit 1
end

def log(msg)
  puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}"
end

begin
  script_dir = File.dirname(WSApplication.script_file)
  csv_path = File.join(script_dir, DATABASE_LIST_CSV)
  log_path = File.join(script_dir, "batch_log_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")
  
  # Read target databases
  databases = []
  CSV.foreach(csv_path, headers: true) do |row|
    path = row['database_path'].to_s.strip
    databases << path unless path.empty?
  end
  
  log "Found #{databases.length} target databases"
  log "Source: #{SOURCE_DB}, Type: #{GROUP_TYPE}, Group: #{GROUP_NAME}"
  
  # Determine target group name
  if APPEND_DATE
    date_suffix = Time.now.strftime('%Y%m%d')
    target_name = "#{GROUP_NAME}_#{date_suffix}"
    log "Date appending enabled: target name = #{target_name}"
  else
    target_name = GROUP_NAME
  end
  
  # Open source database
  log "Opening source database..."
  db_source = WSApplication.open(SOURCE_DB, true)  # Read-only
  
  # Get source group
  source_group = db_source.model_object(">#{GROUP_TYPE}~#{GROUP_NAME}")
  if source_group.nil?
    log "ERROR: Group '#{GROUP_NAME}' (type: #{GROUP_TYPE}) not found in source database"
    log "  Expected path: >#{GROUP_TYPE}~#{GROUP_NAME}"
    db_source.close
    exit 1
  end
  log "Found source group (ID: #{source_group.id})"
  
  # Process each target database
  success = 0
  failed = 0
  
  databases.each_with_index do |db_path, idx|
    log "\n[#{idx+1}/#{databases.length}] Processing: #{db_path}"
    
    db_target = nil
    begin
      # Open target database
      db_target = WSApplication.open(db_path, false)  # Read-write
      
      # Delete old dated versions if appending date
      if APPEND_DATE
        deleted_count = 0
        group_type_name = GROUP_TYPE_NAMES[GROUP_TYPE]
        date_pattern = /\A#{Regexp.escape(GROUP_NAME)}_\d{8}\z/
        db_target.root_model_objects.each do |mo|
          if mo.type == group_type_name && mo.name.match?(date_pattern)
            if DRY_RUN
              log "  [DRY RUN] Would delete: #{mo.name}"
            else
              log "  Deleting old version: #{mo.name}"
              mo.delete
            end
            deleted_count += 1
          end
        end
        log "  Deleted #{deleted_count} old version(s)" if deleted_count > 0 && !DRY_RUN
        log "  [DRY RUN] Would delete #{deleted_count} old version(s)" if deleted_count > 0 && DRY_RUN
      else
        # Delete exact name match if not appending date
        existing = db_target.model_object(">#{GROUP_TYPE}~#{GROUP_NAME}")
        if existing
          if DRY_RUN
            log "  [DRY RUN] Would delete existing group: #{existing.name}"
          else
            log "  Deleting existing group..."
            existing.delete
          end
        end
      end
      
      # Copy group from source
      if DRY_RUN
        log "  [DRY RUN] Would copy group to target"
        copied = nil
      else
        log "  Copying group..."
        copied = db_target.copy_into_root(source_group, true, true)
      end
      
      # Rename if appending date
      if APPEND_DATE && copied
        copied.name = target_name
        log "  Renamed to: #{target_name}"
      end
      
      # Verify by checking returned object
      if DRY_RUN
        log "  [DRY RUN] Would succeed"
        success += 1
      elsif copied
        log "  SUCCESS (ID: #{copied.id})"
        success += 1
      else
        log "  WARNING: copy_into_root returned nil"
        failed += 1
      end
      
    rescue => e
      log "  FAILED: #{e.message}"
      log "  Backtrace:"
      e.backtrace.first(5).each { |line| log "    #{line}" }
      failed += 1
    ensure
      # Always close target database
      begin
        db_target.close if db_target
      rescue => close_error
        log "  Warning: Error closing database - #{close_error.message}"
      end
    end
  end
  
  # Summary
  log "\n" + "="*60
  log "COMPLETE: #{success} succeeded, #{failed} failed"
  log "="*60
  
  if DRY_RUN
    log "\n[DRY RUN MODE] No changes were made. Review the above and set DRY_RUN = false to execute."
  end
  
rescue => e
  log "FATAL: #{e.message}"
  log e.backtrace.join("\n")
  exit 1
ensure
  # Always close source database
  begin
    db_source.close if db_source
  rescue => close_error
    log "Warning: Error closing source database - #{close_error.message}"
  end
end
