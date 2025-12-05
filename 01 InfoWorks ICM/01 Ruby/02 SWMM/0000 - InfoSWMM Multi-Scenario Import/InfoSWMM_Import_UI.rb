# ============================================================================
# InfoSWMM Multi-Scenario Import - UI SCRIPT
# ============================================================================
# 
# DESCRIPTION:
#   User interface script for importing multiple InfoSWMM scenarios into ICM.
#   Collects user input and launches the Exchange script for processing.
#
# FEATURES:
#   - Import multiple scenarios simultaneously
#   - Content-based deduplication of Rainfall & Inflow Events
#   - Automatic label list cleanup
#   - Creates merged network with all scenarios
#   - Sets up SWMM runs (partial - timesteps/climatology require manual config)
#   - Sequential naming: "Rainfall Event 01", "Inflow 01", etc.
#   - Tracks scenario usage in object Description fields
#
# USAGE:
#   1. Close InfoSWMM (if model is open)
#   2. Open ICM database
#   3. Network → Run Ruby Script → Select this file
#   4. Follow prompts to select .mxd file and scenarios
#   5. Wait for completion
#   6. Manually configure timesteps, climatology, time patterns in runs
#
# OUTPUT:
#   - Individual model groups (one per scenario) - keep for reference
#   - Merged model group with deduplicated objects and partial runs
#   - Log files in [YourModel]/ICM Import Log Files/
#
# REQUIREMENTS:
#   - InfoWorks ICM 2023.2+ (tested with 2026.2)
#   - InfoSWMM .mxd file with .ISDB folder
#   - BASE scenario recommended
#
# ============================================================================

require 'yaml'

# Get the script directory
script_dir = File.dirname(WSApplication.script_file)

# ============================================================================
# Main execution with error handling
# ============================================================================
catch :cancel_import do
begin

# ----------------------------------------------------------------------------
# STEP 1: Get InfoSWMM model file using file dialog
# ----------------------------------------------------------------------------
WSApplication.message_box(
  "InfoSWMM Multi-Scenario Import\n\n" +
  "This script will:\n" +
  "  * Import each scenario to a separate group\n" +
  "  * Clean up empty label lists\n" +
  "  * Deduplicate Rainfall Events & Inflows\n" +
  "  * Create a merged network with all scenarios\n" +
  "  * Set up SWMM runs (partial configuration)\n\n" +
  "You will need to manually configure:\n" +
  "  [!] Timesteps, Climatology, Time Patterns, Inflows\n\n" +
  "Select your InfoSWMM .mxd file next.",
  "OK",
  "Information",
  false
)

file_path = WSApplication.file_dialog(
  true,                          # open (not save)
  'mxd',                         # extension
  'InfoSWMM Model File',         # description
  '',                            # default filename
  false,                         # single file (not multiple)
  nil                            # don't exit on cancel
)

# Check if user cancelled
if file_path.nil?
  WSApplication.message_box(
    "Import cancelled - no file selected.",
    "OK",
    "!",
    false
  )
  throw :cancel_import
end

# ----------------------------------------------------------------------------
# Check for InfoSWMM lock files
# ----------------------------------------------------------------------------
mxd_dir = File.dirname(file_path)
mxd_basename = File.basename(file_path, '.mxd')
lock_files = []

begin
  if Dir.exist?(mxd_dir)
    # Get all entries in the directory
    entries = Dir.entries(mxd_dir)
    
    # Filter for lock files (start with ~)
    lock_entries = entries.select { |entry| entry.start_with?('~') && entry != '~' }
    
    if lock_entries.any?
      # Build full paths
      lock_files = lock_entries.map { |entry| File.join(mxd_dir, entry) }
      
      # Verify they exist (not just directory artifacts)
      lock_files = lock_files.select { |f| File.exist?(f) }
    end
  end
rescue => e
  # Silent error handling
end

# Check ISDB folder for lock files
possible_isdb_folders = [
  File.join(mxd_dir, "#{mxd_basename}.ISDB"),
  File.join(mxd_dir, "ISDB"),
  File.join(mxd_dir, "#{mxd_basename}.isdb"),
  File.join(mxd_dir, "isdb")
]

