# ===================================================================
# Import Rainfall Events from RED (native InfoWorks format)
# ===================================================================
#
# Imports Rainfall Event objects from .red files recreating hierarchy
# under a configurable root group. On name conflicts, creates sibling
# groups with _2 suffix rather than renaming events.
#
# Innovyze Open Source Support | February 2026
# ===================================================================

# ===================================================================
# USER CONFIGURATION - Edit these paths before running
# ===================================================================

# Folder containing .red files and manifest.csv to import
IMPORT_FOLDER = 'D:/TEMP'

# Root Model Group name under which all imports are placed
IMPORT_ROOT_GROUP = 'Imported Rainfall'

# Database path (optional - leave empty to show picker dialog)
DATABASE_PATH = ''  # e.g., 'C:/Databases/MyDatabase.icmm' or 'localhost:40000/MyDatabase'

# ===================================================================
# Script begins here
# ===================================================================

require 'csv'

start_time = Time.now

puts "=" * 70
puts "RAINFALL EVENT IMPORT FROM RED (native format)"
puts "=" * 70
puts ""

# Check if running in Exchange mode
if WSApplication.ui?
  puts "ERROR: This script must be run from ICMExchange, not the UI."
  puts "       The import_new_model_object() method is only available in Exchange mode."
  exit
end

# Open database
if DATABASE_PATH.empty?
  db = WSApplication.open
else
  db = WSApplication.open(DATABASE_PATH)
end

if db.nil?
  puts "ERROR: No database is currently open."
  exit
end

puts "Database: #{db.path}"
puts ""

# Validate import folder
import_folder = File.expand_path(IMPORT_FOLDER)

unless Dir.exist?(import_folder)
  puts "ERROR: Import folder does not exist: #{import_folder}"
  exit
end

puts "Import folder: #{import_folder}"
puts "Import root group: #{IMPORT_ROOT_GROUP}"
puts ""

# -----------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------

# Safely print strings to console (handles encoding issues on Windows)
def safe_puts(text)
  begin
    puts text.encode('CP850', invalid: :replace, undef: :replace, replace: '?')
  rescue
    puts text.encode('ASCII', invalid: :replace, undef: :replace, replace: '?')
  end
end

