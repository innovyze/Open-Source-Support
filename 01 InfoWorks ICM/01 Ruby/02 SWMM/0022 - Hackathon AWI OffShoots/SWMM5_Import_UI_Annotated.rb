#Here is the rewritten code saved as `SWMM5_Import_UI_Annotated.rb`.

# ==============================================================================
# FILE: SWMM5_Import_UI_Annotated.rb
#
# DESCRIPTION:
# This is the "User Interface" (UI) script for importing SWMM5 files.
# It runs inside the ICM user interface (the window you see).
#
# Its main jobs are:
# 1. Ask the user for settings (Single file vs Batch, filenames, etc).
# 2. Find all the files to be imported.
# 3. Save those settings to a temporary configuration file.
# 4. Run a SECOND script (the "Exchange" script) in the background to do the heavy lifting.
#
# CONCEPTS FOR NOVICES:
# 1. WSApplication: This is the "bridge" between Ruby and ICM. We use it to 
#    show pop-ups (message_box), ask for input (prompt), and get file paths (file_dialog).
# 2. Variables: Containers for data. 
#    Example: 'file_path' holds the text string "C:\Projects\Model.inp".
# 3. Conditionals (If/Else): Logic to decide what to do.
#    Example: "If the user clicked 'No', then exit the script."
# 4. Loops (.each): Doing the same thing multiple times.
#    Example: "For each file in the folder, do this..."
# 5. The "Exchange" Concept: ICM has a background tool called ICMExchange.exe.
#    This script builds a command line instruction to tell that tool what to do.
# ==============================================================================

# 'require' tells Ruby to load extra toolkits.
# YAML is a toolkit for saving data in a readable text format.
require 'yaml' 
require 'open3' # Toolkit for running external commands (like the Command Prompt)

# Get the folder where THIS script is currently saved.
# We need this so we can find the partner "Exchange" script later.
script_dir = File.dirname(WSApplication.script_file)

# ==============================================================================
# HELPER FUNCTION: find_inp_files
# ==============================================================================
# A "def" (method) is a reusable block of code. 
# This specific method is "Recursive" - meaning if it finds a folder, 
# it calls itself again to dig deeper into that folder.
#
# Inputs: 
#   directory: The folder to look in.
#   recursive: True/False (should we look in sub-folders?)
# Returns: A list (Array) of all .inp files found.
# ==============================================================================
def find_inp_files(directory, recursive = true)
  files = [] # Start with an empty list
  
  begin
    # Loop through every item in the directory
    Dir.entries(directory).each do |entry|
      # Skip the current folder (.) and parent folder (..) indicators
      next if entry == '.' || entry == '..'
      
      # Build the full path (e.g., "C:\Data" + "file.inp")
      full_path = File.join(directory, entry)
      
      # LOGIC: Is it a Folder or a File?
      if File.directory?(full_path) && recursive
        # It's a folder, and we want to go deep. Call this function again!
        files.concat(find_inp_files(full_path, recursive))
        
      elsif File.file?(full_path) && entry.downcase.end_with?('.inp')
        # It's a file, and it ends with .inp. Add it to our list.
        files << full_path
      end
    end
  rescue => e
    # If something crashes (permission denied, etc.), print the error but don't stop entirely
    puts "ERROR scanning #{directory}: #{e.message}"
  end
  
  return files # Send the list back to whoever asked for it
end

# ==============================================================================
# STEP 1: WELCOME SCREEN
# ==============================================================================

# WSApplication.message_box shows a popup.
# Format: message_box(Text, ButtonType, IconType, ReturnsBoolean)
result = WSApplication.message_box(
  "SWMM5 Import to ICM InfoWorks\nVersion 2\n\n" +
  "This script imports .inp files and cleans up label lists.\n\n" +
  "Continue?",
  "YesNo",       # Buttons to show
  "Information", # Icon to show
  false          # Return the text "Yes" or "No", not a true/false value
)

# If they clicked No, stop the script immediately.
if result == "No"
  puts "Import cancelled by user"
  exit
end

# ==============================================================================
# STEP 2: SELECT MODE (Single vs Batch)
# ==============================================================================

# Define the layout for the input form.
# format: ['Label', 'Type', DefaultValue]
layout = [
  ['Select Import Mode (check ONE):', 'READONLY', ''],
  ['1. Single File', 'BOOLEAN', true],                # Checkbox
  ['2. Batch - Directory Only', 'BOOLEAN', false],    # Checkbox
  ['3. Batch - Include Subdirectories', 'BOOLEAN', false] # Checkbox
]

