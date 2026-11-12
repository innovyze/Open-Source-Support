require 'json'
# NOTE: 'fileutils' is intentionally NOT required here. On this embedded Ruby
# build (InfoWorks ICM 2027.1.0, Ruby 3.4.6, x64-mswin64_140) the Symbol#to_s
# bug corrupts Ruby's own internal error/source formatting, which causes
# fileutils.rb's module_eval-based method definitions to raise a bogus
# SyntaxError on require (e.g. "def #<Symbol:0x...>(*args, **options)").
# FileUtils is not actually used anywhere in this tool - only core File/Dir
# methods are - so it is safe to skip loading it entirely.

# Gets DBF files and returns a hash mapping to their filepaths
#
# @param model_path [String] path to the IEDB folder we want to import
# @return [Hash] hash of DBF names (lowercase, no extension) to their filepath

def get_dbf_files_for_import(model_path)
  begin
    # Ensure we're working with the .IEDB folder
    iedb_path = model_path
    unless model_path.end_with?('.IEDB') || model_path.end_with?('.iedb')
      iedb_path = File.join(File.dirname(model_path), File.basename(model_path, '.*') + '.IEDB')
    end
    
    raise "Cannot find IEDB folder: #{iedb_path}" unless Dir.exist?(iedb_path)
    
    puts "\n[OK] Reading InfoSewer model data"
    return get_dbf_files(iedb_path, $field_maps)
  rescue => err
    puts "ERROR in get_dbf_files_for_import: #{err.message}"
    puts "  #{err.backtrace[0..2].join("\n  ")}"
    raise err
  end
end

# Reads an InfoSewer DBF file using native binary parser
# Alias for read_dbf() - name kept for backward compatibility
#
# @param file [String] path to the DBF file
# @param hash_by_id [Boolean] Creates a hash of the rows, where each row can be identified by it's ID
# @param make_id_safe [Boolean] Update all ID's to be filesafe i.e. remove problematic characters
# @return [Array or Hash] Returns an array of rows when hash_by_id is false, hash when true

def read_csv(file, hash_by_id, make_id_safe: true)
  return read_dbf(file, hash_by_id, make_id_safe: make_id_safe)
end

# Reads a time-series DBF file with ID and SEQ columns
# Alias for read_dbf_ts() - name kept for backward compatibility
#
# @param file [String] path to the DBF file
# @param hash_by_id [Boolean] Creates nested hash by ID then SEQ
# @return [Hash] Hash of ID => {SEQ => row_data}

def read_csv_ts(file, hash_by_id, make_id_safe: true)
  return read_dbf_ts(file, hash_by_id, make_id_safe: make_id_safe)
end

# Check if a file or directory exists
#
# @param path [String] path to check
# @return [Boolean] whether the file/directory exists

def file_exists?(path)
  return false if path.nil? || !path.is_a?(String)
  return File.exist?(path) || Dir.exist?(path)
end

# Converts a filepath to Windows-style (backwards slash directory seperators)
#
# @param path [String] path to convert
# @return [String, nil] the converted path, nil if path is not a string

def path_to_win(path)
  return path.gsub('/', '\\') if path.is_a?(String)
end

# Converts a filepath to Ruby/Unix-style (forward slash directory seperators)
#
# @param path [String] path to convert
# @return [String, nil] the converted path, nil if path is not a string

def path_to_unix(path)
  return path.gsub('\\', '/') if path.is_a?(String)
end


# Gets the field maps for each type of object (see readme.md for details).
#
# @param base_path [String] the folder to read from
# @param types [Array of Strings] the object types, which should match the name
#   of each file, i.e. object 'manhole' should be 'manhole.json'
# @return [Hash] Hash of each object type to the contents of it's '.json' file

def get_field_maps(base_path, types)
  mappings = Hash.new
  
  types.each do |type|
    path = File.join(base_path, type + '.json')
    map = nil
    
    begin
      map = JSON.parse(File.read(path))
      raise "Missing table in field config for #{type}" if map['table'].nil?
      mappings[type] = map
    rescue => err
      puts "WARNING: Failed to read field config for #{type} at #{path}"
      puts "  Error: #{err.message}"
    end
  end
  
  return mappings
end

