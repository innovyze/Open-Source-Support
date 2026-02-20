# ===================================================================
# Export Rainfall Events to RED (native InfoWorks format)
# ===================================================================
#
# Exports all Rainfall Event objects from the database to .red files
# preserving full parent hierarchy. Creates manifest.csv for import.
#
# Innovyze Open Source Support | February 2026
# ===================================================================

# ===================================================================
# USER CONFIGURATION - Edit these paths before running
# ===================================================================

# Export folder where .red files will be saved
EXPORT_FOLDER = 'D:/TEMP'

# Database path (optional - leave empty to show picker dialog)
DATABASE_PATH = ''  # e.g., 'C:/Databases/MyDatabase.icmm' or 'localhost:40000/MyDatabase'

# ===================================================================
# Script begins here
# ===================================================================

require 'csv'
require 'fileutils'
require 'pathname'

# Start timing
start_time = Time.now

puts "=" * 70
puts "RAINFALL EVENT EXPORT TO RED (native format)"
puts "=" * 70
puts ""

# Check if running in Exchange mode
if WSApplication.ui?
  puts "ERROR: This script must be run from ICMExchange, not the UI."
  puts "       The model_object.export() method is only available in Exchange mode."
  exit
end

# Open database
if DATABASE_PATH.empty?
  db = WSApplication.open  # Shows database picker dialog
else
  db = WSApplication.open(DATABASE_PATH)
end

if db.nil?
  puts "ERROR: No database is currently open."
  exit
end

puts "Database: #{db.path}"
puts ""

# Use configured export folder
export_folder = File.expand_path(EXPORT_FOLDER)

# Check if folder exists, create if needed
unless Dir.exist?(export_folder)
  puts "Creating export folder: #{export_folder}"
  begin
    FileUtils.mkdir_p(export_folder)
    puts "OK Folder created successfully"
  rescue => e
    puts "ERROR: Could not create folder: #{e.message}"
    exit
  end
end

puts "Export folder: #{export_folder}"
puts ""
puts "Searching for Rainfall Events in database..."
puts "-" * 70

# -----------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------