# Show the form to the user
result = WSApplication.prompt('Import Mode Selection', layout, false)

# If user closed the window (result is nil), exit.
if result.nil?
  puts "Import cancelled by user"
  exit
end

# Figure out which checkbox they ticked.
# result[1] corresponds to the second item in the layout list (Single File)
if result[1]
  import_mode = 'Single File'
elsif result[2]
  import_mode = 'Batch - Directory Only'
elsif result[3]
  import_mode = 'Batch - Include Subdirectories'
else
  import_mode = 'Single File' # Default safety net
end

# Print to the "Output" window in ICM so the user sees what's happening
puts "\n" + "="*70
puts " Import Mode: #{import_mode}"
puts "="*70

# ==============================================================================
# STEP 3: SELECT FILES OR DIRECTORIES
# ==============================================================================

file_paths = []      # This will hold the list of files we need to process
base_directory = nil # This will hold the folder path

# A 'case' statement is like a multi-option "If"
case import_mode
when 'Single File'
  # Open a standard Windows file picker
  file_path = WSApplication.file_dialog(
    true,                 # Open (not Save)
    'inp',                # File extension filter
    'SWMM5 Input File',   # Description
    '',                   # Default filename
    false,                # Allow multi-select? (False here)
    nil
  )
  
  # If they didn't pick a file, stop.
  if file_path.nil?
    WSApplication.message_box("Import cancelled.", "OK", "!", false)
    exit
  end
  
  # Add the single file to our list array
  file_paths << file_path
  base_directory = File.dirname(file_path) # Get the folder that file sits in

when 'Batch - Directory Only', 'Batch - Include Subdirectories'
  # ICM doesn't have a "Pick Folder" dialog easily available.
  # Workaround: Ask user to pick ANY file in the target folder.
  WSApplication.message_box(
    "Select Directory\n\nPlease select ANY file inside the folder you want to import.",
    "OK", "Information", false
  )
  
  sample_file = WSApplication.file_dialog(true, '*', 'Pick any file', '', false, nil)
  
  if sample_file.nil?
    exit
  end
  
  # Extract the folder path from that file
  base_directory = File.dirname(sample_file)
  
  puts "Scanning directory: #{base_directory}"
  
  # Decide whether to scan recursively based on mode
  is_recursive = (import_mode == 'Batch - Include Subdirectories')
  
  if is_recursive
    # Call our helper function defined at the top of the script
    file_paths = find_inp_files(base_directory, true)
  else
    # Simple scan of just the top folder
    Dir.entries(base_directory).each do |entry|
      next if entry == '.' || entry == '..' # Skip system folders
      full_path = File.join(base_directory, entry)
      # Only add if it is a file and ends in .inp
      if File.file?(full_path) && File.extname(entry).downcase == '.inp'
        file_paths << full_path
      end
    end
  end
  
  # Error check: Did we actually find anything?
  if file_paths.empty?
    WSApplication.message_box("No .inp files found in that directory!", "OK", "!", false)
    exit
  end
  
  puts "Found #{file_paths.length} .inp file(s)"
end

# ==============================================================================
# STEP 4: SIZE CHECK (User Experience)
# ==============================================================================
# Calculate total size to warn user if it's going to take a long time.

total_size_mb = 0.0
file_paths.each do |file|
  # Add size in bytes / 1024 / 1024 to get Megabytes
  total_size_mb += File.size(file) / (1024.0 * 1024.0)
end

if total_size_mb > 100
  response = WSApplication.message_box(
    "Large Import Warning: #{total_size_mb.round(1)} MB total.\nThis might take a while. Continue?",
    "YesNo", "?", false
  )
  exit if response == "No"
end

# ==============================================================================
# STEP 5: NAMING CONVENTION
# ==============================================================================
# We need to decide what to name the "Model Group" inside ICM.

model_group_names = [] # List of names corresponding to the list of files

if import_mode == 'Single File'
  # Default name is the filename without .inp
  default_name = File.basename(file_paths.first, '.inp')
  
  result = WSApplication.prompt(
    'Import Settings',
    [['Model Group Name:', 'STRING', default_name], ['Add Timestamp?', 'BOOLEAN', true]],
    false
  )
  exit if result.nil?
  
  final_name = result[0]
  # Append timestamp if requested (e.g., "_20231025_0930")
  final_name += "_#{Time.now.strftime("%Y%m%d_%H%M")}" if result[1]
  
  model_group_names << final_name

