# Native DBF File Reader
# Reads FoxPro 2.x DBF files without requiring Excel
#
# NOTE: This embedded Ruby build (InfoWorks ICM 2027.1.0, Ruby 3.4.6,
# x64-mswin64_140) raises NoMethodError for String#unpack, so all binary
# values below are decoded manually via String#getbyte instead.

# Reads a little-endian unsigned integer from raw bytes (replaces String#unpack('V')/('v')/('C'))
#
# @param bytes [String] raw binary string (1-4 bytes)
# @return [Integer] the decoded unsigned integer
def unpack_uint_le(bytes)
  value = 0
  index = 0
  while index < bytes.bytesize
    value += bytes.getbyte(index) << (8 * index)
    index += 1
  end
  value
end

# Extracts a null-terminated string from raw bytes (replaces String#unpack('Z*'))
#
# @param bytes [String] raw binary string
# @return [String] the string up to (but not including) the first null byte
def unpack_null_terminated_string(bytes)
  index = 0
  while index < bytes.bytesize
    return bytes[0, index] if bytes.getbyte(index) == 0
    index += 1
  end
  bytes
end

# NOTE: On this embedded Ruby build (InfoWorks ICM 2027.1.0), every Dir
# method that lists folder contents (Dir.glob, Dir.entries, Dir.foreach,
# Dir.new, Dir.new+#each/#read, Dir[]) raises NoMethodError - only
# Dir.exist? works. So instead of discovering DBF files by listing the
# IEDB folder, we build a list of the DBF table names we actually expect
# (from the field mapping JSON configs plus the fixed set read directly
# for BASE geometry) and probe for each one with File.exist?, exactly like
# scenario_import.rb already does for scenario-specific DBFs.

# Base set of DBF table names read directly for BASE network geometry
# (see get_network_geometry / import_unit_hydrographs in InfoSewer_Import_UI.rb)
# NOTE: This file is loaded (not required) and may run more than once per
# ICM session, so ||= avoids an "already initialized constant" warning.
BASE_DBF_NAMES ||= ['node', 'manhole', 'wwell', 'vertex', 'link', 'pipe', 'pump', 'hydrogrh', 'scenario']

# Builds the full list of DBF table names that might need to be read, combining
# the fixed BASE set with every table name referenced under 'import' in the
# field mapping configs (e.g. pipehyd, pumphyd, wwellhyd, mhhyd, control)
#
# @param field_maps [Hash] the parsed field mapping config (see get_field_maps)
# @return [Array<String>] unique, lowercase DBF table names
def get_known_dbf_names(field_maps)
  names = BASE_DBF_NAMES.dup
  
  if field_maps.is_a?(Hash)
    field_maps.each_value do |fields|
      next unless fields.is_a?(Hash) && fields['import'].is_a?(Hash)
      fields['import'].each_key { |table_name| names << table_name.downcase }
    end
  end
  
  names.uniq
end

# Finds a DBF file for a given table name, trying common case variants
# (DBF filenames are usually all-uppercase, but this is not guaranteed)
#
# @param iedb_path [String] path to the .IEDB folder
# @param name [String] the table name (lowercase, no extension)
# @return [String, nil] the full path if found, nil otherwise
def find_dbf_file(iedb_path, name)
  candidates = [
    File.join(iedb_path, name.upcase + '.DBF'),
    File.join(iedb_path, name.upcase + '.dbf'),
    File.join(iedb_path, name.downcase + '.dbf'),
    File.join(iedb_path, name.downcase + '.DBF')
  ].uniq
  
  candidates.each do |candidate|
    return candidate if File.exist?(candidate)
  end
  
  nil
end

# Makes a string safe for use as a file/object name
# Removes problematic characters like pipes and exclamation marks
# Replaces ALL dots with underscores (ICM node IDs cannot have dots)
#
# @param string [String] the string to make safe
# @param track_changes [Boolean] whether to track changes in $sanitized_ids global
# @return [String] the safe string
def make_string_filesafe(string, track_changes: false)
  return string if string.nil?
  
  original = string.dup
  
  # Remove pipes and exclamation marks
  safe = string.gsub(/^.*(|)!/, '')
  
  # ICM node IDs cannot have ANY dots - dots are reserved for compound link IDs (us_node.suffix)
  # Replace ALL dots with underscores to ensure compatibility
  safe = safe.gsub('.', '_')
  
  # Track sanitization if requested
  if track_changes && original != safe
    $sanitized_ids ||= []
    $sanitized_ids << {original: original, sanitized: safe}
  end
  
  return safe
