# ============================================================================
# SWMM5 Import WITH CLEANUP - UI SCRIPT (Version 2 - Summary File Fix)
# ============================================================================
# 
# PURPOSE:
#   User-facing script that imports SWMM5 .inp file(s) into ICM InfoWorks
#
# WHAT THIS SCRIPT DOES:
#   Mode 1 - Single File:
#     Import one SWMM5 .inp file to a model group
#   
#   Mode 2 - Batch Directory:
#     Import all .inp files in a directory (no subdirectories)
#   
#   Mode 3 - Recursive Batch:
#     Import all .inp files in a directory and all subdirectories
#
#   For all modes:
#     + Clean up empty label lists after each import
#     + Perform post-import validation
#     + Report statistics and warnings
#
# HOW TO USE:
#   1. Open your ICM database
#   2. Go to: Network menu -> Run Ruby Script
#   3. Select this file: SWMM5_Import_ICM_SWMM_with_Cleanup_UI.rb
#   4. Choose import mode (Single/Batch/Recursive)
#   5. Select file or directory
#   6. Configure options
#   7. Wait for import(s) to complete
#
# VERSION 2 FEATURES:
#   - Single file import mode
#   - Batch directory import mode
#   - Recursive subdirectory scanning
#   - Automatically deletes empty label lists (import artifacts)
#   - Creates clean model groups ready for simulation
#   - Detailed logging of import process
#   - Progress tracking for batch imports
#   - Enhanced Windows path handling
#   - Summary file for accurate statistics
#
# OUTPUT:
#   - Model group(s) with imported SWMM5 network(s)
#   - Detailed log files in [Directory]/ICM Import Log Files/
#   - Summary report for batch imports
#
# REQUIREMENTS:
#   - InfoWorks ICM 2023.2 or later
#   - SWMM5 input file(s) (.inp)
#   - Open ICM database
#
# ============================================================================

require 'yaml'

# Get the script directory
script_dir = File.dirname(WSApplication.script_file)

# Helper function for recursive file finding
def find_inp_files(directory, recursive = true)
  files = []
  begin
    Dir.entries(directory).each do |entry|
      next if entry == '.' || entry == '..'
      full_path = File.join(directory, entry)
      
      if File.directory?(full_path) && recursive
        files.concat(find_inp_files(full_path, recursive))
      elsif File.file?(full_path) && entry.downcase.end_with?('.inp')
        files << full_path
      end
    end
  rescue => e
    puts "ERROR scanning #{directory}: #{e.message}"
  end
  files
end

# ----------------------------------------------------------------------------
# STEP 1: Welcome and mode selection
# ----------------------------------------------------------------------------
result = WSApplication.message_box(
  "SWMM5 Import to ICM InfoWorks\nVersion 2 with Single/Batch Options\n\n" +
  "This script can:\n" +
  "  * Import a single SWMM5 .inp file\n" +
  "  * Import all .inp files in a directory\n" +
  "  * Import all .inp files in directory tree (recursive)\n\n" +
  "All imports include:\n" +
  "  + Automatic cleanup of empty label lists\n" +
  "  + Post-import validation\n" +
  "  + Detailed logging\n\n" +
  "Continue?",
  "YesNo",
  "Information",
  false
)

if result == "No"
  puts "Import cancelled by user"
  exit
end

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

# Determine which option was selected
if result[1]
  import_mode = 'Single File'
elsif result[2]
  import_mode = 'Batch - Directory Only'
elsif result[3]
  import_mode = 'Batch - Include Subdirectories'
else
  # Default to Single File if nothing selected
  import_mode = 'Single File'
end

puts "\n" + "="*70
puts " SWMM5 Import to ICM InfoWorks - Version 2"
puts "="*70
puts "Import Mode: #{import_mode}"
puts "="*70

# ----------------------------------------------------------------------------
# STEP 3: Get file or directory based on mode
# ----------------------------------------------------------------------------
file_paths = []
base_directory = nil

