# =============================================================================
# PCSWMM to InfoWorks ICM Import Tool - EXCHANGE SCRIPT (BACKEND)
# =============================================================================
# 
# DO NOT RUN THIS SCRIPT DIRECTLY
# This script is automatically launched by PCSWMM_Import_UI.rb
#
# WHAT IT DOES:
#   1. Reads config from YAML file (created by UI script)
#   2. Extracts .pcz file (ZIP format) using PowerShell
#   3. Finds INP file in extracted contents
#   4. Truncates overly long field values (ICM 100-char limit)
#   5. Creates model group in database
#   6. Imports INP to ICM using import_all_sw_model_objects
#   7. Cleans up URL-encoded names (%20 → spaces)
#   8. Removes empty label lists
#   9. Commits network to database
#   10. Deletes temporary files
#
# REQUIREMENTS:
#   - InfoWorks ICM 2024 or later
#   - Config file with pcz_file and model_group_name
#   - Database must be open
#
# OUTPUT:
#   - Model Group with SWMM network
#   - Logs: [PCZlocation]\[PCZname]\PCSWMM_Import_*.log
#
# =============================================================================

require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'open3'
require 'uri'

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Simple logging function - outputs to console and log file
def log(message, log_file = nil)
  puts message
  log_file.puts message if log_file
end

