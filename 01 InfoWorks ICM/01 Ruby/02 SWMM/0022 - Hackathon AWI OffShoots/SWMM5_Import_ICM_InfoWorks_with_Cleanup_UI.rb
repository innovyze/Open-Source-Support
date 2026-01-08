# ============================================================================
# SWMM5 Import WITH CLEANUP - UI SCRIPT (Version 3.1 - Robust Prompt Fix & Enhancements)
# ============================================================================
# 
# PURPOSE:
#   User-facing script to configure and launch the import of SWMM5 .inp file(s) 
#   into ICM SWMM Networks.
#
# V3.1 CHANGES:
#   - Fixed "attributes parameter item 0 invalid type" RuntimeError by implementing
#     the robust 4-element format [Label, Type, Attributes, DefaultValue] for 
#     all WSApplication.prompt definitions.
#   - Improved relative path naming logic for batch imports.
#   - Enhanced summary reporting with accurate duration formatting (float parsing).
#
# HOW TO USE:
#   1. Open your ICM database.
#   2. Network menu -> Run Ruby Script -> Select this file.
#
# ============================================================================

require 'yaml'
require 'open3'
require 'fileutils'

# Constants
# Robust determination of SCRIPT_DIR
begin
  SCRIPT_DIR = File.dirname(WSApplication.script_file)
rescue
  # Fallback if WSApplication.script_file is not available
  SCRIPT_DIR = File.dirname(__FILE__)
end

EXCHANGE_SCRIPT_NAME = 'SWMM5_Import_ICM_InfoWorks_with_Cleanup_Exchange.rb'
LOG_FOLDER_NAME = "ICM Import Log Files"
TARGET_NETWORK_TYPE = 'SWMM network'

# ----------------------------------------------------------------------------
# Helper: Efficient File Finder
# ----------------------------------------------------------------------------
def find_inp_files(directory, recursive)
  # Normalize path separators
  normalized_directory = directory.gsub('\\', '/')
  
  puts "\nScanning: #{normalized_directory} (Recursive: #{recursive})"
  
  # Use Dir.glob for efficient searching
  pattern = recursive ? File.join(normalized_directory, "**", "*.inp") : File.join(normalized_directory, "*.inp")
  
  files = []
  begin
    # FNM_CASEFOLD for case-insensitive matching (.inp, .INP)
    Dir.glob(pattern, File::FNM_CASEFOLD).each do |file_path|
      files << file_path if File.file?(file_path)
    end
  rescue => e
    puts "ERROR during file scan: #{e.message}"
    WSApplication.message_box("Error Scanning Directory\n\n#{e.message}", "OK", "!", false)
  end
  
  puts "Found #{files.length} files."
  files
end

# ----------------------------------------------------------------------------
# Helper: Find ICMExchange.exe (Robust)
# ----------------------------------------------------------------------------
def find_icm_exchange
  # 1. Hardcoded known paths (newest first)
  known_paths = [
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2027\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2027\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2026\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2026\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2025.2\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM 2025.2\\ICMExchange.exe",
  ]

  known_paths.each { |path| return path if File.exist?(path) }

  # 2. Dynamic search in Program Files (Autodesk and Innovyze)
  puts "ICMExchange not in known paths. Searching Program Files..."
  ["Autodesk", "Innovyze"].each do |vendor|
    begin
      program_files = ENV['ProgramFiles'] || "C:\\Program Files"
      search_pattern = File.join(program_files, vendor, "InfoWorks ICM*", "ICMExchange.exe")
      # Find the most recent version (sort reverse)
      found_files = Dir.glob(search_pattern.gsub('\\', '/')).sort.reverse
      if found_files.any?
          puts "Found via dynamic search: #{found_files.first}"
          return found_files.first
      end
    rescue
      # Ignore errors during dynamic search
    end
  end

  # 3. User fallback
  WSApplication.message_box(
    "ICMExchange.exe Not Found Automatically\n\n" +
    "Please locate ICMExchange.exe in the InfoWorks ICM installation directory.",
    "OK", "Warning", false
  )
  
  user_path = WSApplication.file_dialog(true, 'exe', 'Locate ICMExchange.exe', 'ICMExchange.exe', false, nil)
  
  if user_path && File.exist?(user_path) && File.basename(user_path).downcase == 'icmexchange.exe'
    return user_path
  end

  nil
end

# ----------------------------------------------------------------------------
# STEP 1: Initialization and Welcome
# ----------------------------------------------------------------------------
db = WSApplication.current_database
if db.nil?
  WSApplication.message_box("Please open an ICM database before running this script.", "OK", "!", false)
  exit
