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
#   - Creates merged network with all scenarios and scenario-variable data
#   - Sets up SWMM runs (network/scenario/rainfall auto-configured)
#   - Sequential naming: "Rainfall Event 01", "Inflow 01", etc.
#   - Tracks scenario usage in object Description fields
#   - Works with multiple ICM versions open simultaneously
#
# USAGE:
#   1. Close InfoSWMM (if model is open)
#   2. Open ICM database
#   3. Network → Run Ruby Script → Select this file
#   4. Follow prompts to select .mxd file and scenarios
#   5. Wait for completion
#   6. Manually configure: timesteps, climatology, time patterns, inflows in runs
#
# OUTPUT:
#   - Individual model groups (one per scenario) - keep for reference
#   - Merged model group with deduplicated objects and partial runs
#   - Log files in [YourModel]/ICM Import Log Files/
#
# REQUIREMENTS:
#   - InfoSWMM .mxd file with .ISDB folder
#
# ============================================================================

require 'json'

# ----------------------------------------------------------------------------
# ICM 2027.1 Ruby build (3.4.6, x64-mswin64) has two confirmed bugs:
#   1. Symbol#to_s / Symbol#name return garbage or raise, instead of the
#      real text. (Symbol#inspect and string interpolation of a Symbol
#      both work correctly — use those instead.)
#   2. String#unpack raises. (String#getbyte and String#[offset,len] both
#      work correctly — use those to decode binary DBF data instead.)
# The helpers and DBF reader below are written to avoid both broken paths.
# ----------------------------------------------------------------------------

# Safe error class name without relying on Class#to_s/#name (untested/risky
# on this build) — matches against known exception classes explicitly.
def infoswmm_safe_class_name(e)
  case e
  when NoMethodError then 'NoMethodError'
  when NameError then 'NameError'
  when ArgumentError then 'ArgumentError'
  when TypeError then 'TypeError'
  when IOError then 'IOError'
  when SystemCallError then 'SystemCallError'
  when RuntimeError then 'RuntimeError'
  when StandardError then 'StandardError'
  else 'Error'
  end
end

# Safe error description — uses Symbol#inspect (confirmed working) instead
# of Symbol#to_s/#name (confirmed broken) to show the real missing method.
def infoswmm_diagnose_error(e)
  cls = infoswmm_safe_class_name(e)
  detail = ''
  if (e.is_a?(NoMethodError) || e.is_a?(NameError)) && e.respond_to?(:name)
    begin
      detail = " (method #{e.name.inspect})"
    rescue
      detail = ''
    end
  end
  "#{cls}#{detail}"
rescue
  'Unknown error'
end

# 32-bit / 16-bit little-endian integer from raw bytes, without String#unpack.
def infoswmm_le_int(bytes)
  return 0 if bytes.nil?
  value = 0
  i = 0
  len = bytes.length
  while i < len
    value += bytes.getbyte(i) << (8 * i)
    i += 1
  end
  value
end

# Trim a null-padded fixed-width field (replaces unpack('Z11')), without
# String#unpack — finds the first null byte manually.
def infoswmm_null_terminated(raw)
  return '' if raw.nil?
  len = raw.length
  end_idx = len
  i = 0
  while i < len
    if raw.getbyte(i) == 0
      end_idx = i
      break
    end
    i += 1
  end
  raw[0, end_idx].strip
end

# The entire Time class is broken on this ICM build — Time.now, #to_s,
# #strftime, and even the plain #year accessor all raise. Avoid Time
# entirely: get epoch seconds from Process.clock_gettime (a different
# subsystem, returns a plain Float — no Time object involved) and convert
# to a calendar date with hand-rolled integer arithmetic (Howard Hinnant's
# days-from-civil algorithm), using only string interpolation (confirmed
# safe) rather than explicit Integer#to_s.
def infoswmm_epoch_now
  Process.clock_gettime(Process::CLOCK_REALTIME)
rescue
  0
end

def infoswmm_civil_from_epoch(epoch_seconds)
  total_days = (epoch_seconds / 86400).floor
  secs_of_day = (epoch_seconds - (total_days * 86400)).floor
  hour = secs_of_day / 3600
  minute = (secs_of_day % 3600) / 60
  second = secs_of_day % 60

  z = total_days + 719468
  era = (z >= 0 ? z : z - 146096) / 146097
  doe = z - era * 146097
  yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  y = yoe + era * 400
  doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  mp = (5 * doy + 2) / 153
  d = doy - (153 * mp + 2) / 5 + 1
  m = mp + (mp < 10 ? 3 : -9)
  y = y + (m <= 2 ? 1 : 0)

  [y, m, d, hour, minute, second]
end

def infoswmm_zero_pad(n)
  n < 10 ? "0#{n}" : "#{n}"
end

def infoswmm_timestamp_display
  y, mo, d, h, mi, s = infoswmm_civil_from_epoch(infoswmm_epoch_now)
  "#{y}-#{infoswmm_zero_pad(mo)}-#{infoswmm_zero_pad(d)} " +
  "#{infoswmm_zero_pad(h)}:#{infoswmm_zero_pad(mi)}:#{infoswmm_zero_pad(s)}"