possible_isdb_folders.each do |isdb_path|
  next unless Dir.exist?(isdb_path)
  
  begin
    entries = Dir.entries(isdb_path)
    lock_entries = entries.select { |entry| entry.start_with?('~') && entry != '~' }
    
    if lock_entries.any?
      isdb_locks = lock_entries.map { |entry| File.join(isdb_path, entry) }
      isdb_locks = isdb_locks.select { |f| File.exist?(f) }
      lock_files.concat(isdb_locks)
    end
  rescue => e
    # Silent error handling
  end
end

if lock_files.any?
  lock_file_paths = lock_files.join("\n")
  
  WSApplication.message_box(
    "InfoSWMM is open or has a residual lock file.\n\n" +
    "Lock file(s):\n" +
    "#{lock_file_paths}\n\n" +
    "Close InfoSWMM or delete the lock file, then run this script again.",
    "OK",
    "!",
    false
  )
  throw :cancel_import
end

puts "\n" + "="*70
puts " InfoSWMM Multi-Scenario Import"
puts "="*70
puts "Model: #{File.basename(file_path, '.*')}"

# ----------------------------------------------------------------------------
# STEP 2: Read actual scenario names from SCENARIO.DBF
# ----------------------------------------------------------------------------

# Try different possible ISDB folder names
possible_isdb_folders = [
  File.join(mxd_dir, "#{mxd_basename}.ISDB"),
  File.join(mxd_dir, "ISDB"),
  File.join(mxd_dir, "#{mxd_basename}.isdb"),
  File.join(mxd_dir, "isdb")
]

scenario_names = []
isdb_folder = nil

# Find the ISDB folder
possible_isdb_folders.each do |folder|
  folder_name = File.basename(folder)
  next if folder_name.start_with?('~')  # Skip lock files
  
  if Dir.exist?(folder)
    isdb_folder = folder
    puts "Found ISDB folder: #{isdb_folder}"
    break
  end
end

if isdb_folder
  scenario_dbf = File.join(isdb_folder, "SCENARIO.DBF")
  scenario_dbf = File.join(isdb_folder, "Scenario.dbf") unless File.exist?(scenario_dbf)
  
  if File.exist?(scenario_dbf)
    begin
      # Read DBF file to get scenario names
      File.open(scenario_dbf, 'rb') do |file|
        # Read DBF header
        version = file.read(1)
        raise "File is empty or unreadable" if version.nil?
        
        last_update = file.read(3)
        num_records_bytes = file.read(4)
        header_length_bytes = file.read(2)
        record_length_bytes = file.read(2)
        
        raise "DBF header is incomplete" if num_records_bytes.nil? || header_length_bytes.nil? || record_length_bytes.nil?
        
        num_records = num_records_bytes.unpack('V')[0]
        header_length = header_length_bytes.unpack('v')[0]
        record_length = record_length_bytes.unpack('v')[0]
        
        file.read(20)  # Reserved
        
        # Read field descriptors
        fields = []
        field_offset = 1  # First byte is delete flag
        
        loop do
          field_name_bytes = file.read(11)
          break if field_name_bytes.nil? || field_name_bytes[0] == "\r" || field_name_bytes[0] == "\x0D"
          
          field_name = field_name_bytes.unpack('Z11')[0]
          break if field_name.nil? || field_name.empty?
          
          field_type = file.read(1)
          file.read(4)  # Reserved
          field_length = file.read(1).unpack('C')[0]
          file.read(15)  # Decimals + reserved
          
          fields << {
            name: field_name.strip,
            type: field_type,
            offset: field_offset,
            length: field_length
          }
          
          field_offset += field_length
        end
        
        # Find the ID field
        id_field = fields.find { |f| ['ID', 'SCEN_ID', 'NAME', 'SCENID'].include?(f[:name].upcase) }
        
        if id_field.nil?
      WSApplication.message_box(
        "ERROR: Cannot read scenario names\n\n" +
        "Could not find ID field in SCENARIO.DBF.\n\n" +
        "Fields found:\n" +
        fields.map { |f| "  - #{f[:name]}" }.join("\n") + "\n\n" +
        "You will need to enter scenario names manually.",
        "OK",
        "!",
        false
      )
        else
          # Skip to data records
          file.seek(header_length)
          
          # Read each record
          num_records.times do
            record = file.read(record_length)
            next if record.nil? || record[0] == '*'  # Skip deleted records
            
            # Extract ID field value
            id_value = record[id_field[:offset], id_field[:length]].strip
            scenario_names << id_value unless id_value.empty?
          end
        end
      end
      
      if scenario_names.any?
        puts "Found #{scenario_names.length} scenario(s) in model"
      end
      
    rescue => e
      puts "Warning: Could not auto-detect scenarios (#{e.message})"
      
      WSApplication.message_box(
        "Could not read SCENARIO.DBF file.\n\n" +
        "Error: #{e.message}\n\n" +
        "Will use manual entry instead.",
        "OK",
        "!",
        false
      )
    end
  else
    puts "Warning: SCENARIO.DBF not found"
  end