# Sanitize name for InfoWorks (ASCII-safe)
def sanitize_name(name)
  begin
    sanitized = name.encode('ASCII', invalid: :replace, undef: :replace, replace: '_')
  rescue
    sanitized = name
  end
  sanitized = sanitized.gsub(/[\\\/:*?"<>|]/, '_').strip
  sanitized.empty? ? "unnamed_#{Time.now.to_i}" : sanitized
end

# -----------------------------------------------------------------
# Find or create the root import group
# -----------------------------------------------------------------

def find_or_create_root_group(db, root_name)
  # Search existing root objects
  db.root_model_objects.each do |root_obj|
    if root_obj.type == 'Model Group' && root_obj.name == root_name
      return root_obj
    end
  end

  # Not found - create it
  begin
    new_grp = db.new_model_object('Model Group', root_name)
    if new_grp
      puts "  + Created root group: #{root_name}"
      return new_grp
    end
  rescue => e
    puts "  ERROR creating root group: #{e.class.name} - #{e.message}"
  end

  nil
end

# -----------------------------------------------------------------
# Navigate/create a Model Group hierarchy under a given parent
# -----------------------------------------------------------------

# Find a child Model Group by name under a parent
def find_child_group(parent, name)
  begin
    parent.children.each do |child|
      if child.type == 'Model Group' && child.name == name
        return child
      end
    end
  rescue
    # children may not be available
  end
  nil
end

# Create a child Model Group under a parent
def create_child_group(parent, name)
  begin
    return parent.new_model_object('Model Group', name)
  rescue => e
    safe_puts "  ERROR creating group '#{name}': #{e.class.name} - #{e.message}"
  end
  nil
end

# Walk or create the full group path under import_root.
# group_path_str: pipe-delimited, e.g. "Branch A | Group B | Sub C"
# Returns the deepest group.
def ensure_group_hierarchy(import_root, group_path_str)
  return import_root if group_path_str.nil? || group_path_str.strip.empty?

  raw_segments = group_path_str.split('|')
  segments = []
  raw_segments.each do |seg|
    trimmed = seg.strip
    segments << trimmed unless trimmed.empty?
  end
  return import_root if segments.empty?

  current = import_root

  segments.each do |group_name|
    child = find_child_group(current, group_name)
    if child.nil?
      child = create_child_group(current, group_name)
      if child.nil?
        safe_puts "  ERROR: Could not create group '#{group_name}'"
        return nil
      end
    end
    current = child
  end

  current
end

# -----------------------------------------------------------------
# Local name tracking (parent.children doesn't refresh after import)
# -----------------------------------------------------------------

$name_registry = {}  # group_key -> { lowercase_name => true }

# Build a unique key for a group (root_group + path + any suffix)
def group_key(group_path, suffix = '')
  "#{group_path}#{suffix}"
end

# Load existing children names from a group (called once per group)
def load_existing_names(group, gkey)
  return if $name_registry.key?(gkey)

  names = {}
  begin
    group.children.each do |child|
      if child.type == 'Rainfall Event'
        names[child.name.downcase] = true
      end
    end
  rescue
    # If children not accessible, start empty
  end
  $name_registry[gkey] = names
end

# Check if a name is taken in a group (using our local registry)
def name_taken?(gkey, name)
  return false unless $name_registry.key?(gkey)
  $name_registry[gkey].key?(name.downcase)
end

# Register a name as used in a group
def register_name(gkey, name)
  $name_registry[gkey] ||= {}
  $name_registry[gkey][name.downcase] = true
end

# -----------------------------------------------------------------
# Conflict resolution: create sibling groups on name conflicts
# -----------------------------------------------------------------

# Creates/finds sibling group with _2, _3 suffix to preserve event names
# Returns [new_group, new_gkey]
def find_or_create_sibling_group(parent_group, leaf_name, gkey_base)
  counter = 2
  loop do
    sibling_name = "#{leaf_name}_#{counter}"
    sibling_gkey = "#{gkey_base}_#{counter}"

    sibling = find_child_group(parent_group, sibling_name)
    if sibling.nil?
      sibling = create_child_group(parent_group, sibling_name)
      if sibling
        safe_puts "  + Created sibling group: #{sibling_name}"
        load_existing_names(sibling, sibling_gkey)
        return [sibling, sibling_gkey]
      else
        return [nil, nil]
      end
    else
      # Sibling exists, check if it has room (name not taken there)
      load_existing_names(sibling, sibling_gkey)
      return [sibling, sibling_gkey]
    end

    counter += 1
    break if counter > 1000
  end
  [nil, nil]
end

# -----------------------------------------------------------------
# Read manifest
# -----------------------------------------------------------------

puts "=" * 70
puts "READING MANIFEST FILE"
puts "=" * 70

manifest_path = File.join(import_folder, 'manifest.csv')

unless File.exist?(manifest_path)
  puts "ERROR: manifest.csv not found in import folder."
  puts "       Expected: #{manifest_path}"
  puts "       Run the export script first to generate it."
  exit
end

manifest_entries = []
begin
  CSV.foreach(manifest_path, headers: true) do |row|
    manifest_entries << {
      file_path:      row['file_path'] || '',
      event_name:     row['event_name'] || '',
      group_path:     row['group_path'] || '',
      is_multi_file:  (row['is_multi_file'] == 'true'),
      original_event: row['original_event'] || row['event_name'] || ''
    }
  end
  puts "Loaded #{manifest_entries.size} entries from manifest.csv"
rescue => e
  puts "ERROR: Failed to read manifest.csv: #{e.class.name} - #{e.message}"
  exit
end

if manifest_entries.empty?
  puts "No entries found in manifest.csv. Nothing to import."
  exit
end

# Deduplicate manifest entries by file_path
seen_files = {}
unique_entries = []
dup_manifest_count = 0

manifest_entries.each do |entry|
  key = entry[:file_path].downcase
  if seen_files.key?(key)
    dup_manifest_count += 1
  else
    seen_files[key] = true
    unique_entries << entry
  end
end

if dup_manifest_count > 0
  puts "Duplicate manifest entries removed: #{dup_manifest_count}"
end
puts "Unique files to import: #{unique_entries.size}"
puts ""

# -----------------------------------------------------------------
# Create root import group
# -----------------------------------------------------------------

puts "=" * 70
puts "PREPARING DATABASE"
puts "=" * 70

import_root = find_or_create_root_group(db, IMPORT_ROOT_GROUP)
if import_root.nil?
  puts "ERROR: Could not create or access root group '#{IMPORT_ROOT_GROUP}'"
  exit
end
puts "  OK Root group ready: #{IMPORT_ROOT_GROUP}"
puts ""

# -----------------------------------------------------------------
# Import rainfall events
# -----------------------------------------------------------------

puts "=" * 70
puts "IMPORTING RAINFALL EVENTS"
puts "=" * 70
puts ""

import_count = 0
error_count = 0
import_log = []
groups_ensured = {}

unique_entries.each_with_index do |entry, index|
  file_path_rel = entry[:file_path]
  event_name    = entry[:event_name]
  group_path    = entry[:group_path]
  is_multi_file = entry[:is_multi_file]

  begin
    # Build full path to the .red file
    full_file_path = File.join(import_folder, file_path_rel)

    unless File.exist?(full_file_path)
      error_count += 1
      safe_puts "  X File not found: #{file_path_rel}"
      import_log << { file: file_path_rel, event_name: event_name, status: 'FAILED: File not found' }
      next
    end

    # Ensure the Model Group hierarchy exists under import root
    target_group = ensure_group_hierarchy(import_root, group_path)

    if target_group.nil?
      error_count += 1
      safe_puts "  X Could not create group hierarchy for: #{event_name}"
      import_log << { file: file_path_rel, event_name: event_name, status: 'FAILED: No target group' }
      next
    end

    # Build group key for name tracking
    gkey = group_key(group_path)

    # Log group hierarchy (once per unique path)
    unless groups_ensured.key?(gkey)
      groups_ensured[gkey] = true
      safe_puts "  + Group ready: #{group_path.empty? ? '(root)' : group_path}"
      load_existing_names(target_group, gkey)
    end

    # Determine import name
    safe_name = sanitize_name(event_name)
    if safe_name.nil? || safe_name.empty?
      safe_name = "imported_#{index}"
    end

    # Check for naming conflict
    actual_group = target_group
    actual_gkey = gkey

    if name_taken?(actual_gkey, safe_name)
      # Conflict! Create a sibling group with _2, _3 suffix
      # We need the parent of target_group and the leaf group name

      # Parse out the leaf segment and parent path
      raw_segments = group_path.split('|')
      path_segments = []
      raw_segments.each do |seg|
        trimmed = seg.strip
        path_segments << trimmed unless trimmed.empty?
      end

      if path_segments.empty?
        # Target is the import root itself - create sibling under import root
        # This shouldn't normally happen, but handle it
        actual_group, actual_gkey = find_or_create_sibling_group(
          import_root, IMPORT_ROOT_GROUP, gkey
        )
      else
        leaf_name = path_segments.last

        # Get the parent group (everything except the last segment)
        parent_path = path_segments[0..-2].join(' | ')
        parent_group = ensure_group_hierarchy(import_root, parent_path)

        if parent_group
          # Try sibling groups _2, _3, etc. until we find one where the name fits
          counter = 2
          found_slot = false
          loop do
            sibling_name = "#{leaf_name}_#{counter}"
            sibling_gkey = "#{gkey}_#{counter}"

            sibling = find_child_group(parent_group, sibling_name)
            if sibling.nil?
              sibling = create_child_group(parent_group, sibling_name)
              if sibling
                safe_puts "  + Created sibling group: #{sibling_name}"
                load_existing_names(sibling, sibling_gkey)
                actual_group = sibling
                actual_gkey = sibling_gkey
                found_slot = true
                break
              else
                break  # Creation failed
              end
            else
              # Sibling exists - check if our name fits there
              load_existing_names(sibling, sibling_gkey)
              unless name_taken?(sibling_gkey, safe_name)
                actual_group = sibling
                actual_gkey = sibling_gkey
                found_slot = true
                break
              end
              # Name also taken in this sibling, try next one
            end

            counter += 1
            break if counter > 1000
          end

          unless found_slot
            # Fallback: use the original group with a renamed event
            actual_group = target_group
            actual_gkey = gkey
            suffix = 2
            loop do
              candidate = "#{safe_name}_#{suffix}"
              unless name_taken?(actual_gkey, candidate)
                safe_name = candidate
                break
              end
              suffix += 1
              break if suffix > 10000
            end
          end
        end
      end
    end

    # Import the rainfall event
    actual_group.import_new_model_object('Rainfall Event', safe_name, '', full_file_path)

    # Register immediately in our local tracker
    register_name(actual_gkey, safe_name)

    import_count += 1

    begin
      safe_puts "  OK [#{import_count}] #{safe_name} -> #{group_path.empty? ? '(root)' : group_path}"
    rescue
      puts "  OK [#{import_count}] (entry #{index + 1})"
    end

    import_log << {
      file: file_path_rel,
      event_name: event_name,
      imported_as: safe_name,
      group: group_path,
      multi_file: is_multi_file,
      status: 'SUCCESS'
    }

  rescue => e
    error_count += 1
    begin
      safe_puts "  X ERROR '#{file_path_rel}': #{e.class.name} - #{e.message}"
    rescue
      puts "  X ERROR (entry #{index + 1}): #{e.class.name}"
    end
    import_log << { file: file_path_rel, event_name: event_name, status: "FAILED: #{e.class.name}" }
  end
end

# -----------------------------------------------------------------
# Summary
# -----------------------------------------------------------------

end_time = Time.now
elapsed = end_time - start_time

puts ""
puts "=" * 70
puts "IMPORT SUMMARY"
puts "=" * 70
puts "Manifest Entries:        #{manifest_entries.size}"
puts "Duplicate Entries Removed: #{dup_manifest_count}"
puts "Unique Files to Import:  #{unique_entries.size}"
puts "Successfully Imported:   #{import_count}"
puts "Failed:                  #{error_count}"
puts "Group Hierarchies Used:  #{groups_ensured.size}"
puts "Import Root Group:       #{IMPORT_ROOT_GROUP}"
puts "Import Folder:           #{import_folder}"
puts "Format:                  RED (native InfoWorks)"
puts "Script Runtime:          #{format('%.2f', elapsed)} seconds"
puts "=" * 70

if error_count > 0
  puts ""
  puts "ERRORS:"
  import_log.each do |entry|
    next if entry[:status] == 'SUCCESS'
    begin
      safe_puts "  #{entry[:event_name]} - #{entry[:status]}"
      safe_puts "    File: #{entry[:file]}"
    rescue
      puts "  (entry) - #{entry[:status]}"
    end
  end
end

puts ""
puts "Import complete!"
puts ""
puts "All imported Rainfall Events are under the '#{IMPORT_ROOT_GROUP}' Model Group."
