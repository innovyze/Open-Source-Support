# ============================================================================
# SWMM5 Import WITH CLEANUP - EXCHANGE SCRIPT (Version 2)
# ============================================================================
# 
# WHAT THIS SCRIPT DOES:
#   Processes single or multiple SWMM5 .inp files based on configuration
#   
#   For each file:
#     Phase 1:   Import SWMM5 .inp file to a new model group
#                + Clean up empty label lists after import
#     Phase 2:   Perform post-import validation
#                + Report import statistics
#                + Log any warnings or issues
#
# NEW IN VERSION 2:
#   - Supports single file import
#   - Supports batch directory import
#   - Supports recursive subdirectory scanning
#   - Progress tracking for batch imports
#   - Aggregate statistics for multiple files
#   - Continues processing on individual file failures
#   - Writes summary file for accurate statistics reporting
#
# RUNS AUTOMATICALLY:
#   Launched by SWMM5_Import_with_Cleanup_UI.rb (UI script)
#   Reads configuration from YAML file
#
# ============================================================================

require 'yaml'

# ----------------------------------------------------------------------------
# Helper method for logging
# ----------------------------------------------------------------------------
def log(message, log_file = nil)
  puts message
  log_file.puts message if log_file
end

# ----------------------------------------------------------------------------
# Helper method to check if a label list is empty
# ----------------------------------------------------------------------------
def is_label_list_empty?(label_list, log_file = nil)
  begin
    labels_blob = label_list['labels']
    return labels_blob.nil? || labels_blob.empty?
  rescue => e
    log "  WARNING: Error checking label list: #{e.message}", log_file
    false
  end
end

# ----------------------------------------------------------------------------
# Read configuration
# ----------------------------------------------------------------------------
config_file = ENV['ICM_IMPORT_CONFIG']

unless config_file && File.exist?(config_file)
  script_dir = File.dirname(__FILE__)
  parent_dir = File.dirname(script_dir)
  grandparent_dir = File.dirname(parent_dir)
  
  search_paths = []
  [script_dir, parent_dir, grandparent_dir].each do |dir|
    Dir.glob(File.join(dir, "**", "ICM Import Log Files", "import_config.yaml")).each do |path|
      search_paths << path
    end
  end
  
  if search_paths.any?
    config_file = search_paths.max_by { |f| File.mtime(f) }
  end
end

unless config_file && File.exist?(config_file)
  puts "ERROR: Configuration file not found"
  puts "Please run SWMM5_Import_with_Cleanup_UI.rb first to generate the config file."
  exit 1
end

config = YAML.load_file(config_file)

# Validate configuration
required_keys = ['import_mode', 'file_configs', 'file_type', 'cleanup_empty_label_lists']
missing = required_keys - config.keys
if missing.any?
  puts "ERROR: Configuration missing required keys: #{missing.join(', ')}"
  puts "Please run the UI script again to regenerate the configuration."
  exit 1
end

import_mode = config['import_mode']
file_configs = config['file_configs']
cleanup_empty_label_lists = config['cleanup_empty_label_lists']
validate_after_import = config['validate_after_import']

puts "\n" + "="*70
puts "  SWMM5 Import to ICM InfoWorks (V2)"
puts "="*70
puts "\nImport Mode: #{import_mode}"
puts "Files to process: #{file_configs.length}"
puts "\n" + "="*70

# ----------------------------------------------------------------------------
# Open database
# ----------------------------------------------------------------------------
begin
  db = WSApplication.open
rescue => e
  puts "Error opening database: #{e.message}"
  exit 1
end

if db.nil?
  puts "Failed to open the database."
  exit 1
end

# ----------------------------------------------------------------------------
# Setup logging
# ----------------------------------------------------------------------------
log_dir = File.join(config['base_directory'], "ICM Import Log Files")
Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

