# ============================================================================
# SWMM5 Import WITH CLEANUP - EXCHANGE SCRIPT (Version 3 - Refactored & Enhanced)
# ============================================================================
# 
# WHAT THIS SCRIPT DOES:
#   Processes SWMM5 .inp files via ICMExchange, importing them into ICM SWMM Networks.
#   
#   Phases: Import -> Cleanup (sw_label) -> Validation -> Reporting
#
# NEW IN VERSION 3:
#   - Refactored into functional components.
#   - Implemented cleanup of empty visualization labels (sw_label table).
#   - Enhanced validation logic (accurate connectivity checks).
#   - Added performance timing metrics.
#   - Uses Ruby Logger for structured log files.
#
# RUNS AUTOMATICALLY:
#   Launched by the UI script. Reads configuration via ENV['ICM_IMPORT_CONFIG'].
#
# ============================================================================

require 'yaml'
require 'logger'
require 'fileutils'
require 'set'

# ----------------------------------------------------------------------------
# Global State and Helpers
# ----------------------------------------------------------------------------

$script_logger = nil
$aggregate_stats = {
  files_processed: 0,
  files_successful: 0,
  files_failed: 0,
  total_nodes: 0,
  total_links: 0,
  total_subcatchments: 0,
  total_labels_cleaned: 0,
  total_import_time: 0.0,
  failed_files: []
}

# Dual logging: Console (simple) and File (structured)
def log(message, level = :info)
  # Output to console (ICMExchange stdout) for live streaming
  puts "[#{Time.now.strftime('%H:%M:%S')}] #{message}"
  # Output to log file
  $script_logger.send(level, message) if $script_logger
end

def time_it
  start_time = Time.now
  yield
  Time.now - start_time
end