end

result = WSApplication.message_box(
  "SWMM5 Import to ICM (SWMM Networks) - V3.1\n\n" +
  "Features:\n" +
  "  * Single/Batch/Recursive modes\n" +
  "  * Automatic cleanup of empty visualization labels\n" +
  "  * Post-import connectivity validation\n" +
  "  * Live progress streaming\n\n" +
  "Continue?",
  "YesNo", "Information", false
)

exit if result == "No"

# ----------------------------------------------------------------------------
# STEP 2: Select import mode using checkboxes
# ----------------------------------------------------------------------------
layout = [
  ['Select Import Mode (check ONE):', 'READONLY', ''],
  ['1. Single File', 'BOOLEAN', true],
  ['2. Batch - Directory Only', 'BOOLEAN', false],
  ['3. Batch - Include Subdirectories', 'BOOLEAN', false]
]

result = WSApplication.prompt(
  'Import Mode Selection',
  layout,
  false
)
if result.nil?
  puts "Import cancelled by user"
  exit
end

# The result array contains the selected index for CHOICE inputs.
mode_index = result[0]
import_mode_label = import_modes[mode_index]

puts "\n" + "="*70
puts " SWMM5 Import to ICM - V3.1"
puts "="*70
puts "Import Mode: #{import_mode_label}"

# ----------------------------------------------------------------------------
# STEP 3: Get File(s) or Directory
# ----------------------------------------------------------------------------
file_paths = []
base_directory = nil

case mode_index
when 0 # Single File
  file_path = WSApplication.file_dialog(true, 'inp', 'SWMM5 Input File', '', false, nil)
  exit if file_path.nil?
  
  normalized_path = file_path.gsub('\\', '/')
  file_paths << normalized_path
  base_directory = File.dirname(normalized_path)

when 1, 2 # Batch Modes
  WSApplication.message_box(
    "Select Target Directory\n\n" +
    "In the next dialog, navigate to the target directory and select ANY FILE within it.\n\n" +
    "The script will scan this directory.",
    "OK", "Information", false
  )
  
  sample_file = WSApplication.file_dialog(true, '*', 'Select any file in the target directory', '', false, nil)
  exit if sample_file.nil?
  
  base_directory = File.dirname(sample_file).gsub('\\', '/')
  is_recursive = (mode_index == 2)
  
  file_paths = find_inp_files(base_directory, is_recursive)
  
  if file_paths.empty?
    WSApplication.message_box("No .inp files found in the selected directory.", "OK", "!", false)
    exit
  end
  
  # Confirmation
  max_display = 20
  file_list = file_paths.take(max_display).map { |f| "  * #{File.basename(f)}" }.join("\n")
  file_list += "\n  ... and #{file_paths.length - max_display} more" if file_paths.length > max_display
  
  result = WSApplication.message_box(
    "Found #{file_paths.length} File(s)\n\n#{file_list}\n\nContinue?",
    "YesNo", "?", false
  )
  exit if result == "No"
end

# ----------------------------------------------------------------------------
# STEP 4: Size Check and Time Estimation
# ----------------------------------------------------------------------------
total_size_mb = file_paths.sum { |file| File.exist?(file) ? File.size(file) : 0 } / (1024.0 * 1024.0)

# Heuristic: 30s per file overhead + 1 min per 25MB
estimated_time_minutes = (file_paths.length * 0.5) + (total_size_mb / 25.0)
estimated_time_str = "#{estimated_time_minutes.ceil} minutes"

puts "Total size: #{total_size_mb.round(2)} MB. Estimated time: ~#{estimated_time_str}"

if estimated_time_minutes > 10
  result = WSApplication.message_box(
    "Large Import Warning\n\nEstimated time: ~#{estimated_time_str}\n\nContinue?",
    "YesNo", "Warning", false
  )
  exit if result == "No"
end

# ----------------------------------------------------------------------------
# STEP 5: Configure Naming Options
# ----------------------------------------------------------------------------
network_names = []

if mode_index == 0 # Single File
  default_name = File.basename(file_paths.first, '.inp')

  # FIX: Using robust 4-element format: [Label, Type, Attributes (nil), Default Value]
  layout = [
    ['Network Name:', 'STRING', nil, default_name],
    ['Add timestamp?', 'BOOLEAN', nil, false]
  ]
  result = WSApplication.prompt('Import Settings', layout, false)
  exit if result.nil?
  
  network_name = result[0].strip
  network_name = default_name if network_name.empty?

  # result[1] holds the boolean value of the checkbox
  if result[1]
    network_name = "#{network_name}_#{Time.now.strftime("%Y%m%d_%H%M")}"
  end
  network_names << network_name
  