end

# Reads a DBF file and returns data in the same format as CSV.parse
#
# @param file_path [String] path to the DBF file
# @param hash_by_id [Boolean] Creates a hash of the rows, where each row can be identified by its ID
# @param make_id_safe [Boolean] Update all ID's to be filesafe i.e. remove problematic characters
# @return [Array or Hash] Returns an array of hashes when hash_by_id is false, hash when true
#
# Returns array of hashes like: [{'ID' => 'MH1', 'DIAMETER' => '4', ...}, ...]
# Same format as CSV.parse(file, headers: true).map(&:to_h)

def read_dbf(file_path, hash_by_id, make_id_safe: true)
  unless File.exist?(file_path)
    puts "WARNING: DBF file not found: #{file_path}"
    return hash_by_id ? Hash.new : []
  end
  
  data = parse_dbf_file(file_path)
  
  if make_id_safe && data.is_a?(Array)
    data.each { |row| row['ID'] = make_string_filesafe(row['ID'], track_changes: true) if row['ID'] }
  end
  
  if hash_by_id
    hash = Hash.new
    data.each { |row| hash[row['ID']] = row if row['ID'] }
    return hash
  end
  
  return data
end

# Reads a time-series DBF (like PATNDATA.DBF) with ID and SEQ columns
#
# @param file_path [String] path to the file
# @param hash_by_id [Boolean] Creates nested hash by ID then SEQ
# @return [Hash] Hash of ID => {SEQ => row_data}

def read_dbf_ts(file_path, hash_by_id, make_id_safe: true)
  unless File.exist?(file_path)
    puts "WARNING: DBF file not found: #{file_path}"
    return Hash.new
  end
  
  data = parse_dbf_file(file_path)
  
  if make_id_safe && data.is_a?(Array)
    data.each { |row| row['ID'] = make_string_filesafe(row['ID'], track_changes: true) if row['ID'] }
  end
  
  if hash_by_id
    hash = Hash.new { |h, k| h[k] = {} }
    data.each do |row|
      id = row['ID']
      seq = row['SEQ']
      hash[id][seq] = row if id && seq
    end
    return hash
  end
  
  return data
end

# Core DBF parser - reads binary DBF file and returns array of hashes
#
# @param file_path [String] path to the DBF file
# @return [Array<Hash>] array of record hashes with field names as keys
#
# DBF Format (FoxPro 2.x):
#   Header: 32 bytes
#     - Byte 0: Version (0x02 = FoxPro 2.x, 0x03 = FoxPro 3.x)
#     - Bytes 1-3: Last update (YYMMDD)
#     - Bytes 4-7: Number of records (32-bit little-endian)
#     - Bytes 8-9: Header length in bytes (16-bit little-endian)
#     - Bytes 10-11: Record length in bytes (16-bit little-endian)
#     - Bytes 12-31: Reserved
#   Field Descriptors: 32 bytes each, terminated by 0x0D
#     - Bytes 0-10: Field name (null-terminated string, max 10 chars)
#     - Byte 11: Field type (C=Char, N=Numeric, L=Logical, D=Date, M=Memo)
#     - Bytes 12-15: Reserved
#     - Byte 16: Field length
#     - Bytes 17-31: Decimals + reserved
#   Records: record_length bytes each
#     - Byte 0: Delete flag ('*' = deleted, ' ' = active)
#     - Remaining bytes: field data