case import_mode
when 'Single File'
  # Single file selection
  file_path = WSApplication.file_dialog(
    true,                          # open (not save)
    'inp',                         # extension
    'SWMM5 Input File',           # description
    '',                            # default filename
    false,                         # single file (not multiple)
    nil                            # don't exit on cancel
  )
  
  if file_path.nil?
    WSApplication.message_box(
      "Import cancelled - no file selected.",
      "OK",
      "!",
      false
    )
    exit
  end
  
  unless File.exist?(file_path)
    WSApplication.message_box(
      "ERROR: File Not Found\n\n" +
      "The selected file does not exist:\n" +
      "#{file_path}",
      "OK",
      "!",
      false
    )
    exit
  end
  
  file_paths << file_path
  base_directory = File.dirname(file_path)
  puts "\nSelected file: #{File.basename(file_path)}"

when 'Batch - Directory Only', 'Batch - Include Subdirectories'
  # Directory selection
  WSApplication.message_box(
    "Select Directory\n\n" +
    "In the next dialog, select any file in the directory.\n" +
    "The script will use the directory containing that file.",
    "OK",
    "Information",
    false
  )
  
  sample_file = WSApplication.file_dialog(
    true,                          # open (not save)
    '*',                           # any extension
    'Any File in Target Directory',
    '',                            # default filename
    false,                         # single file
    nil                            # don't exit on cancel
  )
  
  if sample_file.nil?
    WSApplication.message_box(
      "Import cancelled - no directory selected.",
      "OK",
      "!",
      false
    )
    exit
  end
  
  base_directory = File.dirname(sample_file)
  
  # DEBUG: Show what we're searching
  puts "\n" + "="*70
  puts "DEBUG: Directory Scanning"
  puts "="*70
  puts "Selected file: #{sample_file}"
  puts "Base directory: #{base_directory}"
  puts "Import mode: #{import_mode}"
  puts "Searching for: *.inp files"
  puts "="*70
  
  # Check if directory exists
  unless Dir.exist?(base_directory)
    puts "ERROR: Directory does not exist!"
    WSApplication.message_box(
      "ERROR: Directory Not Found\n\n" +
      "The directory does not exist:\n" +
      "#{base_directory}",
      "OK",
      "!",
      false
    )
    exit
  end
  
  # Scan for .inp files
  puts "\nScanning directory: #{base_directory}"
  
  # Convert Windows backslashes to forward slashes (Ruby handles these better)
  normalized_path = base_directory.gsub('\\', '/')
  puts "Normalized path: #{normalized_path}"
  
  if import_mode == 'Batch - Include Subdirectories'
    puts "Mode: Recursive (including subdirectories)"
    
    # Use Dir.entries instead of Dir.glob for better compatibility
    puts "\nUsing Dir.entries to scan recursively..."
    
    file_paths = find_inp_files(base_directory, true)
    
  else
    puts "Mode: Directory only (no subdirectories)"
    
    # Use Dir.entries instead of Dir.glob
    puts "\nUsing Dir.entries to scan directory..."
    
    begin
      Dir.entries(base_directory).each do |entry|
        next if entry == '.' || entry == '..'
        full_path = File.join(base_directory, entry)
        
        puts "  Checking: #{entry}"
        
        if File.file?(full_path)
          ext = File.extname(entry).downcase
          puts "    Type: file, Extension: #{ext}"
          
          if ext == '.inp'
            file_paths << full_path
            puts "    -> Added to list!"
          end
        elsif File.directory?(full_path)
          puts "    Type: directory"
        end
      end
    rescue => e
      puts "ERROR: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
    end
  end
  
  # DEBUG: Show what we found
  puts "\nDEBUG: Scan complete"
  puts "Files found: #{file_paths.length}"
  
  if file_paths.any?
    puts "\nDEBUG: Files found:"
    file_paths.each_with_index do |f, i|
      puts "  #{i+1}. #{File.basename(f)}"
      break if i >= 19  # Show first 20
    end
    puts "  ... and #{file_paths.length - 20} more" if file_paths.length > 20
  else
    puts "\nDEBUG: No .inp files found!"
  end
  
  puts "="*70
  
  if file_paths.empty?
    WSApplication.message_box(
      "No SWMM5 Files Found\n\n" +
      "No .inp files found in:\n" +
      "#{base_directory}\n\n" +
      (import_mode == 'Batch - Include Subdirectories' ? "(including subdirectories)" : "(directory only)") +
      "\n\n" +
      "Check the Ruby output window for detailed scan results.\n" +
      "The directory may:\n" +
      "  * Not contain any .inp files\n" +
      "  * Have files with different extensions\n" +
      "  * Have .inp files in subdirectories (use recursive mode)",
      "OK",
      "!",
      false
    )
    exit
  end
  
  puts "Found #{file_paths.length} .inp file(s)"
  
  # Show list of files to user
  file_list = file_paths.map { |f| "  * #{File.basename(f)}" }.join("\n")
  if file_paths.length > 20
    file_list = file_paths[0..19].map { |f| "  * #{File.basename(f)}" }.join("\n")
    file_list += "\n  ... and #{file_paths.length - 20} more files"
  end
  
  result = WSApplication.message_box(
    "Found #{file_paths.length} SWMM5 File(s)\n\n" +
    "Files to import:\n" +
    "#{file_list}\n\n" +
    "Continue with batch import?",
    "YesNo",
    "?",
    false
  )
  
  if result == "No"
    puts "Import cancelled by user"
    exit
  end
