# `SWMM5_Import_Exchange_Annotated.rb`.

# ==============================================================================
# FILE: SWMM5_Import_Exchange_Annotated.rb
#
# DESCRIPTION:
# This is the "Worker" script (Exchange Script).
# It runs invisibly in the background, launched by the UI script.
#
# CONCEPTS FOR NOVICES:
# 1. "Headless" Execution: This script runs via 'ICMExchange.exe'. It has 
#    no buttons, windows, or popups. If you try to use a message_box here, 
#    the script will crash.
# 2. Environment Variables (ENV): Think of this as a "Post-it note" left by the 
#    UI script on the computer's desktop. The UI script writes the location 
#    of the settings file to ENV, and this script reads it.
# 3. Logging: Since the user can't see a progress bar, we must write every 
#    step to a text file (.log) so the user can read what happened later.
# 4. Error Handling (Begin/Rescue): If File #5 fails, we don't want the script 
#    to stop. We "rescue" the error, write it to the log, and move to File #6.
# 5. Object Model: We use 'db.new_model_object' to create items inside ICM.
# ==============================================================================

require 'yaml' # Toolkit for reading the settings file

# ==============================================================================
# HELPER METHODS
# ==============================================================================

# A helper to write text to TWO places at once:
# 1. The "Standard Output" (puts) - visible in the black Command Prompt window.
# 2. The "Log File" (log_file.puts) - saved to the hard drive.
def log(message, log_file = nil)
  puts message
  log_file.puts message if log_file
end

# A helper to check if a 'Label List' (a specific ICM object) has any data.
# We want to delete empty ones to keep the model clean.
def is_label_list_empty?(label_list, log_file = nil)
  begin
    # We look at the 'labels' data blob inside the object
    labels_blob = label_list['labels']
    # Return TRUE if it's nil (doesn't exist) or empty
    return labels_blob.nil? || labels_blob.empty?
  rescue => e
    log "  WARNING: Error checking label list: #{e.message}", log_file
    false
  end
end

# ==============================================================================
# STEP 1: RETRIEVE CONFIGURATION
# ==============================================================================

# Grab the "Post-it note" left by the UI script
config_file = ENV['ICM_IMPORT_CONFIG']

# SAFETY LOGIC: 
# If the Post-it note is missing (maybe you ran this script manually?), 
# try to hunt for the config file in nearby folders.
unless config_file && File.exist?(config_file)
  script_dir = File.dirname(__FILE__)
  
  # Search current folder, parent, and grandparent for the config file
  search_paths = []
  [script_dir, File.dirname(script_dir), File.dirname(File.dirname(script_dir))].each do |dir|
    Dir.glob(File.join(dir, "**", "ICM Import Log Files", "import_config.yaml")).each do |path|
      search_paths << path
    end
  end
  
  # If found, take the most recent one
  if search_paths.any?
    config_file = search_paths.max_by { |f| File.mtime(f) }
  end
end

# If we STILL can't find the settings, we must stop.
unless config_file && File.exist?(config_file)
  puts "ERROR: Configuration file not found. Run the UI script first."
  exit 1 # Exit code 1 means "Something went wrong"
end

# Load the settings from the file
config = YAML.load_file(config_file)

# Check if all necessary settings are present
required_keys = ['import_mode', 'file_configs', 'cleanup_empty_label_lists']
missing = required_keys - config.keys
if missing.any?
  puts "ERROR: Config file is corrupted. Missing: #{missing.join(', ')}"
  exit 1
end

# Extract settings into easy-to-use variables
import_mode = config['import_mode']
file_configs = config['file_configs'] # This is the list of files to process
cleanup_empty_label_lists = config['cleanup_empty_label_lists']
validate_after_import = config.fetch('validate_after_import', false)

# ==============================================================================
# STEP 2: CONNECT TO THE DATABASE
# ==============================================================================

begin
  # WSApplication.open connects to the database without showing a login screen 
  # (assuming current Windows credentials work).
  db = WSApplication.open