log_filename = File.join(log_dir, "SWMM5_Batch_Import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
log_file = File.open(log_filename, 'w')

log "\n" + "="*70, log_file
log "SWMM5 Import to ICM InfoWorks (V2) - #{Time.now}", log_file
log "="*70, log_file
log "Database GUID: #{db.guid}", log_file
log "Import Mode: #{import_mode}", log_file
log "Files to process: #{file_configs.length}", log_file
log "Cleanup empty label lists: #{cleanup_empty_label_lists}", log_file
log "Validate after import: #{validate_after_import}", log_file
log "="*70 + "\n", log_file

# Initialize aggregate statistics
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

# ============================================================================
# MAIN IMPORT LOOP: Process each file
# ============================================================================
puts "+" + "="*68 + "+"
puts "|" + " "*22 + "BATCH IMPORT PROCESSING" + " "*23 + "|"
puts "+" + "="*68 + "+"
puts ""

log "\n" + "="*70, log_file
log "BATCH IMPORT PROCESSING", log_file
log "="*70, log_file

file_configs.each_with_index do |file_config, file_index|
  file_path = file_config['file_path']
  model_group_name = file_config['model_group_name']
  file_basename = file_config['file_basename']
  
  puts "\n" + "-"*70
  puts "[#{file_index + 1}/#{file_configs.length}] Processing: #{file_basename}"
  puts "-"*70
  
  log "\n" + "="*70, log_file
  log "[#{file_index + 1}/#{file_configs.length}] FILE: #{file_basename}", log_file
  log "="*70, log_file
  log "Full path: #{file_path}", log_file
  log "Model group: #{model_group_name}", log_file
  
  aggregate_stats[:files_processed] += 1
  
  # Validate file exists
  unless File.exist?(file_path)
    error_msg = "ERROR: File not found: #{file_path}"
    puts "  #{error_msg}"
    log error_msg, log_file
    aggregate_stats[:files_failed] += 1
    aggregate_stats[:failed_files] << { file: file_basename, reason: "File not found" }
    next
  end
  
  # Validate file extension
  unless File.extname(file_path).downcase == ".inp"
    error_msg = "ERROR: Not a .inp file: #{file_path}"
    puts "  #{error_msg}"
    log error_msg, log_file
    aggregate_stats[:files_failed] += 1
    aggregate_stats[:failed_files] << { file: file_basename, reason: "Invalid file type" }
    next
  end
  
  # File-specific statistics
  import_stats = { nodes: 0, links: 0, subcatchments: 0 }
  cleanup_stats = { label_lists_found: 0, label_lists_deleted: 0, label_lists_kept: 0 }
  validation_warnings = []
  
  begin
    # ========================================================================
    # PHASE 1: Import file
    # ========================================================================
    log "\nPHASE 1: Import SWMM5 file", log_file
    puts "  Step 1: Creating model group..."
    
    # Create model group
    begin
      model_group = db.new_model_object('Model Group', model_group_name)
      log "  Model group created with ID: #{model_group.id}", log_file
      puts "          Model group created"
    rescue => e
      if e.message.include?("already exists")
        error_msg = "ERROR: Model group '#{model_group_name}' already exists"
        puts "  #{error_msg}"
        log error_msg, log_file
        aggregate_stats[:files_failed] += 1
        aggregate_stats[:failed_files] << { file: file_basename, reason: "Duplicate model group name" }
        next
      else
        raise
      end
    end
    
    # Import file
    import_log_path = File.join(log_dir, "#{File.basename(file_path, '.inp')}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")
    
    log "  Importing: #{file_basename}", log_file
    puts "  Step 2: Importing network..."
    
    imported_objects = model_group.import_all_sw_model_objects(
      file_path,
      "inp",
      nil,
      import_log_path
    )
    
    # Check import success
    if imported_objects.nil? || imported_objects.empty?
      error_msg = "No objects imported"
      puts "          FAILED: #{error_msg}"
      log "  ERROR: #{error_msg}", log_file
      
      if File.exist?(import_log_path)
        log "  Import log contents:", log_file
        File.foreach(import_log_path) do |line|
          log "    #{line.strip}", log_file
        end
      end
      
      # Clean up empty model group
      begin
        model_group.delete
        log "  Deleted empty model group", log_file
      rescue => e
        log "  Could not delete empty model group: #{e.message}", log_file
      end
      
      aggregate_stats[:files_failed] += 1
      aggregate_stats[:failed_files] << { file: file_basename, reason: "No objects imported" }
      next
    end
    
    puts "          Import successful: #{imported_objects.length} objects"
    log "  SUCCESS: Imported #{imported_objects.length} objects", log_file
    
    # Find the imported network
    imported_network = nil
    imported_objects.each do |obj|
      if obj.type == 'SWMM network'
        imported_network = obj
        break
      end
    end
    
    if imported_network
      # Get network statistics
      begin
        net = imported_network.open
        import_stats[:nodes] = net.row_objects('_nodes').length
        import_stats[:links] = net.row_objects('_links').length
        import_stats[:subcatchments] = net.row_objects('_subcatchments').length
        
        log "  Network statistics:", log_file
        log "    Nodes: #{import_stats[:nodes]}", log_file
        log "    Links: #{import_stats[:links]}", log_file
        log "    Subcatchments: #{import_stats[:subcatchments]}", log_file
        
        puts "          Nodes: #{import_stats[:nodes]}, Links: #{import_stats[:links]}, Subs: #{import_stats[:subcatchments]}"
        
        # Update aggregate statistics
        aggregate_stats[:total_nodes] += import_stats[:nodes]
        aggregate_stats[:total_links] += import_stats[:links]
        aggregate_stats[:total_subcatchments] += import_stats[:subcatchments]
        
        # Commit the network
        net.commit("Imported from SWMM5 - #{file_basename}")
        log "  Network committed", log_file
        
      rescue => e
        log "  WARNING: Could not analyze network: #{e.message}", log_file
        puts "          WARNING: Could not get network statistics"
      end
    end
    
    # ========================================================================
    # CLEANUP: Empty label lists
    # ========================================================================
    if cleanup_empty_label_lists
      log "\n  Cleaning up empty label lists...", log_file
      puts "  Step 3: Cleaning up artifacts..."
      
      label_lists_to_delete = []
      
      imported_objects.each do |obj|
        if obj.type == 'Label List'
          cleanup_stats[:label_lists_found] += 1
          log "    Found Label List: #{obj.name}", log_file
          
          if is_label_list_empty?(obj, log_file)
            log "      Empty - will delete", log_file
            label_lists_to_delete << obj
          else
            log "      Has content - keeping", log_file
            cleanup_stats[:label_lists_kept] += 1
          end
        end
      end
      
      if label_lists_to_delete.any?
        log "    Deleting #{label_lists_to_delete.length} empty label list(s)", log_file
        puts "          Removing #{label_lists_to_delete.length} empty label list(s)"
        
        label_lists_to_delete.each do |label_list|
          begin
            label_list.delete
            cleanup_stats[:label_lists_deleted] += 1
            log "      Deleted: #{label_list.name}", log_file
          rescue => e
            log "      ERROR deleting '#{label_list.name}': #{e.message}", log_file
            cleanup_stats[:label_lists_kept] += 1
          end
        end
        
        aggregate_stats[:total_label_lists_deleted] += cleanup_stats[:label_lists_deleted]
        log "    Cleanup complete", log_file
        puts "          Cleanup complete"
      else
        log "    No empty label lists found", log_file
        puts "          No cleanup needed"
      end
    end
    
    # ========================================================================
    # PHASE 2: Validation
    # ========================================================================
    if validate_after_import && imported_network
      log "\n  PHASE 2: Validation", log_file
      puts "  Step 4: Validating..."
      
      begin
        net = imported_network.open
        
        # Check 1: Empty network
        if import_stats[:nodes] == 0 && import_stats[:links] == 0
          warning = "Network is empty (no nodes or links)"
          validation_warnings << warning
          log "    WARNING: #{warning}", log_file
          puts "          WARNING: #{warning}"
        end
        
        # Check 2: Disconnected subcatchments
        if import_stats[:subcatchments] > 0
          disconnected_subs = 0
          net.row_objects('_subcatchments').each do |sub|
            outlet = sub.outlet_id
            if outlet.nil? || outlet.empty?
              disconnected_subs += 1
            end
          end
          
          if disconnected_subs > 0
            warning = "#{disconnected_subs} subcatchment(s) have no outlet"
            validation_warnings << warning
            log "    WARNING: #{warning}", log_file
          end
        end
        
        # Check 3: Unconnected nodes
        connected_nodes = []
        net.row_objects('_links').each do |link|
          connected_nodes << link.us_node_id
          connected_nodes << link.ds_node_id
        end
        connected_nodes.uniq!
        
        unconnected_count = import_stats[:nodes] - connected_nodes.length
        if unconnected_count > 0
          warning = "#{unconnected_count} node(s) not connected to links"
          validation_warnings << warning
          log "    WARNING: #{warning}", log_file
        end
        
        if validation_warnings.empty?
          log "    No validation warnings", log_file
          puts "          Validation passed"
        else
          log "    Found #{validation_warnings.length} warning(s)", log_file
          puts "          Found #{validation_warnings.length} warning(s)"
        end
        
      rescue => e
        log "    ERROR during validation: #{e.message}", log_file
        puts "          ERROR during validation"
      end
    end
    
    # Mark as successful
    aggregate_stats[:files_successful] += 1
    puts "  SUCCESS: Import complete"
    log "\n  Import successful", log_file
    
  rescue => e
    puts "  ERROR: #{e.message}"
    log "\n  ERROR: #{e.message}", log_file
    log "  Backtrace: #{e.backtrace.join("\n  ")}", log_file
    
    # Clean up partial import
    if defined?(model_group) && model_group
      begin
        model_group.delete
        log "  Cleaned up partial import", log_file
      rescue => cleanup_error
        log "  Could not clean up: #{cleanup_error.message}", log_file
      end
    end
    
    aggregate_stats[:files_failed] += 1
    aggregate_stats[:failed_files] << { file: file_basename, reason: e.message }
  end
end

# ============================================================================
# Generate Final Summary
# ============================================================================
log "\n" + "="*70, log_file
log "BATCH IMPORT SUMMARY", log_file
log "="*70, log_file

log "\nImport Mode: #{import_mode}", log_file
log "Files processed: #{aggregate_stats[:files_processed]}", log_file
log "Successful: #{aggregate_stats[:files_successful]}", log_file
log "Failed: #{aggregate_stats[:files_failed]}", log_file

if aggregate_stats[:files_successful] > 0
  log "\nAggregate Statistics:", log_file
  log "  Total nodes: #{aggregate_stats[:total_nodes]}", log_file
  log "  Total links: #{aggregate_stats[:total_links]}", log_file
  log "  Total subcatchments: #{aggregate_stats[:total_subcatchments]}", log_file
  
  if aggregate_stats[:total_label_lists_deleted] > 0
    log "  Label lists cleaned: #{aggregate_stats[:total_label_lists_deleted]}", log_file
  end
end

if aggregate_stats[:failed_files].any?
  log "\nFailed Files:", log_file
  aggregate_stats[:failed_files].each do |failed|
    log "  * #{failed[:file]}: #{failed[:reason]}", log_file
  end
end

log "\n" + "="*70, log_file
log "Batch import completed!", log_file
log "Log file: #{log_filename}", log_file
log "="*70, log_file

log_file.close

# ============================================================================
# Write summary file for UI script
# ============================================================================
summary_file = File.join(log_dir, "batch_summary.txt")
File.open(summary_file, 'w') do |f|
  f.puts "BATCH_IMPORT_SUMMARY"
  f.puts "files_processed=#{aggregate_stats[:files_processed]}"
  f.puts "files_successful=#{aggregate_stats[:files_successful]}"
  f.puts "files_failed=#{aggregate_stats[:files_failed]}"
  f.puts "total_nodes=#{aggregate_stats[:total_nodes]}"
  f.puts "total_links=#{aggregate_stats[:total_links]}"
  f.puts "total_subcatchments=#{aggregate_stats[:total_subcatchments]}"
  f.puts "total_label_lists_deleted=#{aggregate_stats[:total_label_lists_deleted]}"
end

puts "\nSummary file written: #{summary_file}"

# Display final summary
puts ""
puts "+" + "="*68 + "+"
puts "|" + " "*23 + "BATCH IMPORT COMPLETE" + " "*24 + "|"
puts "+" + "="*68 + "+"
puts ""
puts "SUMMARY:"
puts "  Files processed: #{aggregate_stats[:files_processed]}"
puts "  Successful: #{aggregate_stats[:files_successful]}"
puts "  Failed: #{aggregate_stats[:files_failed]}"
puts ""

if aggregate_stats[:files_successful] > 0
  puts "  Total Elements Imported:"
  puts "    * #{aggregate_stats[:total_nodes]} nodes"
  puts "    * #{aggregate_stats[:total_links]} links"
  puts "    * #{aggregate_stats[:total_subcatchments]} subcatchments"
  puts ""
  
  if aggregate_stats[:total_label_lists_deleted] > 0
    puts "  Cleanup:"
    puts "    * #{aggregate_stats[:total_label_lists_deleted]} empty label list(s) removed"
    puts ""
  end
end

if aggregate_stats[:failed_files].any?
  puts "  Failed Files:"
  aggregate_stats[:failed_files].each do |failed|
    puts "    * #{failed[:file]}: #{failed[:reason]}"
  end
  puts ""
end

puts "  Log file: #{log_filename}"
puts "  Summary file: #{summary_file}"
puts "+" + "="*68 + "+"

# Exit with appropriate code
exit(aggregate_stats[:files_failed] > 0 ? 1 : 0)