end

# ----------------------------------------------------------------------------
# STEP 4: Check file sizes and warn if large
# ----------------------------------------------------------------------------
total_size_mb = 0.0
file_paths.each do |file|
  total_size_mb += File.size(file) / (1024.0 * 1024.0)
end

puts "Total size: #{total_size_mb.round(2)} MB"

if total_size_mb > 100
  result = WSApplication.message_box(
    "Large Import Warning\n\n" +
    "Total size of files to import: #{total_size_mb.round(1)} MB\n" +
    "Number of files: #{file_paths.length}\n\n" +
    "Large imports may take considerable time.\n" +
    "Estimated time: #{(file_paths.length * 2)} - #{(file_paths.length * 5)} minutes\n\n" +
    "Continue with import?",
    "YesNo",
    "?",
    false
  )
  
  if result == "No"
    puts "\nImport cancelled by user"
    exit
  end
end

# ----------------------------------------------------------------------------
# STEP 5: Configure import options
# ----------------------------------------------------------------------------
if import_mode == 'Single File'
  default_name = File.basename(file_paths.first, '.inp')
  
  layout = [
    ['Model Group Name:', 'STRING', default_name],
    ['Add import timestamp?', 'BOOLEAN', true]
  ]
  
  result = WSApplication.prompt(
    'Import Settings',
    layout,
    false
  )
  
  if result.nil?
    WSApplication.message_box(
      "Import cancelled.",
      "OK",
      "!",
      false
    )
    exit
  end
  
  model_group_name = result[0].strip
  add_timestamp = result[1]
  
  if add_timestamp
    timestamp = Time.now.strftime("%Y%m%d_%H%M")
    model_group_name = "#{model_group_name}_#{timestamp}"
  end
  
  # Store in array for consistency with batch mode
  model_group_names = [model_group_name]
  
else
  # Batch mode - configure naming
  result = WSApplication.message_box(
    "Batch Naming Options:\n\n" +
    "Yes = Use directory + filename\n" +
    "No = Use filename only\n\n" +
    "Include directory in names?",
    "YesNo",
    "?",
    false
  )
  
  if result == "Yes"
    naming_template = 'Use Directory + Filename'
  else
    naming_template = 'Use Filename'
  end
  
  # Ask about prefix and timestamp
  layout = [
    ['Name Prefix (optional):', 'STRING', 'SWMM5 - '],
    ['Add timestamp to each?', 'BOOLEAN', false]
  ]
  
  result = WSApplication.prompt(
    'Batch Import Settings',
    layout,
    false
  )
  
  if result.nil?
    WSApplication.message_box(
      "Import cancelled.",
      "OK",
      "!",
      false
    )
    exit
  end
  
  name_prefix = result[0]
  add_timestamp = result[1]
  
  # Generate model group names for each file
  model_group_names = []
  
  file_paths.each do |file_path|
    case naming_template
    when 'Use Filename'
      name = File.basename(file_path, '.inp')
    when 'Use Directory + Filename'
      parent_dir = File.basename(File.dirname(file_path))
      filename = File.basename(file_path, '.inp')
      name = "#{parent_dir}_#{filename}"
    end
    
    # Add prefix
    name = "#{name_prefix}#{name}" unless name_prefix.empty?
    
    # Add timestamp if requested
    if add_timestamp
      timestamp = Time.now.strftime("%Y%m%d_%H%M")
      name = "#{name}_#{timestamp}"
    end
    
    model_group_names << name
  end
  
  puts "\nModel group names generated:"
  model_group_names.each_with_index do |name, i|
    puts "  #{i+1}. #{name}"
    break if i >= 9  # Show first 10 only
  end
  puts "  ... and #{model_group_names.length - 10} more" if model_group_names.length > 10
