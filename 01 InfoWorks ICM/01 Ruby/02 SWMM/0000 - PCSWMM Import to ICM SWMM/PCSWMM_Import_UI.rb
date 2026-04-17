# =============================================================================
# PCSWMM to InfoWorks ICM Import Tool - USER INTERFACE
# =============================================================================
# 
# WHAT IT DOES:
#   Imports PCSWMM models (.pcz files) into InfoWorks ICM as SWMM networks
#
# HOW TO RUN:
#   1. Open InfoWorks ICM
#   2. Open your database
#   3. Create a new SWMM network (or open an existing one)
#   4. Open the SWMM network
#   5. Network → Run Ruby Script
#   6. Select: PCSWMM_Import_UI.rb
#   7. Follow the prompts
#
# WHAT YOU'LL SEE:
#   - File picker for your .pcz file
#   - Name prompt for model group
#   - Progress messages
#   - Success/failure dialog with results
#
# REQUIREMENTS:
#   - InfoWorks ICM 2024 or later
#   - PCSWMM_Import_Exchange.rb (must be in same folder)
#   - Valid .pcz file from PCSWMM
#
# OUTPUT:
#   - Model Group with imported SWMM network
#   - Log files: [YourModel]/PCSWMM_Import_*.log
#
# =============================================================================

require 'json'
require 'open3'