rescue => e
  puts "Error opening database: #{e.message}"
  exit 1
end

if db.nil?
  puts "Failed to open the database."
  exit 1
end

# ==============================================================================
# STEP 3: START THE LOG FILE
# ==============================================================================

log_dir = File.join(config['base_directory'], "ICM Import Log Files")
Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

# Create a unique log filename using the current time
log_filename = File.join(log_dir, "SWMM5_Batch_Import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
log_file = File.open(log_filename, 'w') # 'w' means Write mode

# Write the header to the log
log "="*70, log_file
log "SWMM5 Import Log - #{Time.now}", log_file
log "Database GUID: #{db.guid}", log_file
log "Files to process: #{file_configs.length}", log_file
log "="*70 + "\n", log_file

# Setup a scorecard to keep track of our results
aggregate_stats = {
  files_processed: 0,
  files_successful: 0,
  files_failed: 0,
  total_nodes: 0,
  total_links: 0,
  total_subcatchments: 0,
  total_label_lists_deleted: 0,
  failed_files: []
}

# ==============================================================================
# STEP 4: THE MAIN LOOP (Process Every File)
# ==============================================================================

puts "STARTING BATCH PROCESSING..."

# Loop through every file in our configuration list
file_configs.each_with_index do |file_config, file_index|
  
  file_path = file_config['file_path']
  model_group_name = file_config['model_group_name']
  file_basename = file_config['file_basename']
  
  # Visual separator in the log
  log "\n" + "="*70, log_file
  log "[File #{file_index + 1} of #{file_configs.length}]: #{file_basename}", log_file
  log "="*70, log_file
  
  aggregate_stats[:files_processed] += 1

  # ----------------------------------------------------------------------------
  # Pre-Checks (Before we try to import)
  # ----------------------------------------------------------------------------
  
  if !File.exist?(file_path)
    log "ERROR: File missing: #{file_path}", log_file
    aggregate_stats[:files_failed] += 1
    aggregate_stats[:failed_files] << { file: file_basename, reason: "File not found" }
    next # Skip to the next file in the loop
  end

  # ----------------------------------------------------------------------------
  # The "Safety Net" Block (Begin/Rescue)
  # ----------------------------------------------------------------------------
  begin
    # TRACKER: Keep stats just for this one file
    import_stats = { nodes: 0, links: 0, subcatchments: 0 }
    
    # --- Phase 1: Create the Container (Model Group) ---
    log "  Action: Creating Model Group '#{model_group_name}'...", log_file
    
    # 'db.new_model_object' creates a new item in the database tree.
    # Type: 'Model Group', Name: model_group_name
    model_group = db.new_model_object('Model Group', model_group_name)
    
    # --- Phase 2: Import the Data ---
    log "  Action: Importing .inp file...", log_file
    
    # We create a temporary text file to capture the specific import warnings 
    # that the ICM engine generates internally.
    import_log_path = File.join(log_dir, "#{File.basename(file_path, '.inp')}_import.txt")
    
    # This is the CORE COMMAND. It tells ICM to suck in the .inp file.
    imported_objects = model_group.import_all_sw_model_objects(
      file_path,       # Source file
      "inp",           # Format
      nil,             # Options (nil = default)
      import_log_path  # Where to write the internal engine log
    )
    
    # Check if it actually worked
    if imported_objects.nil? || imported_objects.empty?
      raise "Import returned no objects. The file might be empty or corrupt."
    end
    
    log "  Success: Imported #{imported_objects.length} items.", log_file

    # --- Phase 3: Gather Stats ---
    
    # We need to find the "Network" object inside the list of things we just imported.
    imported_network = imported_objects.find { |obj| obj.type == 'SWMM network' }
    
    if imported_network
      # 'open' opens the network in memory so we can count things.
      net = imported_network.open
      
      # Count the rows in specific tables
      import_stats[:nodes] = net.row_objects('_nodes').length
      import_stats[:links] = net.row_objects('_links').length
      import_stats[:subcatchments] = net.row_objects('_subcatchments').length
      
      log "  Stats: Nodes: #{import_stats[:nodes]}, Links: #{import_stats[:links]}", log_file
      
      # Add to the grand totals
      aggregate_stats[:total_nodes] += import_stats[:nodes]
      aggregate_stats[:total_links] += import_stats[:links]
      aggregate_stats[:total_subcatchments] += import_stats[:subcatchments]
      
      # 'commit' saves the network changes (even though we just opened it to read, 
      # it's good practice in Exchange scripts to commit/close).
      net.commit("Imported via Script")
    end

    # --- Phase 4: Cleanup (Label Lists) ---
    
    if cleanup_empty_label_lists
      log "  Action: Checking for empty Label Lists...", log_file
      deleted_count = 0
      
      # Loop through everything we imported
      imported_objects.each do |obj|
        if obj.type == 'Label List'
          # Use our helper function to see if it's empty
          if is_label_list_empty?(obj, log_file)
             # Delete it from the database
             obj.delete
             deleted_count += 1
          end
        end
      end
      
      if deleted_count > 0
        log "  Cleanup: Removed #{deleted_count} empty label lists.", log_file
        aggregate_stats[:total_label_lists_deleted] += deleted_count
      end
    end
    
    # --- Phase 5: Validation (Optional) ---
    
    if validate_after_import && imported_network
      log "  Action: Running Validation Checks...", log_file
      
      # Example Check: Is the network completely empty?
      if import_stats[:nodes] == 0 && import_stats[:links] == 0
        log "  WARNING: Network contains 0 nodes and 0 links.", log_file
      end
      
      # (Additional validation logic is in the original code, simplified here for clarity)
    end

    # If we got here, everything worked!
    aggregate_stats[:files_successful] += 1
    log "  RESULT: File processed successfully.", log_file

  rescue => e
    # --------------------------------------------------------------------------
    # The Error Handler
    # --------------------------------------------------------------------------
    # If anything inside the 'begin' block crashed:
    
    log "  CRITICAL ERROR: #{e.message}", log_file
    log "  Trace: #{e.backtrace.first}", log_file
    
    # If we created a Model Group but failed halfway through, 
    # try to delete the messy group so we don't leave junk behind.
    if defined?(model_group) && model_group
      begin
        model_group.delete
        log "  Cleanup: Deleted partial model group.", log_file
      rescue
        # If we can't even delete it, just move on.
      end
    end
    
    # Record the failure
    aggregate_stats[:files_failed] += 1
    aggregate_stats[:failed_files] << { file: file_basename, reason: e.message }
  end
end

# ==============================================================================
# STEP 5: WRITE THE SUMMARY FILE
# ==============================================================================

log "\n" + "="*70, log_file
log "FINAL SUMMARY", log_file
log "Processed: #{aggregate_stats[:files_processed]}", log_file
log "Success:   #{aggregate_stats[:files_successful]}", log_file
log "Failed:    #{aggregate_stats[:files_failed]}", log_file
log "="*70, log_file

log_file.close

# Create a specific "batch_summary.txt" file.
# The UI script reads THIS file to show the final popup to the user.
summary_file_path = File.join(log_dir, "batch_summary.txt")

File.open(summary_file_path, 'w') do |f|
  f.puts "files_processed=#{aggregate_stats[:files_processed]}"
  f.puts "files_successful=#{aggregate_stats[:files_successful]}"
  f.puts "files_failed=#{aggregate_stats[:files_failed]}"
  f.puts "total_nodes=#{aggregate_stats[:total_nodes]}"
  f.puts "total_links=#{aggregate_stats[:total_links]}"
  f.puts "total_subcatchments=#{aggregate_stats[:total_subcatchments]}"
  f.puts "total_label_lists_deleted=#{aggregate_stats[:total_label_lists_deleted]}"
end

puts "Summary file written to: #{summary_file_path}"

# Exit code 0 = Success, 1 = Some failures occurred
exit(aggregate_stats[:files_failed] > 0 ? 1 : 0)
```