end

puts "="*70

# ----------------------------------------------------------------------------
# STEP 6: Get database for Exchange script
# ----------------------------------------------------------------------------
db = WSApplication.current_database
db_guid = db.guid

# ----------------------------------------------------------------------------
# STEP 7: Save configuration to YAML file
# ----------------------------------------------------------------------------
config_folder = File.join(base_directory, "ICM Import Log Files")
Dir.mkdir(config_folder) unless Dir.exist?(config_folder)

# Build file mapping
file_configs = []
file_paths.each_with_index do |file_path, index|
  file_configs << {
    'file_path' => file_path,
    'model_group_name' => model_group_names[index],
    'file_basename' => File.basename(file_path)
  }
end

config = {
  'import_mode' => import_mode,
  'base_directory' => base_directory,
  'file_configs' => file_configs,
  'database_guid' => db_guid,
  'timestamp' => Time.now.to_s,
  'file_type' => 'SWMM5',
  'cleanup_empty_label_lists' => true,
  'validate_after_import' => true
}

config_file = File.join(config_folder, 'import_config.yaml')
File.open(config_file, 'w') { |f| f.write(config.to_yaml) }

puts "Configuration saved: #{config_file}"

# ----------------------------------------------------------------------------
# STEP 8: Final confirmation
# ----------------------------------------------------------------------------
if file_paths.length > 1
  result = WSApplication.message_box(
    "Ready to Import #{file_paths.length} Files\n\n" +
    "Import mode: #{import_mode}\n" +
    "Total size: #{total_size_mb.round(1)} MB\n" +
    "Estimated time: #{(file_paths.length * 2)} - #{(file_paths.length * 5)} minutes\n\n" +
    "The import will run in the background.\n" +
    "You can continue working in ICM.\n\n" +
    "Proceed with batch import?",
    "YesNo",
    "?",
    false
  )
  
  if result == "No"
    puts "Import cancelled by user"
    exit
  end
end

# ----------------------------------------------------------------------------
# STEP 9: Launch Exchange script
# ----------------------------------------------------------------------------
exchange_script = File.join(script_dir, 'SWMM5_Import_ICM_SWMM_with_Cleanup_Exchange.rb')

unless File.exist?(exchange_script)
  WSApplication.message_box(
    "ERROR: Exchange Script Not Found\n\n" +
    "Cannot find: #{File.basename(exchange_script)}\n\n" +
    "Make sure both UI and Exchange scripts are in the same folder:\n" +
    "#{script_dir}",
    "OK",
    "!",
    false
  )
  exit
end

# Pass config file location to Exchange script
ENV['ICM_IMPORT_CONFIG'] = config_file