# Main import function - handles all user interaction and launches Exchange script
def run_import
  # ============================================================
  # STEP 1: Check database is open and capture connection info
  # ============================================================
  db = WSApplication.current_database
  
  if db.nil?
    WSApplication.message_box(
      "No database is currently open!\n\n" +
      "Please open an InfoWorks ICM database first.",
      "OK",
      "!",
      false
    )
    return
  end
  
  # Capture database GUID and path for Exchange script
  db_guid = db.guid
  db_path = nil
  begin
    # Try common properties that might contain the path
    db_path = db.path if db.respond_to?(:path)
    db_path ||= db.database_path if db.respond_to?(:database_path)
    db_path ||= db.location if db.respond_to?(:location)
    db_path ||= db.file_path if db.respond_to?(:file_path)
  rescue => e
    # Couldn't get path - will rely on GUID check only
  end
  
  script_dir = File.dirname(WSApplication.script_file)
  
  # ============================================================
  # STEP 2: Get .pcz file from user
  # ============================================================
  begin
    pcz_file = WSApplication.file_dialog(
      true,              # open mode
      'pcz',            # extension
      'PCSWMM Model Files (*.pcz)',
      '',               # default filename
      false,            # single file
      nil               # don't exit on cancel
    )
  rescue Interrupt
    # User cancelled - silent exit
    return
  end
  
  # Validate selection
  if pcz_file.nil? || pcz_file.empty?
    # User cancelled - silent exit
    return
  end
  
  # Validate file
  unless File.exist?(pcz_file)
    WSApplication.message_box(
      "File not found:\n#{pcz_file}\n\nImport cancelled.",
      "OK",
      "!",
      false
    )
    return
  end
  
  unless File.extname(pcz_file).downcase == '.pcz'
    WSApplication.message_box(
      "Invalid file type.\n\nPlease select a PCSWMM .pcz file.\n\nImport cancelled.",
      "OK",
      "!",
      false
    )
    return
  end
  
  # ============================================================
  # STEP 3: Get model group name
  # ============================================================
  model_basename = File.basename(pcz_file, '.pcz')
  default_group_name = "PCSWMM - #{model_basename}"
  
  group_name = WSApplication.input_box(
    'Model Group Name',
    'Enter name for imported model group:',
    default_group_name
  )
  
  if group_name.nil? || group_name.strip.empty?
    # User cancelled - silent exit
    return
  end
  
  group_name = group_name.strip
  
  # ============================================================
  # STEP 4: Check for duplicate model group
  # ============================================================
  existing_group = nil
  db.model_object_collection('Model Group').each do |mg|
    if mg.name == group_name
      existing_group = mg
      break
    end
  end
  
  if existing_group
    WSApplication.message_box(
      "Model Group Already Exists\n\n" +
      "A model group named '#{group_name}' already exists.\n\n" +
      "Please delete or rename the existing model group in ICM,\n" +
      "or choose a different name when importing.\n\n" +
      "Import cancelled.",
      "OK",
      "!",
      false
    )
    return
  end
  
  # ============================================================
  # STEP 5: Confirm with user
  # ============================================================
  proceed = WSApplication.message_box(
    "Ready to import PCSWMM model.\n\n" +
    "File: #{File.basename(pcz_file)}\n" +
    "Model Group: #{group_name}\n\n" +
    "Do you want to proceed?",
    "YesNo",
    "?",
    false
  )
  
  if proceed != "Yes"
    # User cancelled - silent exit
    return
  end
  
  # ============================================================
  # STEP 6: Prepare configuration and find Exchange script
  # ============================================================
  
  log_dir = File.dirname(pcz_file)
  config_file = File.join(log_dir, 'pcswmm_import_config.json')
  
  config = {
    'pcz_file' => pcz_file,
    'model_group_name' => group_name,
    'database_guid' => db_guid,
    'database_path' => db_path
  }
  
  begin
    File.open(config_file, 'w') { |f| f.write(JSON.pretty_generate(config)) }
    
    # Verify file was created and has content
    unless File.exist?(config_file) && File.size(config_file) > 0
      raise "Config file was not created properly"
    end
  rescue => e
    WSApplication.message_box(
      "Failed to save configuration file.\n\n" +
      "Error: #{e.message}",
      "OK",
      "!",
      false
    )
    return
  end
  
  ENV['PCSWMM_IMPORT_CONFIG'] = config_file
  
  # Find ICMExchange executable
  icm_exchange = nil
  icm_paths = [
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2027\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Sewer 2027\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Flood 2027\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2027\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2026\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2026\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2025.2\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2025.2\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2025\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2025\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2024.2\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2024.2\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2024\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2024\\ICMExchange.exe"
  ]
  
  icm_paths.each do |path|
    if File.exist?(path)
      icm_exchange = path
      break
    end
  end
  
  if icm_exchange.nil?
    WSApplication.message_box(
      "ERROR: ICMExchange.exe Not Found\n\n" +
      "This script requires ICMExchange.exe to run.\n\n" +
      "Please contact support or modify the script\n" +
      "to specify the correct path to ICMExchange.exe.",
      "OK",
      "!",
      false
    )
    File.delete(config_file) if File.exist?(config_file)
    return
  end
  
  exchange_script = File.join(script_dir, 'PCSWMM_Import_Exchange.rb')
  
  unless File.exist?(exchange_script)
    WSApplication.message_box(
      "Cannot find Exchange script:\n#{exchange_script}\n\n" +
      "Please ensure PCSWMM_Import_Exchange.rb is in the same folder as this script.",
      "OK",
      "!",
      false
    )
    File.delete(config_file) if File.exist?(config_file)
    return
  end
  
  # Quick validation
  if !File.exist?(config_file) || !File.exist?(exchange_script)
    WSApplication.message_box("Configuration error - cannot proceed.", "OK", "!", false)
    return
  end
  
  command = "\"#{icm_exchange}\" \"#{exchange_script}\" /ICM"
  
  # ============================================================
  # STEP 7: Run the import via Exchange script
  # ============================================================
  puts "\n" + "="*70
  puts "  PCSWMM to InfoWorks ICM Import"
  puts "="*70
  puts ""
  puts "Source: #{File.basename(pcz_file)}"
  puts "Target: #{group_name}"
  puts ""
  puts "Running import..."
  puts ""
  
  # Launch Exchange script and wait for completion
  begin
    stdout, stderr, status = Open3.capture3(command)
    status_code = status.exitstatus
    
    # Wait for database and log files to be ready
    sleep(2)
  
  # ============================================================
  # STEP 8: Verify import and display results
  # ============================================================
  
  # Check database to confirm model group was created
  imported_group = nil
  begin
    db.model_object_collection('Model Group').each do |mg|
      if mg.name == group_name
        imported_group = mg
        break
      end
    end
  rescue => e
    puts "Error checking database: #{e.message}"
  end
  
  # Find log files
  pcz_basename = File.basename(pcz_file, '.pcz')
  log_subfolder = File.join(log_dir, pcz_basename)
  
  latest_log = nil
  latest_inp_log = nil
  
  if Dir.exist?(log_subfolder)
    log_pattern = File.join(log_subfolder, "PCSWMM_Import_*.log").gsub('\\', '/')
    inp_pattern = File.join(log_subfolder, "INP_Import_*.txt").gsub('\\', '/')
    
    log_files = Dir.glob(log_pattern)
    latest_log = log_files.max_by { |f| File.mtime(f) }
    
    inp_log_files = Dir.glob(inp_pattern)
    latest_inp_log = inp_log_files.max_by { |f| File.mtime(f) }
  end
    
    # Read log content if available
    log_content = ""
    if latest_log && File.exist?(latest_log)
      begin
        log_content = File.read(latest_log)
      rescue
        # Ignore read errors
      end
    end
    
    # REAL check: Did the model group get created?
    actual_error = imported_group.nil?
    
  # Display results
  if !actual_error
    puts "=" * 70
    puts "IMPORT SUCCESSFUL"
    puts "=" * 70
    puts ""
    
    # Get network name
    network_obj = nil
    network_name = "Unknown"
    
    if imported_group
      begin
        imported_group.children.each do |child|
          if child.type == 'SWMM network'
            network_obj = child
            network_name = child.name
            break
          end
        end
      rescue => e
        puts "Warning: Could not access network: #{e.message}"
      end
    end
    
    # Extract cleanup info from log
    cleanup_count = 0
    if log_content && !log_content.empty?
      cleanup_count = $1.to_i if log_content =~ /Deleted (\d+) empty label/
    end
    
    puts "Model Group: #{group_name}"
    puts "Network:     #{network_name}"
    puts ""
    if cleanup_count > 0
      puts "Post-processing: Removed #{cleanup_count} empty label list(s)"
      puts ""
    end
    puts "The SWMM network has been imported successfully."
    puts "Check the network in your ICM database for full details."
    puts ""
    puts "Log Files:"
    puts "  #{latest_log}" if latest_log
    puts "  #{latest_inp_log}" if latest_inp_log
    puts ""
    puts "=" * 70
    
    # Success message box
    summary_msg = "Import Successful!\n\n"
    summary_msg += "Network: #{network_name}\n\n"
    summary_msg += "The SWMM network has been imported to:\n#{group_name}\n\n"
    summary_msg += "Open the network in ICM to view nodes, links, and subcatchments."
    
    WSApplication.message_box(summary_msg, "OK", "Information", false)
      
  else
    puts "=" * 70
    puts "IMPORT FAILED"
    puts "=" * 70
    puts ""
    
    # Extract error from log
    error_detail = "Model group was not created in the database."
    if log_content && !log_content.empty?
      if log_content =~ /ERROR: (.+?)(?:\n|$)/m
        error_detail = $1.strip
      end
    end
    
    puts "Error: #{error_detail}"
    puts ""
    
    if latest_log
      puts "Check log file for details:"
      puts "  #{latest_log}"
    end
    if latest_inp_log
      puts "  #{latest_inp_log}"
    end
    if !latest_log && !latest_inp_log
      puts "No log files were created."
    end
    
    puts ""
    puts "=" * 70
    
    # Error message box
    error_msg = "Import Failed\n\n"
    error_msg += "#{error_detail}\n\n"
    
    if latest_log
      error_msg += "Check log file for details:\n#{File.basename(latest_log)}"
    else
      error_msg += "No log file was created."
    end
    
    WSApplication.message_box(error_msg, "OK", "!", false)
  end
    
  rescue => e
    puts ""
    puts "=" * 70
    puts "UNEXPECTED ERROR"
    puts "=" * 70
    puts ""
    puts "#{e.message}"
    puts ""
    puts "=" * 70
    
    WSApplication.message_box(
      "Unexpected Error\n\n#{e.message}",
      "OK",
      "!",
      false
    )
  ensure
    # Always cleanup config file
    begin
      File.delete(config_file) if config_file && File.exist?(config_file)
    rescue
      # Silently ignore cleanup errors
    end
  end
  
end

# Run the import
run_import