else
  # Batch Mode Naming Logic
  # Ask user if they want the Folder Name included in the Model Group Name
  use_dir_name = WSApplication.message_box(
    "Include directory name in Model Group names?", "YesNo", "?", false
  ) == "Yes"
  
  # Generate names for every file in the list
  file_paths.each do |file_path|
    filename = File.basename(file_path, '.inp')
    
    if use_dir_name
      # logic: ParentFolder_Filename
      parent = File.basename(File.dirname(file_path))
      name = "#{parent}_#{filename}"
    else
      name = filename
    end
    
    model_group_names << name
  end
end

# ==============================================================================
# STEP 6: PREPARE CONFIGURATION FOR EXTERNAL SCRIPT
# ==============================================================================
# The UI Script (this one) cannot import directly because we want to keep the 
# interface responsive or use specific Exchange features. 
# We pass data to the second script via a file.

# Get the ID of the current database
db_guid = WSApplication.current_database.guid

# Create a log folder
config_folder = File.join(base_directory, "ICM Import Log Files")
Dir.mkdir(config_folder) unless Dir.exist?(config_folder)

# Create the list of work to do
file_configs = []
file_paths.each_with_index do |file_path, index|
  file_configs << {
    'file_path' => file_path,
    'model_group_name' => model_group_names[index],
    'file_basename' => File.basename(file_path)
  }
end

# The main configuration object
config = {
  'import_mode' => import_mode,
  'file_configs' => file_configs, # The list of files and target names
  'database_guid' => db_guid,     # The database to import into
  'timestamp' => Time.now.to_s
}

# Write this data to 'import_config.yaml'
config_file = File.join(config_folder, 'import_config.yaml')
File.open(config_file, 'w') { |f| f.write(config.to_yaml) }

puts "Configuration saved for background process."

# ==============================================================================
# STEP 7: LOCATE ICM EXCHANGE AND RUN
# ==============================================================================

# Verify the partner script exists in the same folder as this one
exchange_script = File.join(script_dir, 'SWMM5_Import_with_Cleanup_Exchange.rb')
unless File.exist?(exchange_script)
  WSApplication.message_box("Error: Could not find companion script:\n#{exchange_script}", "OK", "!", false)
  exit
end

# We need to find the ICMExchange.exe program.
# It changes location based on the year version of the software.
# We check a list of known locations.
icm_exchange = nil
possible_paths = [
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2026\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2025\\ICMExchange.exe",
  "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2024.2\\ICMExchange.exe"
  # Add other paths here if your installation is different
]

possible_paths.each do |path|
  if File.exist?(path)
    icm_exchange = path
    break
  end
end

if icm_exchange.nil?
  WSApplication.message_box("Error: Could not find ICMExchange.exe. Please update the script paths.", "OK", "!", false)
  exit
end

# Set an Environment Variable so the second script knows where to find the config file
ENV['ICM_IMPORT_CONFIG'] = config_file

# Build the command line string:
# "Path\To\ICMExchange.exe" "Path\To\Script.rb" /ICM
command = "\"#{icm_exchange}\" \"#{exchange_script}\" /ICM"

puts "Launching background import process..."

# Open3.capture2 executes the command and waits for it to finish.
# It captures the text output (output) and the success code (status).
output, status = Open3.capture2(command)

# ==============================================================================
# STEP 8: READ SUMMARY AND REPORT
# ==============================================================================

# The background script should have created a summary text file.
summary_file = File.join(config_folder, "batch_summary.txt")
files_processed = 0
files_successful = 0

if File.exist?(summary_file)
  # Read the text file line by line to find key=value pairs
  File.readlines(summary_file).each do |line|
    if line.include?('=')
      key, value = line.strip.split('=')
      # Convert "10" to integer 10
      files_processed = value.to_i if key == 'files_processed'
      files_successful = value.to_i if key == 'files_successful'
    end
  end
else
  puts "Warning: No summary file generated."
end

# Final Popup for the user
if files_successful > 0
  WSApplication.message_box(
    "Import Complete!\n\nProcessed: #{files_processed}\nSuccess: #{files_successful}\n\nCheck logs in:\n#{config_folder}",
    "OK", "Information", false
  )
else
  WSApplication.message_box(
    "Import Completed with Errors.\nCheck Output window and logs.",
    "OK", "!", false
  )
end
```