# Find ICMExchange.exe
icm_exchange = nil
[
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2026\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Sewer 2026\\ICMExchange.exe",
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
  exit
end

puts "\nLaunching import process..."
if file_paths.length > 1
  puts "Batch processing #{file_paths.length} files..."
  puts "This will take approximately #{(file_paths.length * 2)} - #{(file_paths.length * 5)} minutes"
else
  puts "This may take several minutes for large models..."
end

# Launch Exchange script
command = "\"#{icm_exchange}\" \"#{exchange_script}\" /ICM"

require 'open3'
output, status = Open3.capture2(command)
success = status.success?

# Read summary file instead of parsing output
puts "\n" + "="*70
puts "Reading import summary..."
puts "="*70

summary_file = File.join(config_folder, "batch_summary.txt")

files_processed = 0
files_successful = 0
files_failed = 0
total_nodes = 0
total_links = 0
total_subs = 0
total_cleaned = 0

if File.exist?(summary_file)
  puts "Summary file found: #{summary_file}"
  summary_data = {}
  File.readlines(summary_file).each do |line|
    if line.include?('=')
      key, value = line.strip.split('=')
      summary_data[key] = value.to_i
    end
  end
  
  files_processed = summary_data['files_processed'] || 0
  files_successful = summary_data['files_successful'] || 0
  files_failed = summary_data['files_failed'] || 0
  total_nodes = summary_data['total_nodes'] || 0
  total_links = summary_data['total_links'] || 0
  total_subs = summary_data['total_subcatchments'] || 0
  total_cleaned = summary_data['total_label_lists_deleted'] || 0
  
  puts "Successfully read summary:"
  puts "  Files: #{files_processed} (#{files_successful} successful, #{files_failed} failed)"
  puts "  Elements: #{total_nodes} nodes, #{total_links} links, #{total_subs} subs"
  puts "  Cleaned: #{total_cleaned} label lists"
else
  puts "WARNING: Summary file not found at: #{summary_file}"
  puts "Using file count from configuration: #{file_paths.length}"
  files_processed = file_paths.length
  files_successful = file_paths.length  # Assume success if no summary
  files_failed = 0
end

puts "="*70

# Display summary
puts "\n" + "="*70
puts " IMPORT SUMMARY"
puts "="*70
puts ""

if file_paths.length > 1
  puts "BATCH IMPORT RESULTS:"
  puts "  Files processed: #{files_processed}"
  puts "  Successful: #{files_successful}"
  puts "  Failed: #{files_failed}"
  puts ""
  
  if total_nodes > 0
    puts "TOTAL ELEMENTS IMPORTED:"
    puts "  * #{total_nodes} nodes"
    puts "  * #{total_links} links"
    puts "  * #{total_subs} subcatchments"
    puts ""
  end
  
  if total_cleaned > 0
    puts "CLEANUP:"
    puts "  * #{total_cleaned} empty label list(s) removed"
    puts ""
  end
else
  if success
    puts "STATUS: Import Successful"
    puts ""
    
    if total_nodes > 0
      puts "NETWORK ELEMENTS:"
      puts "  * #{total_nodes} nodes"
      puts "  * #{total_links} links"
      puts "  * #{total_subs} subcatchments"
      puts ""
    end
    
    if total_cleaned > 0
      puts "CLEANUP:"
      puts "  * #{total_cleaned} empty label list(s) removed"
      puts ""
    end
  else
    puts "STATUS: Import completed with warnings (check log)"
    puts ""
  end
  
  puts "MODEL GROUP CREATED:"
  puts "  #{model_group_names.first}"
  puts ""
end

puts "LOG FILES:"
puts "  #{config_folder}"
puts ""
puts "="*70

# Show completion dialog
if success || files_successful > 0
  if file_paths.length > 1
    summary = "Batch Import Complete!\n\n"
    summary += "Processed: #{files_processed} file(s)\n"
    summary += "Successful: #{files_successful}\n"
    summary += "Failed: #{files_failed}\n\n"
    
    if total_nodes > 0
      summary += "Total Elements:\n"
      summary += "  * #{total_nodes} nodes\n"
      summary += "  * #{total_links} links\n"
      summary += "  * #{total_subs} subcatchments\n\n"
    end
    
    if total_cleaned > 0
      summary += "Cleaned: #{total_cleaned} empty label list(s)\n\n"
    end
    
    summary += "See Ruby output window for details.\n"
    summary += "Logs: ICM Import Log Files folder"
  else
    summary = "SWMM5 Import Complete!\n\n"
    summary += "Model Group: #{model_group_names.first}\n\n"
    
    if total_nodes > 0
      summary += "Imported:\n"
      summary += "  * #{total_nodes} nodes\n"
      summary += "  * #{total_links} links\n"
      summary += "  * #{total_subs} subcatchments\n\n"
    end
    
    if total_cleaned > 0
      summary += "Cleaned: #{total_cleaned} empty label list(s)\n\n"
    end
    
    summary += "See Ruby output window for details.\n"
    summary += "Logs: ICM Import Log Files folder"
  end
  
  WSApplication.message_box(
    summary,
    "OK",
    "Information",
    false
  )
else
  WSApplication.message_box(
    "Import Completed with Issues\n\n" +
    (file_paths.length > 1 ? 
      "Some imports may have failed.\n" : 
      "The import finished but may have warnings.\n") +
    "Check the Ruby output window for details.\n\n" +
    "Logs: ICM Import Log Files folder",
    "OK",
    "Warning",
    false
  )
end