end

def infoswmm_timestamp_compact
  y, mo, d, h, mi, s = infoswmm_civil_from_epoch(infoswmm_epoch_now)
  "#{y}#{infoswmm_zero_pad(mo)}#{infoswmm_zero_pad(d)}_" +
  "#{infoswmm_zero_pad(h)}#{infoswmm_zero_pad(mi)}#{infoswmm_zero_pad(s)}"
end

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
  "  * Create a merged network with all scenario-variable data\n" +
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
        
        num_records = infoswmm_le_int(num_records_bytes)
        header_length = infoswmm_le_int(header_length_bytes)
        record_length = infoswmm_le_int(record_length_bytes)
        
        file.read(20)  # Reserved
        
        # Read field descriptors
        fields = []
        field_offset = 1  # First byte is delete flag
        
        # NOTE: Kernel#loop is also broken on this ICM build (raises
        # NoMethodError), so a plain while/true loop is used instead.
        reading_fields = true
        while reading_fields
          field_name_bytes = file.read(11)
          if field_name_bytes.nil? || field_name_bytes.length < 11
            reading_fields = false
            next
          end
          if field_name_bytes.getbyte(0) == 0x0D
            reading_fields = false
            next
          end
          
          field_name = infoswmm_null_terminated(field_name_bytes)
          if field_name.empty?
            reading_fields = false
            next
          end
          
          field_type = file.read(1)
          file.read(4)  # Reserved
          field_length_byte = file.read(1)
          field_length = field_length_byte.nil? ? 0 : field_length_byte.getbyte(0)
          file.read(15)  # Decimals + reserved
          
          fields << {
            name: field_name,
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
          
          # Read each record.
          # NOTE: Integer#times is also broken on this ICM build (raises
          # NoMethodError), so a plain counter-based while loop is used.
          record_index = 0
          while record_index < num_records
            record = file.read(record_length)
            unless record.nil? || record.length < record_length || record.getbyte(0) == 42  # '*' = deleted record
              # Extract ID field value
              id_value = record[id_field[:offset], id_field[:length]].strip
              scenario_names << id_value unless id_value.empty?
            end
            record_index += 1
          end
        end
      end
      
      if scenario_names.any?
        puts "Found #{scenario_names.length} scenario(s) in model"
      end
      
    rescue => e
      diagnosis = infoswmm_diagnose_error(e)
      puts "Warning: Could not auto-detect scenarios (#{diagnosis})"
      begin
        e.backtrace.first(5).each { |line| puts "  #{line}" } if e.backtrace
      rescue
      end

      WSApplication.message_box(
        "Could not read SCENARIO.DBF file.\n\n" +
        "Diagnosis: #{diagnosis}\n\n" +
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

# Try to get database path - different ICM versions may expose this differently
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
  'database_path' => db_path,
  'timestamp' => infoswmm_timestamp_display,
  'merge_scenarios' => true,
  'cleanup_empty_label_lists' => true,
  'copy_swmm_runs' => true
}

config_file = File.join(config_folder, 'import_config.json')
File.open(config_file, 'w') { |f| f.write(JSON.pretty_generate(config)) }

# ----------------------------------------------------------------------------
# STEP 7: Launch Exchange script
# ----------------------------------------------------------------------------
exchange_script = File.join(script_dir, 'InfoSWMM_Import_Exchange.rb')

# Pass config file location to Exchange script via environment variable
ENV['ICM_IMPORT_CONFIG'] = config_file

# Find ICMExchange.exe
icm_exchange = nil
[
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2027\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Sewer 2027\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Flood 2027\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM 2027\\ICMExchange.exe",
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

# Capture the console output.
# NOTE: Open3.capture2 is broken on this ICM build — it fails internally
# with NoMethodError (method :last) inside Autodesk's own shipped
# open3.rb. Use backticks instead, which go through Kernel/IO directly
# and never touch the open3 library.
output = `#{command} 2>&1`
success = begin
  $?.success?
rescue
  false
end

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
  diagnosis = infoswmm_diagnose_error(e)
  puts "\n" + "="*70
  puts "FATAL ERROR"
  puts "="*70
  puts "Error: #{diagnosis}"
  puts "\nStack trace:"
  backtrace_lines = []
  begin
    backtrace_lines = e.backtrace.first(10) if e.backtrace
    puts backtrace_lines.join("\n") unless backtrace_lines.empty?
  rescue
  end
  puts "="*70

  location_text = ''
  begin
    location_text = "\n\nLocation:\n#{backtrace_lines.first(3).join("\n")}" unless backtrace_lines.empty?
  rescue
  end

  WSApplication.message_box(
    "An unexpected error occurred:\n\n" +
    "#{diagnosis}#{location_text}\n\n" +
    "Check the Ruby output window for full details.",
    "OK",
    "!",
    false
  )
end
end  # catch :cancel_import