# ----------------------------------------------------------------------------
# Initialization and Configuration
# ----------------------------------------------------------------------------
def initialize_script
  # Load configuration strictly from the environment variable
  config_file = ENV['ICM_IMPORT_CONFIG']
  unless config_file && File.exist?(config_file)
    puts "ERROR: Configuration file not found via ICM_IMPORT_CONFIG. Run the UI script first."
    exit 1
  end

  begin
    config = YAML.load_file(config_file)
  rescue => e
    puts "ERROR: Failed to parse configuration file: #{e.message}"
    exit 1
  end

  # Setup Logging
  log_dir = File.join(config['base_directory'], "ICM Import Log Files")
  FileUtils.mkdir_p(log_dir)

  log_filename = File.join(log_dir, "SWMM5_Batch_Import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
  
  $script_logger = Logger.new(log_filename)
  $script_logger.formatter = proc do |severity, datetime, progname, msg|
    "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
  end

  # Open Database
  begin
    db = WSApplication.open
  rescue => e
    log "Error opening database: #{e.message}", :error
    exit 1
  end

  log "="*70
  log "SWMM5 Import to ICM (V3) - Exchange Script Initialized"
  log "="*70
  log "Database GUID: #{db.guid}"
  log "Files to process: #{config['file_configs'].length}"

  { config: config, db: db, log_dir: log_dir, log_filename: log_filename }
end

# ----------------------------------------------------------------------------
# Phase 1: Import File
# ----------------------------------------------------------------------------
def import_file(db, file_path, network_name, log_dir)
  log "PHASE 1: Importing SWMM5 data"
  network = nil

  # 1. Create Network Object
  begin
    # Explicitly creating 'SWMM network' type
    network = db.new_model_object('SWMM network', network_name)
    log "  Network object created (ID: #{network.id})"
  rescue => e
    # Handle duplicate names robustly
    if e.message.include?("already exists") || e.message.include?("Name is not unique")
      raise "Network '#{network_name}' already exists (Duplicate name)"
    else
      raise "Failed to create network object: #{e.message}"
    end
  end

  # 2. Import Data
  import_log_path = File.join(log_dir, "#{File.basename(file_path, '.inp')}_ImportLog_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")
  net = network.open
  
  import_success = false
  import_time = time_it do
    # Import using the "inp" driver for SWMM5 into SWMM networks
    # Ensuring path format is compatible (ICM API often prefers Windows paths)
    import_success = net.import_ex(
        file_path.gsub('/', '\\'), 
        "inp", 
        nil, 
        import_log_path.gsub('/', '\\')
    )
  end

  $aggregate_stats[:total_import_time] += import_time
  log "  Import duration: #{sprintf('%.2f', import_time)}s"

  # 3. Handle Failure
  unless import_success
    log "  Import process reported failure. Check log: #{import_log_path}", :error
    # Dump import log contents to main log
    if File.exist?(import_log_path)
        log "  --- Import Log Contents (First 100 lines) ---", :warn
        File.foreach(import_log_path).with_index do |line, i|
            log "    > #{line.strip}", :warn
            break if i >= 100
        end
        log "  ---------------------------------------------", :warn
    end
    raise "Import failed"
  end

  log "  SUCCESS: Import completed."
  { net: net, network_obj: network }
end

# ----------------------------------------------------------------------------
# Phase 2: Cleanup (sw_label)
# ----------------------------------------------------------------------------
def cleanup_visualization_labels(net)
  log "PHASE 2: Cleaning up empty visualization labels (sw_label)"
  
  # In SWMM networks, visualization labels are stored in 'sw_label'.
  table_name = 'sw_label'
  
  unless net.table_exists?(table_name)
    return 0
  end
  
  labels = net.row_objects(table_name)
  if labels.empty?
    return 0
  end
  
  log "  Found #{labels.length} labels. Analyzing for empty content..."
  deleted_count = 0
  
  # Use transaction for safe deletion
  net.transaction_begin
  begin
    labels.each do |label|
      # Check the 'label' field content
      content = label.label
      if content.nil? || content.strip.empty?
        label.delete
        deleted_count += 1
      end
    end
    net.transaction_commit
    log "  SUCCESS: Deleted #{deleted_count} empty labels."
  rescue => e
    net.transaction_rollback
    log "  ERROR during label cleanup: #{e.message}. Transaction rolled back.", :error
    return 0
  end
  
  deleted_count
end

# ----------------------------------------------------------------------------
# Phase 3: Validation and Statistics
# ----------------------------------------------------------------------------
def validate_and_report(net)
  log "PHASE 3: Validation and Statistics"
  stats = { nodes: 0, links: 0, subcatchments: 0 }
  warnings = []

  begin
    nodes = net.row_objects('_nodes')
    links = net.row_objects('_links')
    subcatchments = net.row_objects('_subcatchments')

    stats[:nodes] = nodes.length
    stats[:links] = links.length
    stats[:subcatchments] = subcatchments.length

    log "  Statistics: Nodes=#{stats[:nodes]}, Links=#{stats[:links]}, Subs=#{stats[:subcatchments]}"

    # Check 1: Empty network
    if stats[:nodes] == 0 && stats[:links] == 0
      warnings << "Network is empty"
    end

    # Check 2: Disconnected subcatchments
    disconnected_subs = 0
    subcatchments.each do |sub|
      # Check both node_id and subcatchment_id for connection in SWMM networks
      if (sub.node_id.nil? || sub.node_id.empty?) && (sub.subcatchment_id.nil? || sub.subcatchment_id.empty?)
          disconnected_subs += 1
      end
    end
    if disconnected_subs > 0
      warnings << "#{disconnected_subs} subcatchment(s) have no outlet (node or subcatchment)"
    end

    # Check 3: Unconnected nodes (Islanding) - Comprehensive and Robust Check
    connected_nodes = Set.new
    
    # Nodes connected by links
    links.each do |link|
      connected_nodes.add(link.us_node_id) if link.us_node_id && !link.us_node_id.empty?
      connected_nodes.add(link.ds_node_id) if link.ds_node_id && !link.ds_node_id.empty?
    end
    
    # Nodes connected as subcatchment outlets
    subcatchments.each do |sub|
      # We only care if it connects to a node here (sub-to-sub connections don't count for node connectivity)
      connected_nodes.add(sub.node_id) if sub.node_id && !sub.node_id.empty?
    end

    all_node_ids = Set.new
    nodes.each { |node| all_node_ids.add(node.id) }

    # Calculate the difference
    unconnected_nodes = all_node_ids - connected_nodes
    if unconnected_nodes.any?
      examples = unconnected_nodes.to_a.take(5).join(', ')
      warnings << "#{unconnected_nodes.size} node(s) are unconnected (Islands). Examples: #{examples}"
    end

    if warnings.any?
      log "  Validation finished with #{warnings.length} warning(s):", :warn
      warnings.each { |w| log "    * #{w}", :warn }
    else
      log "  Validation passed with no warnings."
    end

  rescue => e
    log "  ERROR during validation/statistics analysis: #{e.message}", :error
  end
  
  stats
end

# ----------------------------------------------------------------------------
# Main Processing Loop
# ----------------------------------------------------------------------------
def main_process_loop(init_data)
  config = init_data[:config]
  db = init_data[:db]
  log_dir = init_data[:log_dir]
  file_configs = config['file_configs']

  log "\n" + "="*70
  log "BATCH PROCESSING STARTING"
  log "="*70

  file_configs.each_with_index do |file_config, index|
    file_basename = file_config['file_basename']
    file_path = file_config['file_path']
    network_name = file_config['network_name']

    log "\n" + "-"*70
    log "[#{index + 1}/#{file_configs.length}] Processing: #{file_basename}"
    log "-"*70

    $aggregate_stats[:files_processed] += 1
    network_obj = nil

    begin
      # Input Validation
      raise "File not found" unless File.exist?(file_path)

      # Phase 1: Import
      import_result = import_file(db, file_path, network_name, log_dir)
      net = import_result[:net]
      network_obj = import_result[:network_obj]

      # Phase 2: Cleanup
      labels_cleaned = 0
      if config['cleanup_empty_label_lists']
        labels_cleaned = cleanup_visualization_labels(net)
      end

      # Phase 3: Validation
      import_stats = {}
      if config['validate_after_import']
        import_stats = validate_and_report(net)
      end

      # Finalize: Commit
      commit_message = "Imported SWMM5: #{file_basename}."
      commit_message += " (Cleaned #{labels_cleaned} empty labels)" if labels_cleaned > 0
      
      net.commit(commit_message)
      log "Network committed."

      # Update Stats on Success
      $aggregate_stats[:files_successful] += 1
      $aggregate_stats[:total_nodes] += import_stats[:nodes] || 0
      $aggregate_stats[:total_links] += import_stats[:links] || 0
      $aggregate_stats[:total_subcatchments] += import_stats[:subcatchments] || 0
      $aggregate_stats[:total_labels_cleaned] += labels_cleaned

      log "SUCCESS: #{file_basename}"

    rescue => e
      # Error Handling
      log "FAILURE: Failed to process #{file_basename}. Reason: #{e.message}", :error
      $script_logger.error("Backtrace:\n#{e.backtrace.join("\n")}") if $script_logger
      
      $aggregate_stats[:files_failed] += 1
      $aggregate_stats[:failed_files] << { file: file_basename, reason: e.message }

      # Cleanup partial import if network object exists
      if network_obj
        begin
          # Check if the object still exists (by name, as ID might be unreliable if creation failed partially)
          if db.find_model_object('SWMM network', network_name)
            log "Attempting to delete partially processed network '#{network_name}'..."
            network_obj.delete
            log "Successfully deleted network object."
          end
        rescue => cleanup_error
          log "Could not delete network object during cleanup: #{cleanup_error.message}", :error
        end
      end
    end
  end
end

# ----------------------------------------------------------------------------
# Summary Generation
# ----------------------------------------------------------------------------
def generate_summary(init_data, duration)
  log_dir = init_data[:log_dir]

  log "\n" + "="*70
  log "BATCH IMPORT SUMMARY"
  log "="*70
  log "Total duration: #{sprintf('%.2f', duration)}s"
  log "Files processed: #{$aggregate_stats[:files_processed]}"
  log "Successful: #{$aggregate_stats[:files_successful]}"
  log "Failed: #{$aggregate_stats[:files_failed]}"

  if $aggregate_stats[:files_successful] > 0
    log "\nAggregate Statistics:"
    log "  Nodes: #{$aggregate_stats[:total_nodes]}"
    log "  Links: #{$aggregate_stats[:total_links]}"
    log "  Subcatchments: #{$aggregate_stats[:total_subcatchments]}"
    log "  Empty Labels Cleaned: #{$aggregate_stats[:total_labels_cleaned]}"

    log "\nPerformance Metrics:"
    avg_import = $aggregate_stats[:total_import_time] / $aggregate_stats[:files_successful]
    log "  Total Import Time: #{sprintf('%.2f', $aggregate_stats[:total_import_time])}s (Avg: #{sprintf('%.2f', avg_import)}s)"
  end

  if $aggregate_stats[:failed_files].any?
    log "\nFailed Files:", :warn
    $aggregate_stats[:failed_files].each do |failed|
      log "  * #{failed[:file]}: #{failed[:reason]}", :warn
    end
  end

  # Write summary file for UI script
  summary_file = File.join(log_dir, "batch_summary.txt")
  begin
    File.open(summary_file, 'w') do |f|
        f.puts "BATCH_IMPORT_SUMMARY"
        f.puts "files_processed=#{$aggregate_stats[:files_processed]}"
        f.puts "files_successful=#{$aggregate_stats[:files_successful]}"
        f.puts "files_failed=#{$aggregate_stats[:files_failed]}"
        f.puts "total_nodes=#{$aggregate_stats[:total_nodes]}"
        f.puts "total_links=#{$aggregate_stats[:total_links]}"
        f.puts "total_subcatchments=#{$aggregate_stats[:total_subcatchments]}"
        f.puts "total_labels_cleaned=#{$aggregate_stats[:total_labels_cleaned]}"
        f.puts "total_duration=#{sprintf('%.2f', duration)}"
    end
  rescue => e
    log "ERROR: Failed to write summary file: #{e.message}", :error
  end
end

# ============================================================================
# Script Execution
# ============================================================================
start_time = Time.now
init_data = nil
begin
  init_data = initialize_script
  main_process_loop(init_data)
rescue => e
  log "A critical error occurred during execution: #{e.message}", :fatal
  log e.backtrace.join("\n"), :fatal
ensure
  duration = Time.now - start_time
  generate_summary(init_data, duration) if init_data
  $script_logger.close if $script_logger
end

# Exit with appropriate code
exit($aggregate_stats[:files_failed] > 0 ? 1 : 0)