else # Batch Modes
    naming_options = [
        '1. Filename Only',
        '2. Directory + Filename (e.g., Dir_File)',
        '3. Relative Path (e.g., Sub_Dir_File)'
    ]

    # FIX: Using robust 4-element format for all types.
    layout = [
        ['Naming Convention:', 'CHOICE', naming_options, 0],
        ['Prefix (optional):', 'STRING', nil, 'SWMM_Import_'],
        ['Add timestamp (recommended)?', 'BOOLEAN', nil, true] # Default true for batch
    ]
  
    result = WSApplication.prompt('Batch Naming Settings', layout, false)
    exit if result.nil?

    # Retrieve results
    naming_choice = result[0]
    name_prefix = result[1].strip
    add_timestamp = result[2]
  
    # Generate names
    timestamp_str = Time.now.strftime("%Y%m%d_%H%M") if add_timestamp
    
    # IMPROVEMENT: Ensure base directory ends with a slash for clean subtraction
    base_dir_normalized = base_directory.end_with?('/') ? base_directory : base_directory + '/'

    file_paths.each do |file_path|
        # Case-insensitive extension removal
        filename = File.basename(file_path, File.extname(file_path))
        
        case naming_choice
        when 0 # Filename Only
            name = filename
        when 1 # Directory + Filename
            parent_dir = File.basename(File.dirname(file_path))
            name = "#{parent_dir}_#{filename}"
        when 2 # Relative Path
            relative_path = file_path.sub(base_dir_normalized, '')
            
            # IMPROVEMENT: Robustly handle files in the root directory
            if relative_path == File.basename(file_path)
                name = filename
            else
                # Construct name from relative path components, replacing separators with underscores
                name = File.join(File.dirname(relative_path), filename).gsub('/', '_')
            end
        end
        
        name = "#{name_prefix}#{name}" unless name_prefix.empty?
        name = "#{name}_#{timestamp_str}" if add_timestamp
        
        # Basic sanitization: Replace invalid characters
        name.gsub!(/[^0-9A-Za-z_ -]/, '_')
        network_names << name
    end
  
    # Internal check for self-duplicates
    if network_names.uniq.length != network_names.length
        duplicates = network_names.group_by{|e| e}.select{|k,v| v.size > 1}.keys
        WSApplication.message_box(
            "ERROR: Duplicate Names Generated!\n\n" +
            "The chosen naming convention resulted in duplicate names:\n#{duplicates.take(5).join("\n")}\n\n" +
            "Please adjust the naming options (e.g., enable timestamps or use relative paths) and try again.",
            "OK", "!", false
        )
        exit
    end
end

# ----------------------------------------------------------------------------
# STEP 6: Pre-Validation (Check for Duplicates in DB)
# ----------------------------------------------------------------------------
puts "\nValidating network names against database..."
duplicates = []
network_names.each do |name|
  # Check if an object of the target type with this name already exists
  if db.find_model_object(TARGET_NETWORK_TYPE, name)
    duplicates << name
  end
end

if duplicates.any?
  puts "ERROR: Duplicate network names found in the database."
  WSApplication.message_box(
    "ERROR: Duplicate Network Names Exist\n\n" +
    "The following network names already exist in the database:\n\n" +
    duplicates.first(15).map { |d| "  * #{d}" }.join("\n") +
    (duplicates.length > 15 ? "\n  ..." : "") +
    "\n\nImport cancelled. Please adjust naming settings and try again.",
    "OK", "!", false
  )
  exit
end
puts "Validation complete. No conflicts found."

# ----------------------------------------------------------------------------
# STEP 7: Prepare Configuration File
# ----------------------------------------------------------------------------
config_folder = File.join(base_directory, LOG_FOLDER_NAME)
FileUtils.mkdir_p(config_folder)

file_configs = file_paths.map.with_index do |file_path, index|
  {
    'file_path' => file_path,
    'network_name' => network_names[index],
    'file_basename' => File.basename(file_path)
  }
end

config = {
  'import_mode' => import_mode_label,
  'base_directory' => base_directory,
  'file_configs' => file_configs,
  # Flags for the exchange script
  'cleanup_empty_label_lists' => true, 
  'validate_after_import' => true
}

config_file = File.join(config_folder, 'import_config.yaml')
File.open(config_file, 'w') { |f| f.write(config.to_yaml) }
puts "\nConfiguration saved."