else
  puts "Warning: ISDB folder not found next to model file"
end

# ----------------------------------------------------------------------------
# STEP 3: Prompt for scenario selection
# ----------------------------------------------------------------------------
if scenario_names.any?
  # Separate BASE from other scenarios (BASE is required and will be added automatically)
  base_scenario = scenario_names.find { |s| s.upcase == 'BASE' }
  other_scenarios = scenario_names.reject { |s| s.upcase == 'BASE' }
  
  # Build prompt with checkboxes for each scenario (excluding BASE)
  layout = [
    ['BASE imported automatically', 'READONLY', ''],
    ['', 'READONLY', ''],  # Blank line
    ['Select additional scenarios:', 'READONLY', ''],
    ['Select All', 'BOOLEAN', false]  # Select all checkbox (unchecked by default)
  ]
  
  other_scenarios.each do |scenario|
    layout << [scenario, 'BOOLEAN', false]  # Default to unchecked
  end
  
  result = WSApplication.prompt(
    'Select Scenarios to Import',
    layout,
    false  # don't exit on cancel
  )
  
  # Check if user cancelled
  if result.nil?
    WSApplication.message_box(
      "Import cancelled - no scenarios selected.",
      "OK",
      "!",
      false
    )
    throw :cancel_import
  end
  
  # Check if "Select All" is checked
  select_all = result[3]  # Now at index 3 (after 2 READONLY lines + blank line)
  
  # Collect selected scenarios (excluding BASE which is handled separately)
  selected_scenarios = []
  other_scenarios.each_with_index do |scenario, index|
    # +4 to skip the 3 READONLY lines and "Select All" checkbox
    if select_all || result[index + 4]
      selected_scenarios << scenario
    end
  end
  
  # Always add BASE automatically (it's required for merging)
  if base_scenario
    selected_scenarios.unshift(base_scenario)  # Add BASE at the beginning
    puts "BASE will be imported automatically"
  else
    # No BASE scenario found - warn user but continue
    puts "WARNING: No BASE scenario found in model"
    puts "The first selected scenario will be used as the master network"
  end
  
  # Check if any additional scenarios were selected (BASE is already included)
  if selected_scenarios.length == 1 && selected_scenarios.first&.upcase == 'BASE'
    puts "Only BASE scenario selected"
    WSApplication.message_box(
      "Only BASE Scenario Selected\n\n" +
      "You haven't selected any additional scenarios.\n\n" +
      "This script is designed to merge multiple scenarios.\n" +
      "With only BASE, you'll get a single network.\n\n" +
      "Continue with only BASE?",
      "YesNo",
      "?",
      false
    )
    # User chose No
    if WSApplication.message_box_return_value == "No"
      throw :cancel_import
    end
  end
  
  scenario_input = selected_scenarios.join(',')
  puts "Importing #{selected_scenarios.length} scenario(s)"
  