# Sanitize filename to remove invalid characters
def sanitize_filename(name)
  begin
    sanitized = name.encode('ASCII', invalid: :replace, undef: :replace, replace: '_')
  rescue
    sanitized = name
  end
  sanitized = sanitized.gsub(/[\\\/:\*\?"<>\|]/, '_')
  sanitized.strip.gsub(/^\.+|\.+$/, '')
end

# Safely print strings to console (handles encoding issues on Windows)
def safe_puts(text)
  begin
    puts text.encode('CP850', invalid: :replace, undef: :replace, replace: '?')
  rescue
    puts text.encode('ASCII', invalid: :replace, undef: :replace, replace: '?')
  end
end

# Extract all parent container names from scripting path (all segments except RAIN~)
# Example: ">TDBG~Branch>MODG~Group>RAIN~Event" -> ["Branch", "Group"]
def extract_group_path(full_path)
  return [] if full_path.nil? || full_path.empty?

  segments = full_path.split('>')
  groups = []

  segments.each do |segment|
    next if segment.empty?

    # Match any "TYPE~Name" segment
    if segment =~ /^(\w+)~(.+)$/
      seg_type = $1
      seg_name = $2.gsub('\\~', '~').gsub('\\>', '>').gsub('\\\\', '\\')

      # Skip the leaf node (Rainfall Event) -- keep everything else
      next if seg_type == 'RAIN'

      groups << seg_name
    end
  end

  groups
end

# Create subfolder structure matching Model Group hierarchy
def ensure_folder_path(base_folder, group_segments)
  current_path = base_folder

  group_segments.each do |group_name|
    safe_name = sanitize_filename(group_name)
    current_path = File.join(current_path, safe_name)
    FileUtils.mkdir_p(current_path) unless Dir.exist?(current_path)
  end

  current_path
end

# Generate a unique file path by appending _2, _3, etc. to the base name
def unique_file_path(folder, base_name, extension, used_paths)
  candidate = File.join(folder, "#{base_name}#{extension}")
  return candidate unless used_paths.key?(candidate.downcase)

  counter = 2
  loop do
    candidate = File.join(folder, "#{base_name}_#{counter}#{extension}")
    return candidate unless used_paths.key?(candidate.downcase)
    counter += 1
    if counter > 10000
      candidate = File.join(folder, "#{base_name}_#{Time.now.to_i}#{extension}")
      break
    end
  end
  candidate
end

# -----------------------------------------------------------------
# Collect and deduplicate rainfall events
# -----------------------------------------------------------------

all_events = []
begin
  collection = db.model_object_collection('Rainfall Event')
  if collection
    collection.each { |mo| all_events << mo }
  end
rescue => e
  puts "ERROR: Could not access rainfall events: #{e.message}"
  exit
end

puts "Raw collection returned: #{all_events.size} entries"

# Deduplicate by scripting path (unique identifier for each model object)
seen_paths = {}
rainfall_events = []

all_events.each do |mo|
  obj_path = nil
  begin
    obj_path = mo.path
  rescue
    begin
      obj_path = mo.id.to_s
    rescue
      obj_path = "fallback_#{rainfall_events.size}"
    end
  end

  unless seen_paths.key?(obj_path)
    seen_paths[obj_path] = true
    rainfall_events << mo
  end
end

duplicates_skipped = all_events.size - rainfall_events.size
puts "Unique Rainfall Events:       #{rainfall_events.size}"
if duplicates_skipped > 0
  puts "Duplicate references skipped: #{duplicates_skipped}"
end
puts ""

if rainfall_events.empty?
  puts "No Rainfall Events found in the database."
  puts "Script completed."
  exit
end

# -----------------------------------------------------------------
# Export each rainfall event with hierarchy preservation
# -----------------------------------------------------------------

export_count = 0
file_count = 0
error_count = 0
errors = []
manifest = []
used_file_paths = {}  # Track ALL used file paths to prevent overwriting

rainfall_events.each do |rainfall_mo|
  event_name = nil

  begin
    event_name = rainfall_mo.name
    full_path = rainfall_mo.path

    # Extract Model Group hierarchy from path
    group_segments = extract_group_path(full_path)
    group_path_str = group_segments.join(' | ')

    # Sanitize the name for filesystem
    safe_name = sanitize_filename(event_name)
    if safe_name.nil? || safe_name.empty?
      safe_name = "unnamed_event_#{export_count}"
    end

    # Create subfolder matching Model Group hierarchy
    target_folder = ensure_folder_path(export_folder, group_segments)

    # Build unique export path - never overwrite an existing file
    red_path = unique_file_path(target_folder, safe_name, '.red', used_file_paths)
    red_filename = File.basename(red_path)
    used_file_paths[red_path.downcase] = true

    # Snapshot ALL files in the target folder before export
    existing_files = {}
    Dir.glob(File.join(target_folder, '*')).each do |f|
      existing_files[f] = true unless File.directory?(f)
    end

    # Export the rainfall event in native InfoWorks format
    rainfall_mo.export(red_path, '')

    # Detect all new files created after export
    new_files = []
    Dir.glob(File.join(target_folder, '*')).each do |f|
      next if File.directory?(f)
      next if existing_files.key?(f)
      new_files << f
    end

    # Also check: if the expected file existed before, it got overwritten
    # We count it as a new file if it was in our used_file_paths but not in existing_files snapshot
    if new_files.empty? && File.exist?(red_path)
      new_files << red_path
    end

    if new_files.size > 1
      # Multi-file export detected (multi-profile rainfall event)
      # Create subfolder named after event and move all profile files into it
      safe_subfolder_name = sanitize_filename(event_name)
      event_subfolder = File.join(target_folder, safe_subfolder_name)

      # Handle subfolder name collision
      if Dir.exist?(event_subfolder)
        counter = 2
        loop do
          event_subfolder = File.join(target_folder, "#{safe_subfolder_name}_#{counter}")
          break unless Dir.exist?(event_subfolder)
          counter += 1
          break if counter > 1000
        end
      end

      FileUtils.mkdir_p(event_subfolder)

      new_files.each do |file_path|
        filename = File.basename(file_path)
        dest_path = File.join(event_subfolder, filename)

        # Handle collision inside the subfolder
        if File.exist?(dest_path)
          base = File.basename(filename, File.extname(filename))
          ext = File.extname(filename)
          counter = 2
          loop do
            dest_path = File.join(event_subfolder, "#{base}_#{counter}#{ext}")
            break unless File.exist?(dest_path)
            counter += 1
            break if counter > 1000
          end
        end

        FileUtils.mv(file_path, dest_path)
        used_file_paths[dest_path.downcase] = true

        # Add each profile file to manifest
        # Use the file's basename (without extension) as the event_name for import
        relative_path = Pathname.new(dest_path).relative_path_from(Pathname.new(export_folder)).to_s
        profile_name = File.basename(dest_path, File.extname(dest_path))

        manifest << {
          file_path: relative_path.gsub('\\', '/'),
          event_name: profile_name,
          group_path: group_path_str,
          is_multi_file: true,
          original_event: event_name
        }

        file_count += 1
      end

      export_count += 1
      safe_puts "Exported: #{event_name} -> #{File.basename(event_subfolder)}/ (#{new_files.size} profile files)"

    elsif new_files.size == 1
      # Single file export
      actual_file = new_files[0]
      used_file_paths[actual_file.downcase] = true

      relative_path = Pathname.new(actual_file).relative_path_from(Pathname.new(export_folder)).to_s

      manifest << {
        file_path: relative_path.gsub('\\', '/'),
        event_name: File.basename(actual_file, File.extname(actual_file)),
        group_path: group_path_str,
        is_multi_file: false,
        original_event: event_name
      }

      file_count += 1
      export_count += 1
      safe_puts "Exported: #{event_name} -> #{File.basename(actual_file)}"

    else
      error_count += 1
      msg = "WARNING: Export of '#{event_name}' created no detectable files"
      safe_puts msg
      errors << msg
    end

  rescue => e
    error_count += 1
    safe_event_name = begin
      event_name.encode('ASCII', invalid: :replace, undef: :replace, replace: '?')
    rescue
      'UNKNOWN'
    end
    error_msg = "ERROR exporting '#{safe_event_name}': #{e.class.name} - #{e.message}"
    safe_puts error_msg
    errors << error_msg
  end
end

# -----------------------------------------------------------------
# Write manifest CSV file
# -----------------------------------------------------------------

manifest_path = File.join(export_folder, 'manifest.csv')
begin
  CSV.open(manifest_path, 'wb') do |csv|
    csv << ['file_path', 'event_name', 'group_path', 'is_multi_file', 'original_event']
    manifest.each do |entry|
      csv << [entry[:file_path], entry[:event_name], entry[:group_path], entry[:is_multi_file], entry[:original_event]]
    end
  end
  puts ""
  puts "Manifest file created: manifest.csv (#{manifest.size} entries)"
rescue => e
  puts "WARNING: Could not create manifest file: #{e.message}"
end

# -----------------------------------------------------------------
# Summary
# -----------------------------------------------------------------

end_time = Time.now
elapsed = end_time - start_time

puts ""
puts "=" * 70
puts "EXPORT SUMMARY"
puts "=" * 70
puts "Collection Returned:         #{all_events.size} entries"
puts "Duplicates Skipped:          #{duplicates_skipped}"
puts "Unique Rainfall Events:      #{rainfall_events.size}"
puts "Successfully Exported:       #{export_count}"
puts "Total Files Created:         #{file_count}"
puts "Manifest Entries:            #{manifest.size}"
puts "Failed:                      #{error_count}"
puts "Export Folder:               #{export_folder}"
puts "Export Format:               RED (native InfoWorks)"
puts "Hierarchy Preserved:         Yes"
puts "Script Runtime:              #{format('%.2f', elapsed)} seconds"
puts "=" * 70

if error_count > 0
  puts ""
  puts "ERRORS ENCOUNTERED:"
  errors.each { |err| safe_puts "  #{err}" }
end

puts ""
puts "Export complete!"