# ----------------------------------------------------------------------------
# STEP 8: Final Confirmation
# ----------------------------------------------------------------------------
result = WSApplication.message_box(
    "Ready to Import #{file_paths.length} File(s)\n\n" +
    "Estimated time: ~#{estimated_time_str}\n\n" +
    "The import will run via ICMExchange. Progress will be streamed LIVE to this Ruby window.\n\n" +
    "Proceed?",
    "YesNo", "?", false
)
exit if result == "No"

# ----------------------------------------------------------------------------
# STEP 9: Launch Exchange Script (Live Streaming)
# ----------------------------------------------------------------------------
exchange_script = File.join(SCRIPT_DIR, EXCHANGE_SCRIPT_NAME)
unless File.exist?(exchange_script)
  WSApplication.message_box("ERROR: Exchange Script Not Found\n#{EXCHANGE_SCRIPT_NAME}", "OK", "!", false)
  exit
end

icm_exchange = find_icm_exchange
if icm_exchange.nil?
  WSApplication.message_box("ERROR: ICMExchange.exe Not Found. Import cancelled.", "OK", "!", false)
  exit
end

# Set Environment Variable and Launch
ENV['ICM_IMPORT_CONFIG'] = config_file
# Ensure paths are properly quoted in the command
command = "\"#{icm_exchange}\" \"#{exchange_script}\" /ICM"

puts "\nLaunching ICMExchange..."
puts "Please wait. Live output streaming below:"
puts "="*70

# Execute the command and stream output
exchange_success = false
begin
  # Use Open3.popen2e to capture both stdout/stderr and stream them live
  Open3.popen2e(command) do |stdin, stdout_and_stderr, wait_thr|
    # Stream output line by line
    stdout_and_stderr.each do |line|
      puts line
    end
    
    # Wait for process to finish and check status
    exit_status = wait_thr.value
    exchange_success = exit_status.success?
    
    puts "="*70
    puts "ICMExchange finished with exit code: #{exit_status.exitstatus}"
  end
rescue => e
  puts "\nERROR launching ICMExchange: #{e.message}"
  WSApplication.message_box("Failed to launch ICMExchange.\n\nError: #{e.message}", "OK", "!", false)
  exit
end

# ----------------------------------------------------------------------------
# STEP 10: Process Results and Display Summary
# ----------------------------------------------------------------------------
puts "\nProcessing results..."
summary_file = File.join(config_folder, "batch_summary.txt")

# Initialize stats. Use a Hash that defaults numeric values to 0.
stats = Hash.new { |h, k| h[k] = 0 }

if File.exist?(summary_file)
  begin
    File.readlines(summary_file).each do |line|
      if line.include?('=')
        key, value = line.strip.split('=')
        # IMPROVEMENT: Handle duration as float (to_f) for accuracy, others as integer (to_i)
        stats[key] = (key == 'total_duration') ? value.to_f : value.to_i
      end
    end
  rescue
    puts "WARNING: Error reading summary file."
  end
else
  puts "WARNING: Summary file not found. Check Exchange output above for errors."
end

# Display summary dialog
dialog_title = "Import Complete"
icon = "Information"
summary_msg = ""

if stats['files_failed'] > 0
  dialog_title = "Import Completed with Failures"
  icon = (stats['files_successful'] > 0) ? "Warning" : "!"
end

# IMPROVEMENT: Format duration nicely
if stats['total_duration'] > 0
    duration_str = sprintf('%.2f seconds', stats['total_duration'])
    summary_msg += "Duration: #{duration_str}\n\n"
end

if file_paths.length > 1
  summary_msg += "Batch Results:\n"
  summary_msg += "  Processed: #{stats['files_processed']}\n"
  summary_msg += "  Successful: #{stats['files_successful']}\n"
  summary_msg += "  Failed: #{stats['files_failed']}\n\n"
else
    if stats['files_successful'] == 1
        summary_msg += "Network Created: #{network_names.first}\n\n"
    else
        summary_msg += "Status: FAILED\n\n"
    end
end
  
if stats['files_successful'] > 0
  summary_msg += "Total Elements Imported:\n"
  summary_msg += "  * #{stats['total_nodes']} nodes\n"
  summary_msg += "  * #{stats['total_links']} links\n"
  summary_msg += "  * #{stats['total_subcatchments']} subcatchments\n\n"
  # The Exchange script writes the 'total_labels_cleaned' key
  if stats['total_labels_cleaned'] > 0
    summary_msg += "Cleaned: #{stats['total_labels_cleaned']} empty visualization labels\n\n"
  end
end

summary_msg += "Detailed logs available in the Ruby output window and:\n#{config_folder}"

WSApplication.message_box(summary_msg, "OK", icon, false)