else
  # Fallback to manual entry if DBF couldn't be read
  layout = [
    ['Could not auto-detect scenarios.', 'READONLY', 'Enter scenario names manually'],
    ['Scenarios', 'STRING', '', nil]
  ]
  
  result = WSApplication.prompt(
    'Enter Scenarios Manually',
    layout,
    false  # don't exit on cancel
  )
  
  # Check if user cancelled
  if result.nil?
    WSApplication.message_box(
      "Import cancelled - no scenarios entered.",
      "OK",
      "!",
      false
    )
    throw :cancel_import
  end
  
  scenario_input = result[1].strip
  
  if scenario_input.empty?
    puts "No scenarios entered"
    WSApplication.message_box(
      "No scenarios entered. Import cancelled.",
      "OK",
      "!",
      false
    )
    throw :cancel_import
  end
  
  scenario_count = scenario_input.split(',').length
  puts "Importing #{scenario_count} scenario(s)"
end

puts "="*70

# ----------------------------------------------------------------------------
# STEP 4: Verify BASE scenario is included
# ----------------------------------------------------------------------------
scenarios_list = scenario_input.split(',').map(&:strip)
unless scenarios_list.any? { |s| s.upcase == 'BASE' }
  result = WSApplication.message_box(
    "WARNING: No BASE Scenario Found\n\n" +
    "The merged network needs a BASE scenario\n" +
    "to use as the master network.\n\n" +
    "Without BASE, the first selected scenario\n" +
    "will be used as the master.\n\n" +
    "Continue anyway?",
    "YesNo",
    "!",
    false
  )
  
  if result == "No"
    puts "\nImport cancelled - BASE scenario required for merging"
    throw :cancel_import
  end
end

# ----------------------------------------------------------------------------
# STEP 5: Get database path for Exchange script
# ----------------------------------------------------------------------------
db = WSApplication.current_database
db_guid = db.guid

# ----------------------------------------------------------------------------
# Save configuration for Exchange script
# ----------------------------------------------------------------------------
model_dir = File.dirname(file_path)
config_folder = File.join(model_dir, "ICM Import Log Files")
Dir.mkdir(config_folder) unless Dir.exist?(config_folder)

config = {
  'file_path' => file_path,
  'scenarios' => scenario_input,
  'database_guid' => db_guid,
  'timestamp' => Time.now.to_s,
  'merge_scenarios' => true,
  'cleanup_empty_label_lists' => true,
  'copy_swmm_runs' => true
}

config_file = File.join(config_folder, 'import_config.yaml')
File.open(config_file, 'w') { |f| f.write(config.to_yaml) }

# ----------------------------------------------------------------------------
# STEP 7: Launch Exchange script
# ----------------------------------------------------------------------------
exchange_script = File.join(script_dir, 'InfoSWMM_Import_Exchange.rb')

# Pass config file location to Exchange script via environment variable
ENV['ICM_IMPORT_CONFIG'] = config_file

# Find ICMExchange.exe
icm_exchange = nil
[
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2026\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Sewer 2026\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Flood 2026\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM 2026\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2025.2\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM 2025.2\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2025\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM 2025\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2024.2\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM 2024.2\\ICMExchange.exe"
].each do |path|
  if File.exist?(path)
    icm_exchange = path
    break
  end
end

if icm_exchange.nil?
  WSApplication.message_box(
    "ERROR: ICMExchange.exe Not Found\n\n" +
    "This script requires ICMExchange.exe to run.\n\n" +
    "Please install InfoWorks ICM or edit the script\n" +
    "to specify the correct path to ICMExchange.exe.",
    "OK",
    "!",
    false
  )
  throw :cancel_import
end

# Launch Exchange script (capture output for summary)
command = "\"#{icm_exchange}\" \"#{exchange_script}\" /ICM"

# Capture the console output
require 'open3'
output, status = Open3.capture2(command)
success = status.success?

# Parse the console output to extract statistics
scenarios_imported = output.match(/Phase 1: (\d+) scenario\(s\) imported successfully/)
label_lists_cleaned = output.match(/(\d+) empty label list\(s\) cleaned up/)
duplicates_skipped = output.match(/Phase 1\.5: (\d+) duplicate Rainfall Event/)
merged_created = output.match(/Phase 2: Merged network created with (\d+) scenario/)
swmm_runs_created = output.match(/Phase 2\.5: (\d+) SWMM run\(s\) created/)