# Truncate long field values in INP file to meet ICM's 100-character limit
# Why: PCSWMM allows unlimited field lengths, but ICM has a 100-char limit
# This function prevents import failures by automatically shortening long values
def truncate_long_fields(input_file, output_file, log_file = nil)
  max_length = 100
  truncation_count = 0
  line_number = 0
  
  log "  Scanning INP file: #{input_file}", log_file if log_file
  log "  Writing truncated version: #{output_file}", log_file if log_file
  
  File.open(output_file, 'w') do |out|
    File.foreach(input_file) do |line|
      line_number += 1
      original_line = line.dup
      modified = false
      
      # Strategy 1: Look for quoted strings that are too long
      # Match: "text" or 'text'
      while line =~ /["']([^"']{101,})["']/
        long_value = $1
        truncated = long_value[0, max_length]
        
        # Replace in the line
        line.sub!(/["']#{Regexp.escape(long_value)}["']/, "\"#{truncated}\"")
        
        truncation_count += 1
        modified = true
        
        if truncation_count <= 10
          log "    [#{truncation_count}] Line #{line_number}: Quoted string truncated", log_file if log_file
          log "        From (#{long_value.length} chars): #{long_value[0, 60]}...", log_file if log_file
          log "        To   (#{max_length} chars): #{truncated[0, 60]}...", log_file if log_file
        end
      end
      
      # Strategy 2: Look for any non-whitespace sequence > 100 chars (unquoted values)
      # Collect matches first, then replace (can't modify while scanning)
      unquoted_long_values = []
      line.scan(/\S{101,}/) do |long_value|
        # Skip if it's a number or looks like a coordinate
        next if long_value =~ /^[\d\.\-\+eE]+$/
        unquoted_long_values << long_value
      end
      
      # Now replace the collected long values
      unquoted_long_values.each do |long_value|
        truncated = long_value[0, max_length]
        line.sub!(long_value, truncated)
        
        truncation_count += 1
        modified = true
        
        if truncation_count <= 10
          log "    [#{truncation_count}] Line #{line_number}: Unquoted value truncated", log_file if log_file
          log "        From (#{long_value.length} chars): #{long_value[0, 60]}...", log_file if log_file
          log "        To   (#{max_length} chars): #{truncated[0, 60]}...", log_file if log_file
        end
      end
      
      if modified && log_file && truncation_count <= 5
        log "        Original line: #{original_line.strip[0, 100]}", log_file
        log "        Modified line: #{line.strip[0, 100]}", log_file
      end
      
      out.puts line
    end
  end
  
  if truncation_count > 0
    log "  SUCCESS: Truncated #{truncation_count} field value(s) to #{max_length} characters", log_file if log_file
    puts "  > Fixed #{truncation_count} overly long field value(s)"
  else
    log "  No field truncation needed (no values > #{max_length} characters found)", log_file if log_file
  end
  
  log "  Truncation function completed successfully", log_file if log_file
  
  truncation_count
rescue => e
  log "  ERROR in truncate_long_fields: #{e.message}", log_file if log_file
  log "  Backtrace: #{e.backtrace.join("\n")}", log_file if log_file
  raise
end

# =============================================================================
# STEP 1: READ CONFIGURATION
# =============================================================================
begin
  puts ""
  puts "="*70
  puts "EXCHANGE SCRIPT STARTED"
  puts "="*70
  puts "Reading configuration..."

  # Get config file from environment variable (set by UI script)
  config_file = ENV['PCSWMM_IMPORT_CONFIG']
  puts "ENV variable: #{config_file.inspect}"

  # Fallback: look for config.yaml in script directory
  if config_file.nil? || config_file.empty?
    script_dir = File.dirname(__FILE__)
    config_file = File.join(script_dir, 'config.yaml')
    puts "Using config.yaml from script directory"
  end

  puts "Config file: #{config_file}"

  unless File.exist?(config_file)
    puts "ERROR: Configuration file not found: #{config_file}"
    puts ""
    puts "Please create a config.yaml file with the following format:"
    puts ""
    puts "---"
    puts "pcz_file: \"C:/path/to/model.pcz\""
    puts "model_group_name: \"PCSWMM - Model Name\""
    puts ""
    exit 1
  end

  puts "Config file found!"

  config = YAML.load_file(config_file)
  
rescue => e
  puts ""
  puts "="*70
  puts "CRITICAL ERROR IN EXCHANGE SCRIPT"
  puts "="*70
  puts "Error: #{e.message}"
  puts "Class: #{e.class}"
  puts ""
  puts "Backtrace:"
  puts e.backtrace.first(10)
  puts "="*70
  exit 1
end

# Validate required keys
required_keys = ['pcz_file', 'model_group_name']
missing = required_keys - config.keys
if missing.any?
  puts "ERROR: Configuration missing required keys: #{missing.join(', ')}"
  puts ""
  puts "Required keys:"
  required_keys.each { |key| puts "  - #{key}" }
  puts ""
  exit 1
end

pcz_file = config['pcz_file']
group_name = config['model_group_name']

# Validate PCZ file exists
unless File.exist?(pcz_file)
  puts "ERROR: PCZ file not found: #{pcz_file}"
  exit 1
end

# Validate file extension
unless File.extname(pcz_file).downcase == '.pcz'
  puts "ERROR: File must be a PCSWMM .pcz file"
  puts "Selected file: #{pcz_file}"
  exit 1
end

puts "\n" + "="*70
puts "  PCSWMM to InfoWorks ICM Import Tool (Exchange Mode)"
puts "="*70
puts ""
puts "PCZ File: #{File.basename(pcz_file)}"
puts "Model Group: #{group_name}"
puts "="*70

# =============================================================================
# STEP 2: OPEN DATABASE
# =============================================================================
begin
  puts ""
  puts "Opening database..."
  db = WSApplication.open
  
  if db.nil?
    puts "ERROR: Database is nil"
    exit 1
  end
  
  puts "Database opened successfully"
  puts "GUID: #{db.guid}"
  
rescue => e
  puts ""
  puts "="*70
  puts "ERROR OPENING DATABASE"
  puts "="*70
  puts "Error: #{e.message}"
  puts "Class: #{e.class}"
  puts ""
  puts "Backtrace:"
  puts e.backtrace.first(10)
  puts "="*70
  exit 1
end

# =============================================================================
# STEP 3: SETUP LOGGING
# =============================================================================
begin
  pcz_basename = File.basename(pcz_file, '.pcz')
  base_dir = File.dirname(pcz_file)
  log_dir = File.join(base_dir, pcz_basename)

  # Create log directory if it doesn't exist
  unless Dir.exist?(log_dir)
    Dir.mkdir(log_dir)
  end

  log_filename = File.join(log_dir, "PCSWMM_Import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
  log_file = File.open(log_filename, 'w')

  log "="*70, log_file
  log "PCSWMM to InfoWorks ICM Import - #{Time.now}", log_file
  log "="*70, log_file
  log "Database GUID: #{db.guid}", log_file
  log "Source File: #{pcz_file}", log_file
  log "Model Group: #{group_name}", log_file
  log "Log Directory: #{log_dir}", log_file
  log "="*70, log_file
  
rescue => e
  puts "WARNING: Could not create log file: #{e.message}"
  puts "Continuing without log file..."
  log_file = nil
end

# =============================================================================
# STEP 4: EXTRACT PCZ FILE
# =============================================================================
puts "\nStep 1: Extract PCZ file"
log "\nExtracting PCZ file...", log_file

# Create temp directory for extraction
temp_dir = File.join(Dir.tmpdir, "pcswmm_import_#{Time.now.to_i}")
Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)

log "  Temp directory: #{temp_dir}", log_file

begin
  # Use PowerShell's Expand-Archive (built into Windows, no dependencies)
  log "  Using PowerShell to extract archive...", log_file
  log "  Source: #{pcz_file}", log_file
  log "  Destination: #{temp_dir}", log_file
  
  # Workaround: PowerShell's Expand-Archive requires .zip extension
  # Copy .pcz to temporary .zip file for extraction
  temp_zip = File.join(temp_dir, "temp_extract.zip")
  
  log "  Copying .pcz to .zip for extraction...", log_file
  FileUtils.cp(pcz_file, temp_zip)
  log "  Copied to: #{temp_zip}", log_file
  
  # Build PowerShell command to extract the .zip file
  ps_command = "Expand-Archive -Path '#{temp_zip}' -DestinationPath '#{temp_dir}' -Force"
  
  # Execute PowerShell command and capture output
  stdout, stderr, status = Open3.capture3("powershell", "-NoProfile", "-NonInteractive", "-Command", ps_command)
  
  log "  PowerShell output: #{stdout}", log_file if !stdout.empty?
  log "  PowerShell errors: #{stderr}", log_file if !stderr.empty?
  
  # Delete the temp .zip file
  begin
    File.delete(temp_zip) if File.exist?(temp_zip)
    log "  Cleaned up temporary .zip file", log_file
  rescue => e
    log "  Warning: Could not delete temp .zip: #{e.message}", log_file
  end
  
  unless status.success?
    log "  ERROR: Failed to extract PCZ file (exit code: #{status.exitstatus})", log_file
    puts "ERROR: Failed to extract PCZ file"
    puts "Exit code: #{status.exitstatus}"
    puts "Error details: #{stderr}" if !stderr.empty?
    puts ""
    puts "Possible causes:"
    puts "- File is not a valid PCSWMM .pcz (should be ZIP format)"
    puts "- File is corrupted or password-protected"
    puts "- Path has spaces or special characters"
    puts "- Insufficient permissions"
    puts ""
    puts "Try copying the file to a simpler path like: C:\\Temp\\model.pcz"
    log_file.close
    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    exit 1
  end
  
  log "  Extraction completed successfully", log_file
  
  # Count extracted files
  extracted_files = Dir.glob(File.join(temp_dir, '**', '*')).select { |f| File.file?(f) }
  puts "  > Extracted #{extracted_files.length} file(s)"
  log "  Extracted #{extracted_files.length} file(s)", log_file
  
  # Log extracted files
  if extracted_files.length > 0
    log "  Extracted files:", log_file
    extracted_files.first(10).each { |f| log "    - #{File.basename(f)}", log_file }
    log "    ... and #{extracted_files.length - 10} more" if extracted_files.length > 10
  end
  
rescue => e
  log "  ERROR: Exception during extraction: #{e.message}", log_file
  log "  Backtrace: #{e.backtrace.first(5).join("\n")}", log_file
  puts "ERROR: Exception during extraction"
  puts "Error: #{e.message}"
  puts ""
  puts "Try copying the .pcz file to: C:\\Temp\\model.pcz"
  log_file.close
  # Cleanup
  FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  exit 1
end

# =============================================================================
# STEP 5: FIND INP FILE
# =============================================================================
puts ""
puts "Step 2: Find INP file"
log "\nSearching for INP file...", log_file

inp_files = Dir.glob(File.join(temp_dir, '**', '*.inp'))

if inp_files.empty?
  log "  ERROR: No INP file found in PCZ archive", log_file
  puts "ERROR: No INP file found in PCZ archive"
  log_file.close
  # Cleanup
  FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  exit 1
end

# Use the first INP file found
inp_file = inp_files.first

log "  Found INP file: #{File.basename(inp_file)}", log_file
puts "  > Found: #{File.basename(inp_file)}"

# =============================================================================
# STEP 6: CREATE MODEL GROUP
# =============================================================================
puts ""
puts "Step 3: Create Model Group"
log "\nCreating model group: #{group_name}", log_file

begin
  model_group = db.new_model_object('Model Group', group_name)
  log "  Model group created with ID: #{model_group.id}", log_file
  puts "  > Created: #{group_name}"
rescue => e
  log "  ERROR: Failed to create model group: #{e.message}", log_file
  puts "ERROR: Failed to create model group: #{e.message}"
  log_file.close
  # Cleanup
  FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  exit 1
end

# =============================================================================
# STEP 7: IMPORT INP FILE
# =============================================================================
puts ""
puts "Step 4: Import INP file to ICM"
log "\nImporting INP file...", log_file

import_log_path = File.join(log_dir, "INP_Import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")

# Pre-process INP file: truncate long values, clean up names
log "  Pre-processing INP file...", log_file

begin
  # Use a temporary filename for processing to avoid overwriting
  original_basename = File.basename(inp_file)
  clean_basename = URI.decode_www_form_component(original_basename)
  temp_processed = File.join(temp_dir, "temp_processed.inp")
  final_inp = File.join(temp_dir, clean_basename)
  
  log "  Original INP: #{original_basename}", log_file
  log "  Clean name: #{clean_basename}", log_file
  
  log "  Calling truncate_long_fields...", log_file
  truncate_long_fields(inp_file, temp_processed, log_file)
  log "  Truncation complete", log_file
  
  # Verify processed file exists and has content
  unless File.exist?(temp_processed)
    raise "Processed INP file was not created: #{temp_processed}"
  end
  
  file_size = File.size(temp_processed)
  log "  Processed file size: #{file_size} bytes", log_file
  
  if file_size == 0
    raise "Processed INP file is empty! Original file may have been overwritten."
  end
  
  # Rename to clean name for import (so objects get clean names)
  File.rename(temp_processed, final_inp)
  log "  Renamed to: #{File.basename(final_inp)}", log_file
  log "  Starting ICM import...", log_file
  
rescue => e
  log "  ERROR during preprocessing: #{e.message}", log_file
  log "  Backtrace: #{e.backtrace.first(5).join("\n")}", log_file
  raise
end

begin
  imported_objects = model_group.import_all_sw_model_objects(
    final_inp,       # Use final clean version
    'inp',           # format for SWMM5 INP files
    '',              # scenario name (not used for INP)
    import_log_path
  )
  
  # Check success
  if imported_objects.nil? || imported_objects.empty?
    log "  WARNING: No objects imported", log_file
    
    if File.exist?(import_log_path)
      log "  Import log contents:", log_file
      File.foreach(import_log_path) do |line|
        log "    #{line.strip}", log_file
      end
    end
    
    puts "ERROR: No objects were imported"
    puts "Check the import log for details: #{import_log_path}"
    
    # Delete empty model group
    begin
      model_group.delete
      log "  Deleted empty model group", log_file
    rescue => e
      log "  Could not delete empty model group: #{e.message}", log_file
    end
    
    log_file.close
    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    exit 1
    
  else
    # Success!
    log "  SUCCESS: Imported #{imported_objects.length} object(s)", log_file
    puts "  > Imported #{imported_objects.length} object(s)"
    puts ""
    
    log "  Imported objects:", log_file
    imported_objects.each do |obj|
      log "    - #{obj.type}: #{obj.name} (ID: #{obj.id})", log_file
      puts "    - #{obj.type}: #{obj.name}"
    end
    
    # =======================================================================
    # POST-IMPORT CLEANUP
    # =======================================================================
    # Fix common issues that occur during import:
    # - URL-encoded names (%20 becomes space)
    # - Empty label lists (clutter the database)
    
    log "\n  Cleaning up imported objects...", log_file
    
    # 1. Fix URL-encoded names (%20 → space, etc.)
    log "  Fixing URL-encoded names...", log_file
    imported_objects.each do |obj|
      begin
        # Decode URL encoding (%20 -> space, etc.)
        decoded_name = URI.decode_www_form_component(obj.name)
        
        if decoded_name != obj.name
          log "    Renaming: '#{obj.name}' -> '#{decoded_name}'", log_file
          obj.name = decoded_name
        end
      rescue => e
        log "    WARNING: Could not rename '#{obj.name}': #{e.message}", log_file
      end
    end
    
    # 2. Delete empty label lists
    # ICM import sometimes creates empty label lists that clutter the database
    log "  Checking for empty label lists...", log_file
    label_lists_deleted = 0
    
    imported_objects.each do |obj|
      if obj.type == 'Label List'
        begin
          # Check if label list is empty by checking the 'Blob' field
          blob = obj['Blob']
          
          if blob.nil? || blob.empty?
            log "    Deleting empty label list: #{obj.name}", log_file
            obj.delete
            label_lists_deleted += 1
          else
            log "    Keeping label list with content: #{obj.name}", log_file
          end
        rescue => e
          log "    WARNING: Could not check/delete label list '#{obj.name}': #{e.message}", log_file
        end
      end
    end
    
    if label_lists_deleted > 0
      log "  Deleted #{label_lists_deleted} empty label list(s)", log_file
      puts "  > Cleaned up #{label_lists_deleted} empty label list(s)"
    end
    
    # 3. Commit the SWMM network to the database
    # This saves all changes and makes the network available for use
    imported_network = nil
    imported_objects.each do |obj|
      if obj.type == 'SWMM network'
        imported_network = obj
        break
      end
    end
    
    if imported_network
      begin
        model_basename = File.basename(pcz_file, '.pcz')
        # Also decode the model basename
        model_basename_clean = URI.decode_www_form_component(model_basename)
        
        log "\n  Committing network: #{imported_network.name}", log_file
        net = imported_network.open
        net.commit("Imported from PCSWMM - #{model_basename_clean}")
        log "  Network committed successfully", log_file
      rescue => e
        log "  WARNING: Could not commit network: #{e.message}", log_file
      end
    end
  end
  
  rescue => e
    log "  ERROR: Import failed: #{e.message}", log_file
    log "  Backtrace: #{e.backtrace.join("\n")}", log_file
    
    # Read and display INP import log if it exists
    if File.exist?(import_log_path)
      log "\n  INP Import log contents:", log_file
      puts ""
      puts "INP Import Error Details:"
      puts "-" * 70
      
      File.foreach(import_log_path) do |line|
        log "    #{line.strip}", log_file
        puts line
      end
      
      puts "-" * 70
      puts ""
    end
    
    puts ""
    puts "ERROR: Import failed"
    puts "Error: #{e.message}"
    puts ""
    puts "Check the INP import log above for specific errors."
    puts "Main log file: #{log_filename}"
    puts "INP import log: #{import_log_path}"
    puts ""
    
    log "  ERROR: Import exception: #{e.message}", log_file
    log "  Backtrace: #{e.backtrace.first(10).join("\n")}", log_file
    
    # Delete empty model group if it was created
    begin
      if model_group
        model_group.delete
        log "  Cleaned up partial import (deleted model group)", log_file
        puts "Cleaned up: Deleted empty model group"
      end
    rescue => cleanup_error
      log "  Could not cleanup: #{cleanup_error.message}", log_file
    end
    
    log_file.close
    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    
    puts ""
    puts "Import failed - exiting with error code 1"
    exit 1
  end

# =============================================================================
# STEP 8: CLEANUP TEMPORARY FILES
# =============================================================================
puts ""
puts "Step 5: Cleanup temporary files"
log "\nCleaning up temporary files...", log_file

begin
  FileUtils.rm_rf(temp_dir)
  log "  Temp directory deleted", log_file
  puts "  > Cleanup complete"
rescue => e
  log "  WARNING: Could not delete temp directory: #{e.message}", log_file
  puts "  > Warning: Could not delete temp files"
end

# =============================================================================
# IMPORT SUMMARY
# =============================================================================
log "\n" + "="*70, log_file
log "IMPORT COMPLETE", log_file
log "="*70, log_file
log "Model Group: #{group_name}", log_file
log "Objects Imported: #{imported_objects.length}", log_file
log "Log file: #{log_filename}", log_file
log "="*70, log_file

log_file.close

puts ""
puts "="*70
puts "  IMPORT COMPLETE"
puts "="*70
puts ""
puts "Model Group: #{group_name}"
puts "Objects Imported: #{imported_objects.length}"
puts ""
puts "Log file: #{log_filename}"
puts "="*70

exit 0