def parse_dbf_file(file_path)
  records = []
  
  File.open(file_path, 'rb') do |file|
    # Read DBF header (32 bytes)
    version = file.read(1)
    raise "DBF file is empty or unreadable: #{file_path}" if version.nil?
    
    last_update = file.read(3)  # YYMMDD
    num_records_bytes = file.read(4)
    header_length_bytes = file.read(2)
    record_length_bytes = file.read(2)
    
    raise "DBF header is incomplete: #{file_path}" if num_records_bytes.nil? || header_length_bytes.nil? || record_length_bytes.nil?
    
    # Decode binary values (32-bit and 16-bit unsigned, little-endian)
    num_records = unpack_uint_le(num_records_bytes)
    header_length = unpack_uint_le(header_length_bytes)
    record_length = unpack_uint_le(record_length_bytes)
    
    file.read(20)  # Skip reserved bytes (12-31)
    
    # Read field descriptors (start at byte 32)
    fields = []
    field_offset = 1  # First byte of each record is delete flag
    
    while true
      field_name_bytes = file.read(11)
      
      # Check for end of field descriptors (0x0D terminator or end of header)
      break if field_name_bytes.nil? || field_name_bytes[0] == "\r" || field_name_bytes[0] == "\x0D"
      
      # Null-terminated string, max 11 bytes
      field_name = unpack_null_terminated_string(field_name_bytes)
      break if field_name.nil? || field_name.empty?
      
      field_type = file.read(1)
      file.read(4)  # Reserved
      field_length = unpack_uint_le(file.read(1))  # 8-bit unsigned
      file.read(15)  # Decimals + reserved
      
      fields << {
        name: field_name.strip.upcase,  # Normalize to uppercase for consistency
        type: field_type,
        offset: field_offset,
        length: field_length
      }
      
      field_offset += field_length
    end
    
    # Validate we found fields
    raise "No fields found in DBF file: #{file_path}" if fields.empty?
    
    # Skip to start of data records
    file.seek(header_length)
    
    # Read each record
    record_index = 0
    while record_index < num_records
      record_bytes = file.read(record_length)
      
      # Skip if we couldn't read the full record or if it's marked as deleted
      unless record_bytes.nil? || record_bytes.length < record_length || record_bytes[0] == '*'
        # Parse field values from record bytes
        record = {}
        fields.each do |field|
          raw_value = record_bytes[field[:offset], field[:length]]
          
          # Parse based on field type
          value = case field[:type]
          when 'C'  # Character
            raw_value.strip
          when 'N', 'F'  # Numeric, Float
            raw_value.strip
            # Leave as string for now - Ruby will auto-convert when needed
            # This matches CSV behavior
          when 'L'  # Logical
            case raw_value.strip.upcase
            when 'T', 'Y'
              'T'
            when 'F', 'N'
              'F'
            else
              ''
            end
          when 'D'  # Date (YYYYMMDD)
            raw_value.strip
          when 'M'  # Memo (just return the reference number)
            raw_value.strip
          else
            raw_value.strip
          end
          
          record[field[:name]] = value
        end
        
        records << record
      end
      
      record_index += 1
    end
  end
  
  return records
  
rescue => err
  puts "ERROR reading DBF file #{file_path}: #{err.message}"
  puts "  #{err.backtrace[0]}"
  return []
end

# Gets DBF files and returns a hash mapping to their filepaths
#
# @param model_path [String] path to the IEDB folder
# @param field_maps [Hash, nil] parsed field mapping config, used to discover
#   additional table names beyond the fixed BASE set (see get_known_dbf_names)
# @return [Hash] hash of DBF names (lowercase, no extension) to their filepath
#
# Only returns root-level DBFs for BASE scenario import
# Scenario-specific DBFs (in subfolders) are accessed directly during scenario import

def get_dbf_files(model_path, field_maps = nil)
  # Ensure we're working with the .IEDB folder
  iedb_path = model_path
  unless model_path.end_with?('.IEDB') || model_path.end_with?('.iedb')
    iedb_path = File.join(File.dirname(model_path), File.basename(model_path, '.*') + '.IEDB')
  end
  
  raise "Cannot find IEDB folder: #{iedb_path}" unless Dir.exist?(iedb_path)
  
  # Create a hash of DBF names (in lowercase with no extension) to their filepath
  # Only include root-level DBFs for BASE scenario import.
  # NOTE: Directory listing (Dir.glob/entries/foreach/new) is broken on this
  # embedded Ruby build, so known/expected table names are probed directly
  # with File.exist? instead of discovering files by listing the folder.
  dbf = Hash.new
  get_known_dbf_names(field_maps).each do |name|
    next if dbf.key?(name)
    file = find_dbf_file(iedb_path, name)
    dbf[name] = file if file
  end
  
  return dbf
end

