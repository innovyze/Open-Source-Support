# Native DBF File Reader
# Reads FoxPro 2.x DBF files without requiring Excel
# Based on proven implementation from InfoSWMM Import tool

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
    
    # Unpack binary values
    # 'V' = 32-bit unsigned, little-endian (for record count)
    # 'v' = 16-bit unsigned, little-endian (for lengths)
    num_records = num_records_bytes.unpack('V')[0]
    header_length = header_length_bytes.unpack('v')[0]
    record_length = record_length_bytes.unpack('v')[0]
    
    file.read(20)  # Skip reserved bytes (12-31)
    
    # Read field descriptors (start at byte 32)
    fields = []
    field_offset = 1  # First byte of each record is delete flag
    
    loop do
      field_name_bytes = file.read(11)
      
      # Check for end of field descriptors (0x0D terminator or end of header)
      break if field_name_bytes.nil? || field_name_bytes[0] == "\r" || field_name_bytes[0] == "\x0D"
      
      # 'Z11' = null-terminated string, max 11 bytes
      field_name = field_name_bytes.unpack('Z11')[0]
      break if field_name.nil? || field_name.empty?
      
      field_type = file.read(1)
      file.read(4)  # Reserved
      field_length = file.read(1).unpack('C')[0]  # 'C' = 8-bit unsigned
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
    num_records.times do |i|
      record_bytes = file.read(record_length)
      
      # Skip if we couldn't read the full record or if it's marked as deleted
      next if record_bytes.nil? || record_bytes.length < record_length
      next if record_bytes[0] == '*'  # Deleted record marker
      
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
# @return [Hash] hash of DBF names (lowercase, no extension) to their filepath
#
# Only returns root-level DBFs for BASE scenario import
# Scenario-specific DBFs (in subfolders) are accessed directly during scenario import

def get_dbf_files(model_path)
  # Ensure we're working with the .IEDB folder
  iedb_path = model_path
  unless model_path.end_with?('.IEDB') || model_path.end_with?('.iedb')
    iedb_path = File.join(File.dirname(model_path), File.basename(model_path, '.*') + '.IEDB')
  end
  
  raise "Cannot find IEDB folder: #{iedb_path}" unless Dir.exist?(iedb_path)
  
  # Create a hash of DBF names (in lowercase with no extension) to their filepath
  # Only include root-level DBFs for BASE scenario import
  dbf = Hash.new
  unix_iedb_path = iedb_path.gsub('\\', '/')
  Dir.glob(unix_iedb_path + '/*.DBF').each do |file|
    name = File.basename(file, '.*').downcase
    dbf[name] = file
  end
  
  # Also check for lowercase .dbf extension
  Dir.glob(unix_iedb_path + '/*.dbf').each do |file|
    name = File.basename(file, '.*').downcase
    dbf[name] = file unless dbf.key?(name)  # Don't overwrite if uppercase version exists
  end
  
  return dbf
end