# Get log directory path
log_dir = File.join(File.dirname(file_path), "ICM Import Log Files")

# Display summary in console
puts "\n" + "="*70
puts " IMPORT SUMMARY"
puts "="*70
puts ""

if scenarios_imported
  puts "PHASE 1: Individual Scenario Import"
  puts "  * #{scenarios_imported[1]} scenario(s) imported to separate groups"
  if label_lists_cleaned
    puts "  * #{label_lists_cleaned[1]} empty label list(s) cleaned up"
  end
  puts ""
end

if duplicates_skipped && duplicates_skipped[1].to_i > 0
  puts "PHASE 1.5: Object Deduplication"
  puts "  * #{duplicates_skipped[1]} duplicate Rainfall Event(s) detected"
  puts "  * Only unique events copied to merged network"
  puts ""
end

if merged_created
  puts "PHASE 2: Merged Network Creation"
  puts "  * Master network created from BASE scenario"
  puts "  * #{merged_created[1]} scenario(s) combined into one network"
  puts "  * Inactive elements removed from each scenario"
  puts ""
end

if swmm_runs_created
  puts "PHASE 2.5: SWMM Run Setup"
  puts "  * #{swmm_runs_created[1]} SWMM run(s) configured in merged network"
  puts "  * All run parameters preserved from individual networks"
  puts "  * Linked to appropriate climatology, time patterns, and rainfall"
  puts ""
end

puts "SCENARIOS IMPORTED:"
selected_scenarios.each do |scenario|
  puts "  * #{scenario}"
end

puts ""
puts "LOG FILES:"
puts "  #{log_dir}"
puts ""
puts "CREATED MODEL GROUPS:"
puts "  * Individual: One group per scenario"
puts "  * Merged: '#{File.basename(file_path, '.*')} - Merged Scenarios'"
puts ""
puts "="*70

# Show completion message based on results
if success
  summary = "Import Complete!\n\n"
  
  if scenarios_imported
    summary += "Imported: #{scenarios_imported[1]} scenario(s)\n"
    if label_lists_cleaned && label_lists_cleaned[1].to_i > 0
      summary += "Cleaned: #{label_lists_cleaned[1]} label list(s)\n"
    end
  else
    # Fallback if regex didn't match
    summary += "Imported: #{selected_scenarios.length} scenario(s)\n"
  end
  
  if duplicates_skipped && duplicates_skipped[1].to_i > 0
    summary += "Deduplicated: #{duplicates_skipped[1]} Rainfall Event(s)\n"
  end
  
  if merged_created
    summary += "Merged: #{merged_created[1]} scenario(s)\n"
  end
  
  if swmm_runs_created
    summary += "SWMM Runs: #{swmm_runs_created[1]} configured\n"
  end
  
  summary += "\nSee Ruby output window for full details.\n"
  summary += "Logs: ICM Import Log Files folder"
  
  WSApplication.message_box(
    summary,
    "OK",
    "Information",
    false
  )
else
  WSApplication.message_box(
    "Import Failed\n\n" +
    "Check the Ruby output window for details.\n\n" +
    "Logs: ICM Import Log Files folder",
    "OK",
    "Warning",
    false
  )
end

rescue SystemExit, Interrupt
  # Allow intentional exits and interrupts to pass through silently
  raise
rescue => e
  # Handle any unexpected errors
  puts "\n" + "="*70
  puts "FATAL ERROR"
  puts "="*70
  puts "Error: #{e.class} - #{e.message}"
  puts "\nStack trace:"
  puts e.backtrace.first(10).join("\n")
  puts "="*70
  
  WSApplication.message_box(
    "An unexpected error occurred:\n\n" +
    "#{e.message}\n\n" +
    "Check the Ruby output window for details.",
    "OK",
    "!",
    false
  )
end
end  # catch :cancel_import


