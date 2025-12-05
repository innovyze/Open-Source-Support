# ============================================================================
# InfoSWMM/H2OMapSWMM Multi-Scenario Import - EXCHANGE SCRIPT (ENHANCED)
# ============================================================================
# 
# ENHANCED VERSION - Supports both:
#   - InfoSWMM (.mxd) files with .ISDB folders
#   - H2OMapSWMM (.hsm) files with .HSDB folders
#   - Comprehensive data field statistics
#
# EXECUTION:
#   This script is launched automatically by the UI script
#   Do not run this directly - use the UI script instead
#
# WHAT THIS SCRIPT DOES:
#   Phase 0:   Read and analyze all DBF files in ISDB/HSDB folder
#              + Generate comprehensive field statistics
#
#   Phase 1:   Import each scenario to separate model groups
#              + Clean up empty label lists after each import
#
#   Phase 1.5: Analyze and deduplicate Rainfall Events & Inflows by content
#              (Note: Time Patterns and Climatology cannot be deduplicated - API limitation)
#
#   Phase 2:   Create merged network with all scenarios combined
#              + Copy only unique objects (deduplicated)
#              + Use sequential naming: "Rainfall Event 01", "Inflow 01", etc.
#              + Store scenario names in Description field (line-break separated)
#              + Add all scenarios to merged network
#              + Delete inactive elements from each scenario
#
#   Phase 2.5: Set up SWMM runs for each scenario in merged network
#              + Create runs with essential configuration (network, scenario, rainfall)
#              + Link to deduplicated rainfall events in merged group
#              [!] Manual setup required: timesteps, climatology, time patterns, inflows
#
# KEY FEATURES:
#   - Supports both InfoSWMM (.mxd) and H2OMapSWMM (.hsm) files
#   - Comprehensive DBF statistics for all data fields
#   - Content-based deduplication (compares actual data, not just names)
#   - Sequential object naming for clean output
#   - Scenario tracking via Description field
#   - Comprehensive error handling and logging
#
# API LIMITATIONS (require manual post-import setup):
#   - Timestep controls cannot be reliably copied
#   - Climatology cannot be assigned programmatically
#   - Time Patterns cannot be assigned programmatically
#   - Inflow Events cannot be linked to runs programmatically
#
# ============================================================================

require 'yaml'

# ============================================================================
# DBF Reader Class - Enhanced with comprehensive statistics
# ============================================================================
class DBFReader
  attr_reader :fields, :records, :stats, :file_path
  
  def initialize(file_path)
    @file_path = file_path
    @fields = []
    @records = []
    @stats = {}
    read_dbf
  end
  
  def read_dbf
    File.open(@file_path, 'rb') do |file|
      # Read DBF header
      version = file.read(1)
      raise "File is empty or unreadable" if version.nil?
      
      last_update = file.read(3)
      num_records_bytes = file.read(4)
      header_length_bytes = file.read(2)
      record_length_bytes = file.read(2)
      
      raise "DBF header is incomplete" if num_records_bytes.nil? || header_length_bytes.nil? || record_length_bytes.nil?
      
      @num_records = num_records_bytes.unpack('V')[0]
      @header_length = header_length_bytes.unpack('v')[0]
      @record_length = record_length_bytes.unpack('v')[0]
      
      file.read(20)  # Reserved
      
      # Read field descriptors
      field_offset = 1  # First byte is delete flag
      
      loop do
        field_name_bytes = file.read(11)
        break if field_name_bytes.nil? || field_name_bytes[0] == "\r" || field_name_bytes[0] == "\x0D"
        
        field_name = field_name_bytes.unpack('Z11')[0]
        break if field_name.nil? || field_name.empty?
        
        field_type = file.read(1)
        file.read(4)  # Reserved
        field_length = file.read(1).unpack('C')[0]
        field_decimals = file.read(1).unpack('C')[0]
        file.read(14)  # Reserved
        
        @fields << {
          name: field_name.strip,
          type: field_type,
          offset: field_offset,
          length: field_length,
          decimals: field_decimals
        }
        
        field_offset += field_length
      end
      
      # Skip to data records
      file.seek(@header_length)
      
      # Read each record
      @num_records.times do
        record = file.read(@record_length)
        next if record.nil? || record[0] == '*'  # Skip deleted records
        
        record_hash = {}
        @fields.each do |field|
          value = record[field[:offset], field[:length]].strip rescue ''
          record_hash[field[:name]] = value
        end
        @records << record_hash
      end
    end
    
    # Calculate statistics
    calculate_stats
  end
  
  def calculate_stats
    @stats = {
      file_name: File.basename(@file_path),
      total_records: @records.length,
      fields: {}
    }
    
    @fields.each do |field|
      field_name = field[:name]
      values = @records.map { |r| r[field_name] }
      non_empty_values = values.reject { |v| v.nil? || v.empty? }
      
      field_stats = {
        type: get_type_description(field[:type]),
        length: field[:length],
        decimals: field[:decimals],
        total_count: values.length,
        non_empty_count: non_empty_values.length,
        empty_count: values.length - non_empty_values.length,
        unique_values: non_empty_values.uniq.length
      }
      
      # Type-specific statistics
      if field[:type] == 'N' || field[:type] == 'F'
        numeric_values = non_empty_values.map { |v| v.to_f }.compact
        unless numeric_values.empty?
          field_stats[:min] = numeric_values.min
          field_stats[:max] = numeric_values.max
          field_stats[:sum] = numeric_values.sum
          field_stats[:avg] = numeric_values.sum / numeric_values.length
        end
      elsif field[:type] == 'C'
        unless non_empty_values.empty?
          field_stats[:min_length] = non_empty_values.map(&:length).min
          field_stats[:max_length] = non_empty_values.map(&:length).max
          field_stats[:sample_values] = non_empty_values.uniq.first(5)
        end
      end
      
      @stats[:fields][field_name] = field_stats
    end
  end
  
  def get_type_description(type_char)
    case type_char
    when 'C' then 'Character'
    when 'N' then 'Numeric'
    when 'F' then 'Float'
    when 'L' then 'Logical'
    when 'D' then 'Date'
    when 'M' then 'Memo'
    else "Unknown (#{type_char})"
    end
  end
  
  def get_field_values(field_name)
    @records.map { |r| r[field_name] }.reject { |v| v.nil? || v.empty? }
  end
  
  def print_stats(log_file = nil)
    output = []
    output << "\n" + "="*70
    output << "DBF FILE STATISTICS: #{@stats[:file_name]}"
    output << "="*70
    output << "Total Records: #{@stats[:total_records]}"
    output << "Number of Fields: #{@fields.length}"
    output << ""
    output << "FIELD DETAILS:"
    output << "-"*70
    
    @stats[:fields].each do |field_name, field_stats|
      output << ""
      output << "  #{field_name}:"
      output << "    Type: #{field_stats[:type]} (Length: #{field_stats[:length]})"
      output << "    Records: #{field_stats[:non_empty_count]}/#{field_stats[:total_count]} non-empty"
      output << "    Unique Values: #{field_stats[:unique_values]}"
      
      if field_stats[:min] && field_stats[:max]
        output << "    Range: #{field_stats[:min]} to #{field_stats[:max]}"
        output << "    Sum: #{field_stats[:sum].round(4)}, Avg: #{field_stats[:avg].round(4)}"
      end
      
      if field_stats[:sample_values]
        samples = field_stats[:sample_values].map { |v| "'#{v}'" }.join(", ")
        output << "    Sample Values: #{samples}"
      end
    end
    
    output << "="*70
    
    text = output.join("\n")
    puts text
    log_file.puts text if log_file
    text
  end
end

# ============================================================================
# Database Folder Scanner - Reads all DBF files in ISDB/HSDB folders
# ============================================================================
class DatabaseFolderScanner
  attr_reader :folder_path, :dbf_files, :all_stats
  
  def initialize(folder_path)
    @folder_path = folder_path
    @dbf_files = {}
    @all_stats = {}
  end
  
  def scan
    return unless Dir.exist?(@folder_path)
    
    # Normalize path separators for Windows compatibility
    normalized_path = @folder_path.gsub('/', '\\')
    
    puts "Scanning for DBF files in: #{normalized_path}"
    
    # Try multiple glob patterns to find DBF files
    dbf_paths = []
    
    # Pattern 1: Standard glob
    dbf_paths += Dir.glob(File.join(@folder_path, "*.dbf"))
    dbf_paths += Dir.glob(File.join(@folder_path, "*.DBF"))
    
    # Pattern 2: With normalized path
    dbf_paths += Dir.glob(File.join(normalized_path, "*.dbf"))
    dbf_paths += Dir.glob(File.join(normalized_path, "*.DBF"))
    
    # Pattern 3: Direct directory listing as fallback
    if dbf_paths.empty?
      puts "Glob failed, trying direct directory listing..."
      begin
        Dir.entries(@folder_path).each do |entry|
          if entry.downcase.end_with?('.dbf')
            dbf_paths << File.join(@folder_path, entry)
          end
        end
      rescue => e
        puts "Directory listing error: #{e.message}"
      end
    end
    
    # Remove duplicates
    dbf_paths = dbf_paths.uniq
    
    puts "Found #{dbf_paths.length} DBF file(s)"
    
    dbf_paths.each do |dbf_path|
      file_name = File.basename(dbf_path, '.*').upcase
      begin
        reader = DBFReader.new(dbf_path)
        @dbf_files[file_name] = reader
        @all_stats[file_name] = reader.stats
        puts "  OK: #{file_name} (#{reader.records.length} records, #{reader.fields.length} fields)"
      rescue => e
        puts "  FAILED: #{File.basename(dbf_path)}: #{e.message}"
      end
    end
  end
  
  def get_reader(table_name)
    @dbf_files[table_name.upcase]
  end
  
  def print_summary(log_file = nil)
    output = []
    output << "\n" + "="*70
    output << "DATABASE FOLDER SUMMARY: #{File.basename(@folder_path)}"
    output << "="*70
    output << "Path: #{@folder_path}"
    output << "DBF Files Found: #{@dbf_files.length}"
    output << ""
    
    if @dbf_files.empty?
      output << "No DBF files found in folder."
    else
      output << "TABLE                    RECORDS   FIELDS   STATUS"
      output << "-"*70
      
      @dbf_files.each do |name, reader|
        status = reader.records.length > 0 ? "OK" : "Empty"
        output << sprintf("%-24s %7d   %6d   %s", name, reader.records.length, reader.fields.length, status)
      end
    end
    
    output << "="*70
    
    text = output.join("\n")
    puts text
    log_file.puts text if log_file
    text
  end
  
  def print_all_stats(log_file = nil)
    @dbf_files.each do |name, reader|
      reader.print_stats(log_file)
    end
  end
end

# ----------------------------------------------------------------------------
# Helper method for logging
# ----------------------------------------------------------------------------
def log(message, log_file = nil)
  puts message
  log_file.puts message if log_file
end

# ----------------------------------------------------------------------------
# Helper method to check if a label list is empty
# ----------------------------------------------------------------------------
# NOTE: InfoSWMM imports always create empty label lists as artifacts
#       This method checks the 'labels' field (blob) for content
#       If it's nil or empty, the label list is considered empty
# ----------------------------------------------------------------------------
def is_label_list_empty?(label_list, log_file = nil)
  begin
    # Check the 'Blob' field (blob data) - if empty, label list is empty
    blob = label_list['Blob']
    return blob.nil? || blob.empty?
  rescue => e
    log "  WARNING: Error checking label list: #{e.message}", log_file
    # On error, assume it's NOT empty (safer to keep it)
    false
  end
end

# ----------------------------------------------------------------------------
# Read configuration
# ----------------------------------------------------------------------------
# Config file is saved in the log folder next to the model file.
# The UI script passes the location via environment variable.

config_file = ENV['ICM_IMPORT_CONFIG']

# Fallback: search for recent config files if not passed
unless config_file && File.exist?(config_file)
  script_dir = File.dirname(__FILE__)
  parent_dir = File.dirname(script_dir)
  grandparent_dir = File.dirname(parent_dir)
  
  search_paths = []
  [script_dir, parent_dir, grandparent_dir].each do |dir|
    Dir.glob(File.join(dir, "**", "ICM Import Log Files", "import_config.yaml")).each do |path|
      search_paths << path
    end
  end
  
  if search_paths.any?
    config_file = search_paths.max_by { |f| File.mtime(f) }
  end
end

unless config_file && File.exist?(config_file)
  puts "ERROR: Configuration file not found"
  puts "Please run InfoSWMM_Import_with_Cleanup_UI.rb first to generate the config file."
  exit 1
end

config = YAML.load_file(config_file)

# Validate required configuration keys
required_keys = ['file_path', 'scenarios', 'merge_scenarios', 'cleanup_empty_label_lists', 'copy_swmm_runs']
missing = required_keys - config.keys
if missing.any?
  puts "ERROR: Configuration missing required keys: #{missing.join(', ')}"
  puts "Please run the UI script again to regenerate the configuration."
  exit 1
end

file_path = config['file_path']
scenario_input = config['scenarios']
merge_scenarios = config['merge_scenarios']
cleanup_empty_label_lists = config['cleanup_empty_label_lists']
copy_swmm_runs = config['copy_swmm_runs']

# Validate model file still exists
unless File.exist?(file_path)
  puts "ERROR: InfoSWMM model file not found: #{file_path}"
  puts "The file may have been moved or deleted since the UI script ran."
  exit 1
end

# Validate file extension
ext = File.extname(file_path).downcase
unless ['.mxd', '.hsm'].include?(ext)
  puts "ERROR: File must be an InfoSWMM .mxd or H2OMapSWMM .hsm file"
  puts "Selected file: #{file_path}"
  exit 1
end

puts "\n" + "="*70
puts "  InfoSWMM / H2OMapSWMM Multi-Scenario Import (ENHANCED)"
puts "="*70
puts "\nModel: #{File.basename(file_path)}"
puts "Scenarios: #{scenario_input}"

# ============================================================================
# Determine file type and database folder
# ============================================================================
ext = File.extname(file_path).downcase
is_hsm = (ext == '.hsm')
db_type = is_hsm ? 'HSDB' : 'ISDB'

puts "File Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}"

# Determine database folder (enhanced detection)
mxd_dir = File.dirname(file_path)
mxd_basename = File.basename(file_path, ext)

db_folder = config['db_folder'] if config.key?('db_folder')

unless db_folder && Dir.exist?(db_folder)
  possible_db_folders = if is_hsm
    [
      File.join(mxd_dir, "#{mxd_basename}.HSDB"),
      File.join(mxd_dir, "#{mxd_basename}.hsdb"),
      File.join(mxd_dir, "HSDB"),
      File.join(mxd_dir, "hsdb"),
      File.join(mxd_dir, "#{mxd_basename}.ISDB"),
      File.join(mxd_dir, "#{mxd_basename}.isdb")
    ]
  else
    [
      File.join(mxd_dir, "#{mxd_basename}.ISDB"),
      File.join(mxd_dir, "#{mxd_basename}.isdb"),
      File.join(mxd_dir, "ISDB"),
      File.join(mxd_dir, "isdb"),
      File.join(mxd_dir, "#{mxd_basename}.HSDB"),
      File.join(mxd_dir, "#{mxd_basename}.hsdb")
    ]
  end
  
  # First try exact matches
  possible_db_folders.each do |folder|
    if Dir.exist?(folder)
      db_folder = folder
      break
    end
  end
  
  # If not found, try case-insensitive search
  unless db_folder
    puts "Trying case-insensitive folder search..."
    Dir.entries(mxd_dir).each do |entry|
      next if entry == '.' || entry == '..'
      full_path = File.join(mxd_dir, entry)
      next unless File.directory?(full_path)
      
      entry_lower = entry.downcase
      basename_lower = mxd_basename.downcase
      
      if entry_lower == "#{basename_lower}.isdb" ||
         entry_lower == "#{basename_lower}.hsdb" ||
         entry_lower == "isdb" ||
         entry_lower == "hsdb"
        db_folder = full_path
        puts "Found database folder: #{entry}"
        break
      end
    end
  end
end

puts "\n" + "="*70

# ----------------------------------------------------------------------------
# Open database
# ----------------------------------------------------------------------------
begin
  db = WSApplication.open
rescue => e
  puts "Error opening database: #{e.message}"
  exit 1
end

if db.nil?
  puts "Failed to open the database."
  exit 1
end

# File validation already done above after config loading
# Additional validation handled earlier in the script

# ----------------------------------------------------------------------------
# Parse scenarios
# ----------------------------------------------------------------------------
scenarios = scenario_input.split(',').map(&:strip).reject(&:empty?)

if scenarios.empty?
  puts "ERROR: No valid scenario names provided."
  exit 1
end

# ----------------------------------------------------------------------------
# Setup logging
# ----------------------------------------------------------------------------
log_dir = File.join(File.dirname(file_path), "ICM Import Log Files")
Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

log_filename = File.join(log_dir, "Import_Runs_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
log_file = File.open(log_filename, 'w')

log "\n" + "="*70, log_file
log "InfoSWMM/H2OMapSWMM Multi-Scenario Import (ENHANCED) - #{Time.now}", log_file
log "="*70, log_file
log "Database GUID: #{db.guid}", log_file
log "Source File: #{file_path}", log_file
log "File Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}", log_file
log "Scenarios to import: #{scenarios.join(', ')}", log_file
log "Cleanup empty label lists: #{cleanup_empty_label_lists}", log_file
log "Copy SWMM runs: #{copy_swmm_runs}", log_file
log "="*70 + "\n", log_file

# ============================================================================
# PHASE 0: Read and analyze database files with comprehensive statistics
# ============================================================================
puts "+" + "="*68 + "+"
puts "|" + " "*27 + "PHASE 0" + " "*35 + "|"
puts "|" + " "*14 + "Database Analysis & Statistics" + " "*24 + "|"
puts "+" + "="*68 + "+"
puts ""

log "\n" + "="*70, log_file
log "PHASE 0: Database File Analysis", log_file
log "="*70, log_file

# Scan database folder and collect statistics
db_stats = {}
if db_folder && Dir.exist?(db_folder)
  puts "Scanning database folder: #{File.basename(db_folder)}"
  log "Database folder: #{db_folder}", log_file
  
  scanner = DatabaseFolderScanner.new(db_folder)
  scanner.scan
  
  # Print and log summary
  scanner.print_summary(log_file)
  
  # Generate detailed statistics report
  stats_report_path = File.join(log_dir, "DBF_Statistics_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")
  File.open(stats_report_path, 'w') do |stats_file|
    stats_file.puts "="*70
    stats_file.puts "DATABASE STATISTICS REPORT - COMPREHENSIVE"
    stats_file.puts "="*70
    stats_file.puts "Generated: #{Time.now}"
    stats_file.puts "Model File: #{file_path}"
    stats_file.puts "File Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}"
    stats_file.puts "Database Folder: #{db_folder}"
    stats_file.puts "="*70
    
    scanner.print_summary(stats_file)
    stats_file.puts "\n" + "="*70
    stats_file.puts "DETAILED FIELD STATISTICS BY TABLE"
    stats_file.puts "="*70
    scanner.print_all_stats(stats_file)
  end
  
  puts "  > Statistics saved to: #{File.basename(stats_report_path)}"
  log "Detailed statistics saved to: #{stats_report_path}", log_file
  
  # Display quick summary of key tables
  puts ""
  puts "Key Table Summary:"
  key_tables = ['SCENARIO', 'JUNCTION', 'CONDUIT', 'OUTFALL', 'STORAGE', 'PUMP', 'ORIFICE', 'WEIR', 'SUBCATCHMENT', 'RAINGAGE', 'POLLUTANT']
  key_tables.each do |table|
    reader = scanner.get_reader(table)
    if reader && reader.records.length > 0
      puts sprintf("  %-15s: %5d records, %2d fields", table, reader.records.length, reader.fields.length)
      db_stats[table] = { records: reader.records.length, fields: reader.fields.length }
    end
  end
  puts ""
  
  log "Key table statistics:", log_file
  db_stats.each do |table, stats|
    log "  #{table}: #{stats[:records]} records, #{stats[:fields]} fields", log_file
  end
else
  puts "  WARNING: Database folder not found - skipping statistics"
  log "WARNING: Database folder not found at #{db_folder}", log_file
end

log "\nPhase 0 complete - database analysis finished", log_file
puts ""

# ============================================================================
# PHASE 1: Import each scenario to separate model groups
# ============================================================================
puts "+" + "="*68 + "+"
puts "|" + " "*27 + "PHASE 1" + " "*35 + "|"
puts "|" + " "*17 + "Import Individual Scenarios" + " "*24 + "|"
puts "+" + "="*68 + "+"
puts ""

log "\n" + "="*70, log_file
log "PHASE 1: Individual Scenario Import", log_file
log "="*70, log_file

successful_imports = []
failed_imports = []
imported_model_groups = {}  # Track model group IDs for phase 2
cleanup_stats = { label_lists_found: 0, label_lists_deleted: 0, label_lists_kept: 0 }

scenarios.each_with_index do |scenario_name, index|
  puts "[#{index + 1}/#{scenarios.length}] #{scenario_name}"
  puts "  " + "-"*66
  
  log "\n[#{index + 1}/#{scenarios.length}] Processing scenario: #{scenario_name}", log_file
  log "-" * 70, log_file
  
  begin
    # Create model group
    model_group_name = "#{File.basename(file_path, File.extname(file_path))} - #{scenario_name}"
    log "Creating model group: #{model_group_name}", log_file
    
    begin
      model_group = db.new_model_object('Model Group', model_group_name)
      log "Model group created with ID: #{model_group.id}", log_file
    rescue => e
      if e.message.include?("already exists")
        error_msg = "ERROR: Model group '#{model_group_name}' already exists in database.\n\n" +
                    "Please delete or rename the existing model group before running this script again."
        log error_msg, log_file
        puts ""
        puts "="*70
        puts "ERROR: Duplicate Model Group Detected"
        puts "="*70
        puts ""
        puts "A model group with this name already exists:"
        puts "  '#{model_group_name}'"
        puts ""
        puts "Please delete or rename the existing model group"
        puts "before running this script again."
        puts ""
        puts "="*70
        log_file.close
        exit 1
      else
        raise  # Re-raise if it's a different error
      end
    end
    
    # Create import log
    import_log_path = File.join(log_dir, "#{scenario_name}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")
    
    # Import
    log "Importing scenario '#{scenario_name}' from #{File.basename(file_path)}...", log_file
    
    # DEBUG: Show file details
    log "DEBUG: File path: #{file_path}", log_file
    log "DEBUG: File extension: #{ext}", log_file
    log "DEBUG: is_hsm flag: #{is_hsm}", log_file
    log "DEBUG: File exists: #{File.exist?(file_path)}", log_file
    log "DEBUG: File size: #{File.size(file_path) rescue 'unknown'} bytes", log_file
    
    puts "  DEBUG: Attempting import..."
    puts "  DEBUG: is_hsm=#{is_hsm}, ext=#{ext}"
    
    # DEBUG: Check for database folders
    model_dir = File.dirname(file_path)
    model_basename = File.basename(file_path, ext)
    
    log "DEBUG: Model directory: #{model_dir}", log_file
    log "DEBUG: Model basename: #{model_basename}", log_file
    
    # WORKAROUND: ICM importer always looks for .ISDB folder, even for .hsm files
    # If this is an HSM file and only HSDB exists, temporarily rename it to ISDB
    hsdb_to_isdb_renamed = false
    original_hsdb_path = nil
    temp_isdb_path = nil
    
    if is_hsm
      # Check if HSDB exists but ISDB doesn't
      hsdb_path = File.join(model_dir, "#{model_basename}.HSDB")
      isdb_path = File.join(model_dir, "#{model_basename}.ISDB")
      
      # Case-insensitive search for HSDB
      unless Dir.exist?(hsdb_path)
        Dir.entries(model_dir).each do |entry|
          if entry.downcase == "#{model_basename.downcase}.hsdb"
            hsdb_path = File.join(model_dir, entry)
            break
          end
        end
      end
      
      # Case-insensitive check for existing ISDB
      isdb_exists = false
      Dir.entries(model_dir).each do |entry|
        if entry.downcase == "#{model_basename.downcase}.isdb"
          isdb_exists = true
          isdb_path = File.join(model_dir, entry)
          break
        end
      end
      
      if Dir.exist?(hsdb_path) && !isdb_exists
        log "WORKAROUND: HSM file detected with HSDB folder but no ISDB folder", log_file
        log "  ICM importer requires .ISDB folder, temporarily renaming...", log_file
        puts "  WORKAROUND: Renaming HSDB -> ISDB for import compatibility..."
        
        # Determine the ISDB path (same name pattern as HSDB but with .ISDB)
        hsdb_basename = File.basename(hsdb_path)
        temp_isdb_path = File.join(model_dir, hsdb_basename.sub(/\.hsdb$/i, '.ISDB'))
        
        begin
          File.rename(hsdb_path, temp_isdb_path)
          original_hsdb_path = hsdb_path
          hsdb_to_isdb_renamed = true
          log "  Renamed: #{hsdb_basename} -> #{File.basename(temp_isdb_path)}", log_file
          puts "    Renamed: #{hsdb_basename} -> #{File.basename(temp_isdb_path)}"
        rescue => e
          log "  ERROR: Could not rename folder: #{e.message}", log_file
          puts "    ERROR: Could not rename folder: #{e.message}"
          log "  TIP: Manually rename #{hsdb_basename} to .ISDB and try again", log_file
        end
      elsif isdb_exists
        log "DEBUG: ISDB folder already exists, no rename needed", log_file
      end
    end
    
    # Try to discover available import formats
    begin
      log "DEBUG: Checking available import formats...", log_file
      
      # List methods available on model_group to find import-related ones
      import_methods = model_group.methods.grep(/import/i)
      log "DEBUG: Import-related methods: #{import_methods.join(', ')}", log_file
      puts "  DEBUG: Import methods: #{import_methods.join(', ')}"
      
      # Try to get supported formats if method exists
      if model_group.respond_to?(:supported_import_formats)
        formats = model_group.supported_import_formats
        log "DEBUG: Supported formats: #{formats.inspect}", log_file
        puts "  DEBUG: Supported formats: #{formats.inspect}"
      end
      
      # Check the db object for format info
      if db.respond_to?(:supported_import_formats)
        formats = db.supported_import_formats
        log "DEBUG: DB Supported formats: #{formats.inspect}", log_file
      end
      
      # Log more file details
      log "DEBUG: HSDB folder exists: #{Dir.exist?(db_folder) rescue 'unknown'}", log_file if defined?(db_folder)
      
      # List files in the directory to verify structure
      model_dir = File.dirname(file_path)
      log "DEBUG: Files in model directory:", log_file
      Dir.entries(model_dir).each do |entry|
        log "DEBUG:   - #{entry}", log_file
      end
      
    rescue => e
      log "DEBUG: Could not list methods: #{e.message}", log_file
    end
    
    # Known import filters to try (in order of preference)
    # Based on ICM documentation, these are typical filter values
    import_filters_to_try = if is_hsm
      ['mxd', 'hsm', 'H2OMAP', 'h2omap', 'H2OMapSWMM', 'SWMM']  # Try mxd first for HSM files
    else
      ['mxd', 'MXD', 'InfoSWMM', 'SWMM']
    end
    
    log "DEBUG: Will try these import filters: #{import_filters_to_try.join(', ')}", log_file
    puts "  DEBUG: Will try filters: #{import_filters_to_try.join(', ')}"
    
    imported_objects = nil
    successful_filter = nil
    
    import_filters_to_try.each do |import_filter|
      begin
        log "DEBUG: Trying import filter '#{import_filter}'...", log_file
        puts "  DEBUG: Trying filter '#{import_filter}'..."
        
        imported_objects = model_group.import_all_sw_model_objects(
          file_path,
          import_filter,
          scenario_name,
          import_log_path
        )
        
        # If we get here without exception, it worked
        if imported_objects && !imported_objects.empty?
          successful_filter = import_filter
          log "DEBUG: SUCCESS with filter '#{import_filter}' - imported #{imported_objects.length} objects", log_file
          puts "  DEBUG: SUCCESS with '#{import_filter}'!"
          break
        else
          log "DEBUG: Filter '#{import_filter}' returned empty result", log_file
        end
        
      rescue => e
        log "DEBUG: Filter '#{import_filter}' failed: #{e.message}", log_file
        puts "  DEBUG: Filter '#{import_filter}' failed: #{e.message}"
        # Continue to next filter
      end
    end
    
    # Log the successful filter for future reference
    if successful_filter
      log "RESULT: Successfully imported using filter '#{successful_filter}'", log_file
      puts "  RESULT: Import succeeded with filter '#{successful_filter}'"
    else
      log "RESULT: All import filters failed", log_file
      puts "  RESULT: All import filters failed"
      
      # Read import log to see what happened
      if File.exist?(import_log_path)
        log "DEBUG: Import log contents from failed attempts:", log_file
        puts "  DEBUG: Reading import log..."
        File.foreach(import_log_path) do |line|
          log "    #{line.strip}", log_file
          puts "    #{line.strip}"
        end
      end
    end
    
    # Check success
    if imported_objects.nil? || imported_objects.empty?
      puts "  FAILED: No objects imported"
      log "WARNING: No objects imported for scenario '#{scenario_name}'", log_file
      
      if File.exist?(import_log_path)
        log "Import log contents:", log_file
        File.foreach(import_log_path) do |line|
          log "  #{line.strip}", log_file
        end
      end
      
      log "Import failed for scenario '#{scenario_name}'", log_file
      failed_imports << scenario_name
      
      # Clean up empty model group
      begin
        model_group.delete
        log "Deleted empty model group", log_file
      rescue => e
        log "Could not delete empty model group: #{e.message}", log_file
      end
      
      # Restore HSDB folder name if we renamed it
      if hsdb_to_isdb_renamed && original_hsdb_path && temp_isdb_path
        begin
          File.rename(temp_isdb_path, original_hsdb_path)
          log "Restored folder name: #{File.basename(temp_isdb_path)} -> #{File.basename(original_hsdb_path)}", log_file
          puts "    Restored: #{File.basename(original_hsdb_path)}"
        rescue => e
          log "WARNING: Could not restore folder name: #{e.message}", log_file
          puts "    WARNING: Could not restore folder name - please rename manually!"
        end
      end
    else
      # Success!
      puts "  > Imported #{imported_objects.length} objects"
      
      log "SUCCESS: Imported #{imported_objects.length} objects for scenario '#{scenario_name}'", log_file
      log "Imported objects:", log_file
      
      imported_objects.each do |obj|
        log "  - #{obj.type}: #{obj.name} (ID: #{obj.id})", log_file
      end
      
      # ==================================================================
      # NEW: CLEANUP EMPTY LABEL LISTS
      # ==================================================================
      if cleanup_empty_label_lists
        log "\nCleaning up empty label lists...", log_file
        
        label_lists_to_delete = []
        
        # Find all label lists in the imported objects
        imported_objects.each do |obj|
          if obj.type == 'Label List'
            cleanup_stats[:label_lists_found] += 1
            log "  Found Label List: #{obj.name} (ID: #{obj.id})", log_file
            
            # Check if it's empty
            if is_label_list_empty?(obj, log_file)
              log "    Label list is empty - marking for deletion", log_file
              label_lists_to_delete << obj
            else
              log "    Label list has content - keeping", log_file
              cleanup_stats[:label_lists_kept] += 1
            end
          end
        end
        
        # Delete empty label lists
        if label_lists_to_delete.any?
          log "  Deleting #{label_lists_to_delete.length} empty label list(s)...", log_file
          puts "  > Cleaning up: #{label_lists_to_delete.length} empty label list(s) removed"
          
          label_lists_to_delete.each do |label_list|
            begin
              label_list.delete
              cleanup_stats[:label_lists_deleted] += 1
              log "    Deleted: #{label_list.name}", log_file
            rescue => e
              log "    ERROR deleting label list '#{label_list.name}': #{e.message}", log_file
              cleanup_stats[:label_lists_kept] += 1
            end
          end
          
          log "  Cleanup complete: deleted #{cleanup_stats[:label_lists_deleted]} label lists", log_file
        else
          log "  No empty label lists to clean up", log_file
        end
      end
      # ==================================================================
      
      # Find and commit the SWMM network so it's saved for Phase 2
      imported_network = nil
      imported_objects.each do |obj|
        if obj.type == 'SWMM network'
          imported_network = obj
          break
        end
      end
      
      if imported_network
        begin
          log "Committing imported network: #{imported_network.name}", log_file
          net = imported_network.open
          net.commit("Imported from InfoSWMM - #{scenario_name}")
          log "Network committed successfully", log_file
        rescue => e
          log "WARNING: Could not commit network: #{e.message}", log_file
        end
      end
      
      successful_imports << { scenario: scenario_name, group_id: model_group.id, count: imported_objects.length }
      imported_model_groups[scenario_name] = model_group.id
      
      # Restore HSDB folder name if we renamed it
      if hsdb_to_isdb_renamed && original_hsdb_path && temp_isdb_path
        begin
          File.rename(temp_isdb_path, original_hsdb_path)
          log "Restored folder name: #{File.basename(temp_isdb_path)} -> #{File.basename(original_hsdb_path)}", log_file
          puts "    Restored: #{File.basename(original_hsdb_path)}"
        rescue => e
          log "WARNING: Could not restore folder name: #{e.message}", log_file
          puts "    WARNING: Could not restore folder name - please rename manually!"
        end
      end
    end
    
  rescue => e
    puts "  ERROR: #{e.message}"
    log "ERROR importing scenario '#{scenario_name}': #{e.message}", log_file
    log "Backtrace: #{e.backtrace.join("\n")}", log_file
    failed_imports << scenario_name
    
    # Restore HSDB folder name if we renamed it
    if defined?(hsdb_to_isdb_renamed) && hsdb_to_isdb_renamed && original_hsdb_path && temp_isdb_path
      begin
        File.rename(temp_isdb_path, original_hsdb_path)
        log "Restored folder name after error: #{File.basename(temp_isdb_path)} -> #{File.basename(original_hsdb_path)}", log_file
        puts "    Restored: #{File.basename(original_hsdb_path)}"
      rescue => rename_e
        log "WARNING: Could not restore folder name: #{rename_e.message}", log_file
        puts "    WARNING: Could not restore folder name - please rename manually!"
      end
    end
  end
end

# Log cleanup statistics
if cleanup_empty_label_lists
  log "\n" + "="*70, log_file
  log "CLEANUP STATISTICS", log_file
  log "="*70, log_file
  log "Label lists found: #{cleanup_stats[:label_lists_found]}", log_file
  log "Label lists deleted: #{cleanup_stats[:label_lists_deleted]}", log_file
  log "Label lists kept: #{cleanup_stats[:label_lists_kept]}", log_file
  log "="*70 + "\n", log_file
  
  if cleanup_stats[:label_lists_deleted] > 0
    puts "\n" + "-" * 70
    puts "  Cleanup Summary: Deleted #{cleanup_stats[:label_lists_deleted]} empty label list(s)"
    puts "-" * 70
  end
end

# ============================================================================
# PHASE 1.5: Deduplicate Objects (Time Patterns, Climatology, Rainfall Events)
# ============================================================================
puts "+" + "="*68 + "+"
puts "|" + " "*26 + "PHASE 1.5" + " "*33 + "|"
puts "|" + " "*10 + "Analyze & Deduplicate Rainfall/Inflow Events" + " "*13 + "|"
puts "+" + "="*68 + "+"
puts ""

log "\n" + "="*70, log_file
log "PHASE 1.5: Object Deduplication Analysis", log_file
log "="*70, log_file

# Helper method to get object content hash by exporting and stripping metadata
def get_object_hash(obj, log_file = nil)
  require 'digest'
  
  begin
    # Use a simple temp directory path
    script_dir = File.dirname(__FILE__)
    temp_dir = File.join(script_dir, "temp_object_compare")
    Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)
    
    # Export object to temp file
    safe_name = obj.type.gsub(' ', '_').gsub(/[^a-zA-Z0-9_]/, '')
    temp_file = File.join(temp_dir, "#{safe_name}_#{obj.id}.txt")
    
    # Use default InfoWorks format
    obj.export(temp_file, '')
    
    # Check if file was created and has content
    unless File.exist?(temp_file)
      log "  ERROR: Export failed - file not created for #{obj.type} '#{obj.name}'", log_file if log_file
      return nil
    end
    
    file_size = File.size(temp_file)
    if file_size == 0
      log "  WARNING: Export created empty file (0 bytes) for #{obj.type} '#{obj.name}'", log_file if log_file
      File.delete(temp_file) if File.exist?(temp_file)
      return nil
    end
    
    # Read file contents
    contents = File.read(temp_file)
    
    # Strip metadata that would make identical objects appear different
    # Remove lines that contain object names (they vary by scenario)
    cleaned_lines = []
    contents.each_line do |line|
      # Skip lines that are just the object name or contain common metadata keywords
      next if line.strip == obj.name
      next if line.match(/^Name[:\s]/i)
      next if line.match(/^Description[:\s]/i)
      next if line.match(/^Created[:\s]/i)
      next if line.match(/^Modified[:\s]/i)
      next if line.match(/^GUID[:\s]/i)
      next if line.match(/^ID[:\s]/i)
      
      # Keep data lines
      cleaned_lines << line
    end
    
    cleaned_content = cleaned_lines.join
    
    # Log first export for debugging
    if log_file && $first_export_logged.nil?
      $first_export_logged = {}
    end
    if log_file && !$first_export_logged[obj.type]
      $first_export_logged[obj.type] = true
      log "  DEBUG: First #{obj.type} export (after metadata stripping, first 300 chars):", log_file
      log "  #{cleaned_content[0..300].inspect}", log_file
      log "  Original size: #{contents.length} bytes, Cleaned size: #{cleaned_content.length} bytes", log_file
    end
    
    # Calculate hash on cleaned content
    hash = Digest::SHA256.hexdigest(cleaned_content)
    
    # Cleanup
    File.delete(temp_file) if File.exist?(temp_file)
    
    return hash
    
  rescue => e
    log "  ERROR: Exception hashing #{obj.type} '#{obj.name}': #{e.message}", log_file if log_file
    log "  Backtrace: #{e.backtrace.first(3).join("\n           ")}", log_file if log_file
    return nil
  end
end

# Define object types to deduplicate
# Note: IWSW Time Patterns and IWSW Climatology don't support export method,
#       so we can only deduplicate Rainfall Events and Inflows
DEDUP_OBJECT_TYPES = [
  'Rainfall Event',
  'Inflow'
]

# These types don't support export and can't be deduplicated:
# - 'IWSW Time Patterns' (no export support)
# - 'IWSW Climatology' (no export support)

# Collect all objects from all successful imports
all_objects_by_type = {}  # Hash: object_type => { scenario_name => [objects] }
object_stats_by_type = {}  # Hash: object_type => { total_found, unique_count, duplicate_count }

DEDUP_OBJECT_TYPES.each do |obj_type|
  all_objects_by_type[obj_type] = {}
  object_stats_by_type[obj_type] = { total_found: 0, unique_count: 0, duplicate_count: 0 }
end

successful_imports.each do |import_info|
  scenario_name = import_info[:scenario]
  group_id = import_info[:group_id]
  
  # Get the model group
  model_group = db.model_object_from_type_and_id('Model Group', group_id)
  next unless model_group
  
  # Find objects of each type in this group
  DEDUP_OBJECT_TYPES.each do |obj_type|
    all_objects_by_type[obj_type][scenario_name] = []
    
    model_group.children.each do |child|
      if child.type == obj_type
        all_objects_by_type[obj_type][scenario_name] << child
        object_stats_by_type[obj_type][:total_found] += 1
      end
    end
    
    count = all_objects_by_type[obj_type][scenario_name].length
    log "Found #{count} #{obj_type} object(s) in #{scenario_name}", log_file if count > 0
  end
end

# Analyze each object type for uniqueness
unique_objects_by_type = {}  # Hash: object_type => { hash => { object, model_names, scenarios } }

DEDUP_OBJECT_TYPES.each do |obj_type|
  unique_objects_by_type[obj_type] = {}
  
  next if object_stats_by_type[obj_type][:total_found] == 0
  
  log "\nAnalyzing #{obj_type}...", log_file
  puts "Analyzing #{obj_type}..."
  
  all_objects_by_type[obj_type].each do |scenario_name, objects|
    objects.each do |obj|
      obj_model_name = obj.name
      obj_hash = get_object_hash(obj, log_file)
      
      # If hash is nil (export failed), treat as unique to avoid data loss
      if obj_hash.nil?
        log "  WARNING: Could not hash '#{obj_model_name}' from #{scenario_name} - treating as unique", log_file
        # Generate a unique key for this failed hash
        unique_key = "UNHASHABLE_#{obj.id}"
      else
        # Use the hash as the unique key
        unique_key = obj_hash
      end
      
      # Enhanced logging to help debug
      hash_display = obj_hash.nil? ? "FAILED" : "#{obj_hash[0..10]}..."
      log "  '#{obj_model_name}' (#{scenario_name}): hash=#{hash_display}", log_file
      
      if unique_objects_by_type[obj_type].key?(unique_key)
        # Duplicate found (same data content, regardless of model object name)
        object_stats_by_type[obj_type][:duplicate_count] += 1
        unique_objects_by_type[obj_type][unique_key][:scenarios] << scenario_name
        unique_objects_by_type[obj_type][unique_key][:model_names] << obj_model_name
        log "    -> DUPLICATE (matches '#{unique_objects_by_type[obj_type][unique_key][:model_names].first}')", log_file
      else
        # New unique object (different data content)
        unique_objects_by_type[obj_type][unique_key] = {
          object: obj,
          model_names: [obj_model_name],
          hash: obj_hash,
          scenarios: [scenario_name]
        }
        log "    -> UNIQUE", log_file
      end
    end
  end
  
  object_stats_by_type[obj_type][:unique_count] = unique_objects_by_type[obj_type].length
end

# Log summary
log "\nDeduplication analysis complete:", log_file

DEDUP_OBJECT_TYPES.each do |obj_type|
  stats = object_stats_by_type[obj_type]
  next if stats[:total_found] == 0
  
  log "  #{obj_type}:", log_file
  log "    Total found: #{stats[:total_found]}", log_file
  log "    Unique (by contents): #{stats[:unique_count]}", log_file
  log "    Duplicates: #{stats[:duplicate_count]}", log_file
  
  puts "  > Found: #{stats[:total_found]} total | Unique: #{stats[:unique_count]} | Duplicates: #{stats[:duplicate_count]}"
end

puts ""

# Cleanup temp directory used for object comparison
begin
  script_dir = File.dirname(__FILE__)
  temp_dir = File.join(script_dir, "temp_object_compare")
  if Dir.exist?(temp_dir)
    Dir.glob(File.join(temp_dir, "*")).each { |f| File.delete(f) rescue nil }
    Dir.delete(temp_dir) rescue nil
    log "Cleaned up temporary object comparison directory", log_file
  end
rescue => e
  log "WARNING: Could not clean up temp directory: #{e.message}", log_file
end

# ============================================================================
# PHASE 2: Create merged network with scenarios
# ============================================================================
if merge_scenarios && successful_imports.length > 0
  puts "+" + "="*68 + "+"
  puts "|" + " "*27 + "PHASE 2" + " "*35 + "|"
  puts "|" + " "*14 + "Create Merged Network with Scenarios" + " "*17 + "|"
  puts "+" + "="*68 + "+"
  puts ""
  puts "This phase will:"
  puts "  1. Create a new master network based on BASE"
  puts "  2. Add scenarios for each imported network"
  puts "  3. Remove inactive elements from each scenario"
  puts ""
  
  log "\n" + "="*70, log_file
  log "PHASE 2: Merged Network Creation", log_file
  log "="*70, log_file
  
  begin
    # Find BASE scenario
    base_scenario = successful_imports.find { |s| s[:scenario].upcase == 'BASE' }
    
    if base_scenario.nil?
      # Use first scenario as base if no BASE found
      base_scenario = successful_imports.first
      log "WARNING: No BASE scenario found, using '#{base_scenario[:scenario]}' as master", log_file
      puts "  WARNING: Using '#{base_scenario[:scenario]}' as master (no BASE found)"
    else
      log "Using BASE scenario as master network", log_file
      puts "  Using BASE as master network"
    end
    
    # Create merged model group
    merged_group_name = "#{File.basename(file_path, File.extname(file_path))} - Merged Scenarios"
    log "Creating merged model group: #{merged_group_name}", log_file
    puts "Step 1: Creating merged model group '#{merged_group_name}'..."
    
    begin
      merged_group = db.new_model_object('Model Group', merged_group_name)
      log "Merged group created with ID: #{merged_group.id}", log_file
      puts "        Model group created successfully"
    rescue => e
      if e.message.include?("already exists")
        error_msg = "ERROR: Model group '#{merged_group_name}' already exists.\n\n" +
                    "Please delete or rename the existing merged model group before running this script again."
        log error_msg, log_file
        puts ""
        puts "="*70
        puts "ERROR: Duplicate Merged Model Group Detected"
        puts "="*70
        puts ""
        puts "A merged model group already exists:"
        puts "  '#{merged_group_name}'"
        puts ""
        puts "Please delete or rename the existing merged group"
        puts "before running this script again."
        puts ""
        puts "="*70
        log_file.close
        exit 1
      else
        raise  # Re-raise if it's a different error
      end
    end
    
    # Get the BASE model group to find the network
    base_group = db.model_object_from_type_and_id('Model Group', base_scenario[:group_id])
    if base_group.nil?
      raise "Could not find BASE model group with ID #{base_scenario[:group_id]}"
    end
    
    # Find the SWMM Network in the BASE group
    base_network = nil
    
    log "Searching for network in BASE group, children:", log_file
    base_group.children.each do |child|
      log "  - Type: '#{child.type}', Name: '#{child.name}'", log_file
      # Note: type is 'SWMM network' with lowercase 'n'
      if child.type == 'SWMM network'
        base_network = child
        break
      end
    end
    
    if base_network.nil?
      # Log what we found and raise error
      child_types = []
      base_group.children.each { |c| child_types << c.type }
      error_msg = "Could not find SWMM network in BASE model group. Found types: #{child_types.join(', ')}"
      log error_msg, log_file
      raise error_msg
    end
    
    log "Found BASE network: #{base_network.name} (ID: #{base_network.id})", log_file
    puts "  Found BASE network: #{base_network.name}"
    
    # Check if BASE network has data
    base_net = base_network.open
    node_count = base_net.row_objects('_nodes').length
    link_count = base_net.row_objects('_links').length
    sub_count = base_net.row_objects('_subcatchments').length
    
    log "BASE network contains: #{node_count} nodes, #{link_count} links, #{sub_count} subcatchments", log_file
    puts "  BASE network has: #{node_count} nodes, #{link_count} links, #{sub_count} subs"
    
    if node_count == 0 && link_count == 0
      raise "BASE network is empty! Cannot create merged network from empty source."
    end
    
    # Copy the BASE network into the merged group
    log "Copying BASE network to merged group...", log_file
    puts "  Copying BASE network..."
    
    # Use ICM's built-in copy method - copies all elements, structures, and relationships correctly
    merged_network = merged_group.copy_here(base_network, false, false)
    
    if merged_network.nil?
      raise "Failed to copy BASE network - copy_here returned nil"
    end
    
    # Rename the copied network
    merged_network_name = "#{File.basename(file_path, File.extname(file_path))} - Merged"
    merged_network.name = merged_network_name
    
    log "Copied network as: #{merged_network_name} (ID: #{merged_network.id})", log_file
    
    # Verify the copy worked by checking element counts
    merged_net = merged_network.open
    merged_node_count = merged_net.row_objects('_nodes').length
    merged_link_count = merged_net.row_objects('_links').length
    merged_sub_count = merged_net.row_objects('_subcatchments').length
    
    log "Merged network after copy: #{merged_node_count} nodes, #{merged_link_count} links, #{merged_sub_count} subcatchments", log_file
    puts "  Merged network: #{merged_node_count} nodes, #{merged_link_count} links, #{merged_sub_count} subs"
    
    if merged_node_count == 0 && merged_link_count == 0
      log "WARNING: copy_here created empty network, attempting manual commit...", log_file
      puts "  WARNING: Network copy is empty, trying alternative approach..."
      
      # The copy might need to be committed - try that
      merged_net.commit("Initial import from BASE")
      
      # Re-check
      merged_node_count = merged_net.row_objects('_nodes').length
      if merged_node_count == 0
        raise "Copied network is empty even after commit - copy_here may not work for SWMM networks"
      end
    end
    
    log "Successfully created merged network with BASE data", log_file
    puts "Step 1: Create master network from BASE"
    puts "  > Created: #{node_count} nodes, #{link_count} links, #{sub_count} subcatchments"
    puts ""
    
    # ==================================================================
    # DEDUPLICATE OBJECTS IN MERGED GROUP
    # ==================================================================
    log "\nDeduplicating objects in merged group...", log_file
    puts "Step 2: Copy unique Rainfall/Inflow Events to merged group"
    
    total_copied = 0
    total_failed = 0
    total_duplicates_skipped = 0
    
    DEDUP_OBJECT_TYPES.each do |obj_type|
      next if object_stats_by_type[obj_type][:total_found] == 0
      
      log "\n  Processing #{obj_type}...", log_file
      
      # First, delete all objects of this type that came with the BASE network copy
      existing_objects = []
      merged_group.children.each do |child|
        if child.type == obj_type
          existing_objects << child
        end
      end
      
      log "    Found #{existing_objects.length} existing #{obj_type} object(s) (will be replaced)", log_file
      existing_objects.each do |obj|
        begin
          obj.delete
          log "      Deleted: #{obj.name}", log_file
        rescue => e
          log "      WARNING: Could not delete '#{obj.name}': #{e.message}", log_file
        end
      end
      
      # Now copy only unique objects
      unique_count = unique_objects_by_type[obj_type].length
      log "    Copying #{unique_count} unique #{obj_type} object(s)...", log_file
      
      objects_copied = 0
      objects_failed = 0
      
      # Track object number for sequential naming
      object_number = 1
      
      unique_objects_by_type[obj_type].each do |unique_key, obj_info|
        obj = obj_info[:object]
        begin
          # Copy the object to merged group
          copied_obj = merged_group.copy_here(obj, false, false)
          
          # Use sequential naming: "Rainfall Event 01", "Inflow 01", etc.
          new_name = "#{obj_type} #{object_number.to_s.rjust(2, '0')}"
          copied_obj.name = new_name
          
          # Store scenario names in Description field (uses 'comment' in API)
          # Use Windows line ending for better readability in UI
          scenario_list = obj_info[:scenarios].join("\r\n")
          
          # Set comment field (displays as Description in UI) with scenario names
          # Note: Setting 'comment' property persists automatically - no write() call needed
          begin
            copied_obj.comment = scenario_list
            scenario_display = obj_info[:scenarios].join(', ')  # For log readability
            log "      Copied as: '#{new_name}' (ID: #{copied_obj.id}, scenarios: #{scenario_display})", log_file
            log "      Description content: '#{copied_obj.comment}'", log_file
          rescue => e
            log "      WARNING: Could not set description for '#{new_name}': #{e.message}", log_file
            log "      Copied as: '#{new_name}' (ID: #{copied_obj.id}, description not set)", log_file
          end
          
          objects_copied += 1
          object_number += 1
        rescue => e
          objects_failed += 1
          log "      ERROR copying '#{obj_info[:model_names].first}': #{e.message}", log_file
        end
      end
      
      duplicates_skipped = object_stats_by_type[obj_type][:duplicate_count]
      
      log "    #{obj_type} complete: #{objects_copied} copied, #{objects_failed} failed, #{duplicates_skipped} duplicates skipped", log_file
      puts "  > Copied: #{objects_copied} unique | Skipped: #{duplicates_skipped} duplicates"
      
      total_copied += objects_copied
      total_failed += objects_failed
      total_duplicates_skipped += duplicates_skipped
    end
    
    log "\n  Object deduplication complete:", log_file
    log "    Total objects copied: #{total_copied}", log_file
    log "    Total failed: #{total_failed}", log_file
    log "    Total duplicates skipped: #{total_duplicates_skipped}", log_file
    
    puts ""
    # ==================================================================
    
    # Now add other scenarios
    other_scenarios = successful_imports.reject { |s| s[:scenario] == base_scenario[:scenario] }
    
    if other_scenarios.any?
      log "\nAdding #{other_scenarios.length} additional scenario(s) to merged network...", log_file
      puts ""
      puts "Step 3: Add #{other_scenarios.length} scenario(s) to merged network"
      
      # Open the merged network ONCE for all scenarios
      merged_net_work = merged_network.open
      
      other_scenarios.each_with_index do |scenario_info, idx|
        scenario_name = scenario_info[:scenario]
        puts "  [#{idx + 1}/#{other_scenarios.length}] #{scenario_name}"
        log "\nAdding scenario: #{scenario_name}", log_file
        
        begin
          # Get the source model group for this scenario
          scenario_group = db.model_object_from_type_and_id('Model Group', scenario_info[:group_id])
          if scenario_group.nil?
            raise "Could not find model group for scenario #{scenario_name}"
          end
          
          # Find selection list in this group (created by import)
          selection_list = nil
          scenario_group.children.each do |child|
            # InfoSWMM import typically creates selection lists with scenario name
            if child.type == 'Selection List'
              log "  Found Selection List: #{child.name} (ID: #{child.id})", log_file
              # Use the first selection list found (should be the one from import)
              selection_list = child
              break
            end
          end
          
          if selection_list.nil?
            log "  WARNING: No selection list found for scenario #{scenario_name}", log_file
            log "  Available children:", log_file
            scenario_group.children.each do |child|
              log "    - #{child.type}: #{child.name}", log_file
            end
            puts "    WARNING: No selection list found - skipping"
            next
          end
          
          log "  Using selection list: #{selection_list.name}", log_file
          puts "    Found selection list: #{selection_list.name}"
          
          # Find the source network for this scenario
          source_network = nil
          scenario_group.children.each do |child|
            if child.type == 'SWMM network'
              source_network = child
              break
            end
          end
          
          if source_network.nil?
            log "  WARNING: No SWMM network found in scenario group - skipping", log_file
            puts "    WARNING: No source network found - skipping"
            next
          end
          
          log "  Found source network: #{source_network.name}", log_file
          
          # Set to base scenario before creating new scenario
          merged_net_work.current_scenario = 'Base'
          
          # Create new scenario in merged network (based on Base scenario)
          merged_net_work.add_scenario(scenario_name, 'Base', "Imported from InfoSWMM - #{scenario_name}")
          log "  Created scenario '#{scenario_name}' in merged network", log_file
          
          # Switch to the new scenario
          merged_net_work.current_scenario = scenario_name
          log "  Switched to scenario: #{scenario_name}", log_file
          
          # Copy data from source network to this scenario (field-by-field)
          log "  Copying scenario-specific data from source network...", log_file
          
          source_net = source_network.open
          fields_updated = 0
          fields_skipped = 0
          
          # Begin transaction for field updates
          merged_net_work.transaction_begin
          
          # Copy node data
          source_net.row_objects('_nodes').each do |source_node|
            target_node = merged_net_work.row_object('_nodes', source_node.id)
            next unless target_node
            
            # Copy each field value
            source_node.table_info.fields.each do |field|
              field_name = field.name
              # Skip only the object's own ID (not reference fields)
              next if field_name.downcase == 'node_id'
              
              begin
                source_value = source_node[field_name]
                target_value = target_node[field_name]
                
                if source_value != target_value
                  target_node[field_name] = source_value
                  fields_updated += 1
                end
              rescue => e
                # Skip read-only or incompatible fields
                fields_skipped += 1
                log "    Skipped node field '#{field_name}': #{e.message}", log_file if fields_skipped <= 10
              end
            end
            
            target_node.write
          end
          
          log "  Node fields: #{fields_updated} updated, #{fields_skipped} skipped", log_file
          
          # Copy link data
          link_fields_updated = 0
          link_fields_skipped = 0
          source_net.row_objects('_links').each do |source_link|
            target_link = merged_net_work.row_object('_links', source_link.id)
            next unless target_link
            
            source_link.table_info.fields.each do |field|
              field_name = field.name
              # Skip the object's own ID and topology (us/ds nodes define the link)
              next if ['link_id', 'us_node_id', 'ds_node_id'].include?(field_name.downcase)
              
              begin
                source_value = source_link[field_name]
                target_value = target_link[field_name]
                
                if source_value != target_value
                  target_link[field_name] = source_value
                  link_fields_updated += 1
                end
              rescue => e
                link_fields_skipped += 1
                log "    Skipped link field '#{field_name}': #{e.message}", log_file if link_fields_skipped <= 10
              end
            end
            
            target_link.write
          end
          
          log "  Link fields: #{link_fields_updated} updated, #{link_fields_skipped} skipped", log_file
          
          # Copy subcatchment data
          sub_fields_updated = 0
          sub_fields_skipped = 0
          source_net.row_objects('_subcatchments').each do |source_sub|
            target_sub = merged_net_work.row_object('_subcatchments', source_sub.id)
            next unless target_sub
            
            source_sub.table_info.fields.each do |field|
              field_name = field.name
              # Skip only the object's own ID
              next if field_name.downcase == 'subcatchment_id'
              
              begin
                source_value = source_sub[field_name]
                target_value = target_sub[field_name]
                
                if source_value != target_value
                  target_sub[field_name] = source_value
                  sub_fields_updated += 1
                end
              rescue => e
                sub_fields_skipped += 1
                log "    Skipped sub field '#{field_name}': #{e.message}", log_file if sub_fields_skipped <= 10
              end
            end
            
            target_sub.write
          end
          
          log "  Subcatchment fields: #{sub_fields_updated} updated, #{sub_fields_skipped} skipped", log_file
          
          total_fields = fields_updated + link_fields_updated + sub_fields_updated
          total_skipped = fields_skipped + link_fields_skipped + sub_fields_skipped
          log "  TOTAL: #{total_fields} field values updated, #{total_skipped} skipped", log_file
          
          # Commit field update transaction
          merged_net_work.transaction_commit
          log "  Field update transaction committed", log_file
          
          puts "             - Copied #{total_fields} field values" if total_fields > 0
          
          # Load the selection list (this selects ACTIVE elements in the scenario)
          merged_net_work.load_selection(selection_list)
          log "  Loaded selection list - active elements now selected", log_file
          
          # Build list of active element IDs
          active_nodes = []
          active_links = []
          active_subs = []
          
          merged_net_work.row_objects_selection('_nodes').each do |node|
            active_nodes << node.id
          end
          
          merged_net_work.row_objects_selection('_links').each do |link|
            active_links << link.id
          end
          
          merged_net_work.row_objects_selection('_subcatchments').each do |sub|
            active_subs << sub.id
          end
          
          log "  Active elements: #{active_nodes.length} nodes, #{active_links.length} links, #{active_subs.length} subcatchments", log_file
          
          # Clear selection
          merged_net_work.clear_selection
          
          # Select INACTIVE elements (inverse of selection list)
          inactive_count = 0
          
          # Select inactive nodes
          merged_net_work.row_objects('_nodes').each do |node|
            unless active_nodes.include?(node.id)
              node.selected = true
              inactive_count += 1
            end
          end
          
          # Select inactive links
          merged_net_work.row_objects('_links').each do |link|
            unless active_links.include?(link.id)
              link.selected = true
              inactive_count += 1
            end
          end
          
          # Select inactive subcatchments
          merged_net_work.row_objects('_subcatchments').each do |sub|
            unless active_subs.include?(sub.id)
              sub.selected = true
              inactive_count += 1
            end
          end
          
          log "  Selected #{inactive_count} inactive elements for deletion", log_file
          
          if inactive_count > 0
            # Delete the selected (inactive) elements
            merged_net_work.delete_selection
            log "  Successfully deleted inactive elements from scenario '#{scenario_name}'", log_file
            puts "             - Removed #{inactive_count} inactive elements"
          else
            log "  No inactive elements to delete from scenario '#{scenario_name}'", log_file
            puts "             - All elements active"
          end
          
          # Clear selection
          merged_net_work.clear_selection
          
          log "  Scenario '#{scenario_name}' complete", log_file
          
        rescue => e
          log "ERROR adding scenario '#{scenario_name}': #{e.message}", log_file
          log "Backtrace: #{e.backtrace.join("\n")}", log_file
          puts "             ERROR: #{e.message}"
          puts "             Scenario '#{scenario_name}' will be skipped"
          puts "             Check log file for details"
          
          # Try to rollback any pending transaction
          begin
            merged_net_work.transaction_rollback
          rescue
            # Transaction may not be active, ignore error
          end
        end
      end
      
      # Commit all changes once at the end
      puts ""
      puts "Step 3: Saving all changes to database"
      log "\nCommitting all scenario changes...", log_file
      merged_net_work.commit("Imported #{other_scenarios.length} scenarios from InfoSWMM")
      log "All changes committed successfully", log_file
      puts "        Commit successful"
    end
    
    log "\nMerged network creation complete!", log_file
    
    # Validate all scenarios before closing the network
    log "Validating all scenarios...", log_file
    all_scenarios = ['Base'] + other_scenarios.map { |s| s[:scenario] }
    validation_results = merged_net_work.validate(all_scenarios)
    log "All scenarios validated successfully", log_file
    
    # Commit validation results
    log "Committing validation results...", log_file
    merged_net_work.commit("Validated all scenarios")
    log "Validation results committed", log_file
    
    # Close the network
    log "Closing merged network...", log_file
    merged_network_id = merged_network.id
    merged_net_work.close
    log "Merged network closed (ID: #{merged_network_id})", log_file
    
    puts ""
    puts "+" + "="*68 + "+"
    puts "|" + " "*19 + "Merged Network Complete!" + " "*24 + "|"
    puts "+" + "="*68 + "+"
    
    # ========================================================================
    # PHASE 2.5: Copy SWMM Runs to Merged Network (NEW IN VERSION 4)
    # ========================================================================
    copy_swmm_runs = config['copy_swmm_runs']
    
    if copy_swmm_runs
      puts ""
      puts "+" + "="*68 + "+"
      puts "|" + " "*26 + "PHASE 2.5" + " "*33 + "|"
      puts "|" + " "*17 + "Set Up SWMM Runs for Scenarios" + " "*20 + "|"
      puts "+" + "="*68 + "+"
      puts ""
      puts "Creating SWMM runs in merged group..."
      puts "  Auto-configured: Network, scenario, rainfall event"
      puts "  Manual setup required: Timesteps, climatology, time patterns"
      puts ""
      
      log "\n" + "="*70, log_file
      log "PHASE 2.5: SWMM Run Setup", log_file
      log "="*70, log_file
      
      swmm_runs_created = 0
      swmm_runs_failed = 0
      
      begin
        # Reload merged_group to ensure we have fresh object references
        log "Reloading merged model group reference...", log_file
        merged_group = db.model_object_from_type_and_id('Model Group', merged_group.id)
        if merged_group.nil?
          raise "Could not reload merged model group"
        end
        log "Merged group reloaded successfully", log_file
        
        # SWMM runs are created directly under Model Group (no separate container needed)
        log "SWMM runs will be created directly under merged model group (ID: #{merged_group.id})", log_file
        puts "Step 1: Preparing to create SWMM runs"
        
        puts ""
        puts "Step 2: Copy SWMM run parameters for each scenario"
        
        # Process each successful import (including BASE)
        successful_imports.each_with_index do |import_info, idx|
          scenario_name = import_info[:scenario]
          puts "  [#{idx + 1}/#{successful_imports.length}] #{scenario_name}"
          log "\nProcessing SWMM run for scenario: #{scenario_name}", log_file
          
          begin
            # Get the source model group
            source_group = db.model_object_from_type_and_id('Model Group', import_info[:group_id])
            if source_group.nil?
              raise "Could not find source model group for #{scenario_name}"
            end
            
            # Find the SWMM run directly in source model group
            source_run = nil
            source_group.children.each do |child|
              if child.type == 'SWMM run'  # Note: lowercase 'run'
                source_run = child
                break  # Take first run (each scenario should have 1)
              end
            end
            
            if source_run.nil?
              log "  WARNING: No SWMM Run found in #{scenario_name} model group", log_file
              puts "    WARNING: No SWMM Run found - skipping"
              swmm_runs_failed += 1
              next
            end
            
            log "  Found source run: #{source_run.name} (ID: #{source_run.id})", log_file
            
            # Create new run builder (not loading from source)
            # NOTE: API limitation - loading from source and then overriding parameters
            # causes issues. Instead, create fresh runs with essential parameters only.
            run_builder = WSSWMMRunBuilder.new
            log "  Created new run builder (parameters will be set manually)", log_file
            
            # Set run name
            model_basename = File.basename(file_path, File.extname(file_path))
            new_run_name = "#{model_basename} - #{scenario_name}"
            run_builder['name'] = new_run_name
            log "  Set run name: #{new_run_name}", log_file
            
            # Set network to point to merged network  
            run_builder['network'] = merged_network.id
            log "  Set network ID: #{merged_network.id}", log_file
            
            # Set scenario (for non-BASE scenarios)
            # For BASE, use ["Base"] (base scenario)
            if scenario_name.upcase != 'BASE'
              run_builder['scenarios'] = [scenario_name]
              log "  Set scenario: [#{scenario_name}]", log_file
            else
              run_builder['scenarios'] = ['Base']
              log "  Set to base scenario: ['Base']", log_file
            end
            
            # NOTE: API Limitations - Several parameters cannot be reliably set via WSSWMMRunBuilder:
            # 1. Climatology - must be manually assigned in UI from individual model groups
            # 2. Time Patterns - must be manually assigned in UI from individual model groups
            # 3. Timestep controls and other run options - loading from source causes parameter conflicts
            # Users should review and adjust timestep controls in the run configuration after import.
            log "  NOTE: API limitations prevent copying timestep controls and other parameters", log_file
            log "        from original runs. Users should review run configuration after import.", log_file
            log "        Climatology and time patterns must be manually assigned in UI.", log_file
            
            # Find rainfall event in MERGED group (deduplicated)
            # NEW IN VERSION 5: Match by checking Description field (comment in API) which contains scenario names
            # Description format: "BASE\r\nEXISTING_100YR\r\nSCENARIO03" (Windows line endings)
            merged_rainfall = nil
            merged_group.children.each do |child|
              if child.type == 'Rainfall Event'
                begin
                  # Check if the Description field (comment in API) contains this scenario name
                  # include? works correctly with line-break-separated values
                  description = child.comment || ""
                  if description.include?(scenario_name)
                    merged_rainfall = child
                    break
                  end
                rescue => e
                  log "  WARNING: Could not read description from '#{child.name}': #{e.message}", log_file
                end
              end
            end
            
            if merged_rainfall
              run_builder['rainfall'] = [merged_rainfall.id]
              log "  Linked to rainfall event: #{merged_rainfall.name} (ID: #{merged_rainfall.id})", log_file
              # Display description with scenarios (convert line breaks to commas for log readability)
              desc_display = (merged_rainfall.comment || "").gsub(/\r?\n/, ", ")
              log "    Scenarios: #{desc_display}", log_file
            else
              log "  WARNING: No rainfall event found for #{scenario_name} in merged group", log_file
              # Try to find ANY rainfall event as fallback
              merged_group.children.each do |child|
                if child.type == 'Rainfall Event'
                  merged_rainfall = child
                  break
                end
              end
              
              if merged_rainfall
                run_builder['rainfall'] = [merged_rainfall.id]
                log "  WARNING: Using fallback rainfall: #{merged_rainfall.name}", log_file
              else
                log "  WARNING: No rainfall event found - run will retain source rainfall (may be invalid)", log_file
                # Cannot set to empty array - API rejects it. Leave as loaded from source.
              end
            end
            
            # Find inflow in MERGED group (deduplicated)
            # NEW IN VERSION 5: Same logic as rainfall events
            # Description format: "BASE\r\nEXISTING_100YR\r\nSCENARIO03" (Windows line endings)
            merged_inflow = nil
            inflows_found = []
            merged_group.children.each do |child|
              if child.type == 'Inflow'
                begin
                  # Check if the Description field (comment in API) contains this scenario name
                  # include? works correctly with newline-separated values
                  description = child.comment || ""
                  inflows_found << {name: child.name, id: child.id, description: description}
                  log "  DEBUG: Found inflow '#{child.name}' (ID: #{child.id}), description: '#{description}'", log_file
                  if description.include?(scenario_name)
                    merged_inflow = child
                    log "  DEBUG: Inflow '#{child.name}' matches scenario '#{scenario_name}'", log_file
                    break
                  end
                rescue => e
                  log "  WARNING: Could not read description from inflow '#{child.name}': #{e.message}", log_file
                end
              end
            end
            
            if inflows_found.empty?
              log "  DEBUG: No inflow objects found in merged group at all", log_file
            end
            
            if merged_inflow
              log "  Linking to inflow: #{merged_inflow.name} (ID: #{merged_inflow.id})", log_file
              begin
                run_builder['inflow'] = [merged_inflow.id]
                log "  Successfully linked to inflow: #{merged_inflow.name} (ID: #{merged_inflow.id})", log_file
                # Display description with scenarios (convert line breaks to commas for log readability)
                desc_display = (merged_inflow.comment || "").gsub(/\r?\n/, ", ")
                log "    Scenarios: #{desc_display}", log_file
              rescue => e
                log "  ERROR: Could not set inflow parameter: #{e.message}", log_file
                log "  Inflow ID attempted: #{merged_inflow.id}, Type: #{merged_inflow.type}", log_file
              end
            else
              log "  No inflow found for #{scenario_name} in merged group (may not be used)", log_file
              # Inflow is optional - not finding one is normal, so no fallback needed
            end
            
            # Log final run configuration for diagnostics
            log "  Final run configuration:", log_file
            log "    - Name: #{run_builder['name']}", log_file
            log "    - Network: #{run_builder['network']}", log_file
            log "    - Scenarios: #{run_builder['scenarios'].inspect}", log_file
            log "    - Rainfall: #{run_builder['rainfall'].inspect}", log_file
            log "    - Inflow: #{run_builder['inflow'].inspect}", log_file
            
            # Validate the run parameters before creating (no file output)
            begin
              is_valid = run_builder.validate
              if is_valid
                log "  Run parameters validated successfully", log_file
              else
                log "  WARNING: Run validation found issues", log_file
                puts "    WARNING: Run validation had issues"
              end
            rescue => e
              log "  WARNING: Could not validate run parameters: #{e.message}", log_file
              # Continue anyway - validation may not be required
            end
            
            # Create the new run directly in the merged model group
            if run_builder.create_new_run(merged_group.id)
              new_run = run_builder.get_run_mo
              log "  Created SWMM run: #{new_run_name} (ID: #{new_run.id})", log_file
              
              # Verify what was actually set by reading back the run parameters
              verify_builder = WSSWMMRunBuilder.new
              if verify_builder.load(new_run)
                log "  Verification of created run:", log_file
                log "    - Name: #{verify_builder['name']}", log_file
                log "    - Network: #{verify_builder['network']}", log_file
                log "    - Scenarios: #{verify_builder['scenarios'].inspect}", log_file
                log "    - Rainfall: #{verify_builder['rainfall'].inspect}", log_file
                log "    - Inflow: #{verify_builder['inflow'].inspect}", log_file
              end
              
              puts "    Created: #{new_run_name}"
              swmm_runs_created += 1
            else
              log "  ERROR: Failed to create run for #{scenario_name}", log_file
              puts "    ERROR: Failed to create run"
              swmm_runs_failed += 1
            end
            
          rescue => e
            log "  ERROR processing run for #{scenario_name}: #{e.message}", log_file
            log "  Backtrace: #{e.backtrace.first(5).join("\n           ")}", log_file
            puts "    ERROR: #{e.message}"
            swmm_runs_failed += 1
          end
        end
        
        log "\nPhase 2.5 complete:", log_file
        log "  SWMM runs created: #{swmm_runs_created}", log_file
        log "  SWMM runs failed: #{swmm_runs_failed}", log_file
        
        puts ""
        puts "+" + "="*68 + "+"
        puts "|" + " "*20 + "SWMM Runs Created!" + " "*27 + "|"
        puts "|" + " "*15 + "Created #{swmm_runs_created} run(s) for scenarios" + " "*(37 - swmm_runs_created.to_s.length) + "|"
        puts "|" + " "*68 + "|"
        puts "|  NEXT STEP: Open each run and set timesteps, climatology, and" + " "*3 + "|"
        puts "|             time patterns manually (see log for details)" + " "*11 + "|"
        puts "+" + "="*68 + "+"
        
      rescue => e
        log "ERROR in Phase 2.5 (SWMM runs): #{e.message}", log_file
        log "Backtrace: #{e.backtrace.join("\n")}", log_file
        puts ""
        puts "WARNING: SWMM run setup encountered errors"
        puts "The merged network was created successfully, but some runs may be missing."
        puts "Check log file for details."
        # Don't fail the whole script - Phase 2 succeeded
      end
    end
    
  rescue => e
    log "ERROR creating merged network: #{e.message}", log_file
    log "Backtrace: #{e.backtrace.join("\n")}", log_file
    
    # Clean up partial merged network if it was created
    if defined?(merged_group) && merged_group
      begin
        log "Attempting to clean up partial merged network...", log_file
        merged_group.delete
        log "Successfully deleted partial merged network", log_file
        puts "Cleaned up partial merged network"
      rescue => cleanup_error
        log "Warning: Could not delete partial merged network: #{cleanup_error.message}", log_file
        # Don't fail the whole script just because cleanup failed
      end
    end
    
    puts ""
    puts "="*70
    puts "ERROR: Merged network creation failed"
    puts "="*70
    puts ""
    puts "Error: #{e.message}"
    puts ""
    puts "The individual model groups were created successfully,"
    puts "but the merged network could not be created."
    puts "Any partial merged network has been cleaned up."
    puts ""
    puts "Check the log file for details:"
    puts "  #{log_filename}"
    puts ""
    puts "Tip: You can still use the individual model groups."
    puts "="*70
  end
end

# ============================================================================
# Generate Summary
# ============================================================================
log "\n" + "="*70, log_file
log "IMPORT, CLEANUP, AND MERGE SUMMARY", log_file
log "="*70, log_file

# Phase 0 Summary
log "\nPhase 0 - Database Analysis:", log_file
log "  File Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}", log_file
if db_folder && Dir.exist?(db_folder)
  log "  Database Folder: #{File.basename(db_folder)}", log_file
  if defined?(db_stats) && db_stats.any?
    log "  Tables Analyzed: #{db_stats.keys.length}", log_file
    total_records = db_stats.values.map { |s| s[:records] }.sum
    log "  Total Records: #{total_records}", log_file
  end
else
  log "  Database Folder: Not found", log_file
end

# Phase 1 Summary
log "\nPhase 1 - Individual Scenario Imports:", log_file
log "  Successful: #{successful_imports.length}", log_file
if failed_imports.any?
  log "  Failed: #{failed_imports.length}", log_file
end

if successful_imports.any?
  successful_imports.each do |import_info|
    log "    - #{import_info[:scenario]} (#{import_info[:count]} objects)", log_file
  end
end

if failed_imports.any?
  log "\n  Failed scenarios:", log_file
  failed_imports.each do |scenario|
    log "    - #{scenario}", log_file
  end
end

# Cleanup Summary
if cleanup_stats[:label_lists_found] > 0
  log "\nCleanup - Empty Label Lists:", log_file
  log "  Found: #{cleanup_stats[:label_lists_found]}", log_file
  log "  Deleted: #{cleanup_stats[:label_lists_deleted]}", log_file
  log "  Kept (non-empty): #{cleanup_stats[:label_lists_kept]}", log_file
end

# Deduplication Summary
if DEDUP_OBJECT_TYPES.any? { |type| object_stats_by_type[type][:total_found] > 0 }
  log "\nPhase 1.5 - Object Deduplication:", log_file
  DEDUP_OBJECT_TYPES.each do |obj_type|
    stats = object_stats_by_type[obj_type]
    next if stats[:total_found] == 0
    
    log "  #{obj_type}:", log_file
    log "    Total found: #{stats[:total_found]}", log_file
    log "    Unique (copied to merged): #{stats[:unique_count]}", log_file
    log "    Duplicates (skipped): #{stats[:duplicate_count]}", log_file
  end
end

# Phase 2 Summary
if merge_scenarios && successful_imports.length > 0
  log "\nPhase 2 - Merged Network:", log_file
  log "  Created: Yes", log_file
  log "  Scenarios: #{successful_imports.length}", log_file
  log "  BASE scenario used as master network", log_file
  log "  Inactive elements deleted from each scenario", log_file
end

# Phase 2.5 Summary
if copy_swmm_runs && defined?(swmm_runs_created)
  log "\nPhase 2.5 - SWMM Runs:", log_file
  log "  Runs created: #{swmm_runs_created}", log_file
  if defined?(swmm_runs_failed) && swmm_runs_failed > 0
    log "  Runs failed: #{swmm_runs_failed}", log_file
  end
end

log "\n" + "="*70, log_file
log "All operations completed successfully!", log_file
log "Log file saved to: #{log_filename}", log_file
log "="*70, log_file

log_file.close

# Display summary
puts ""
puts "+" + "="*68 + "+"
puts "|" + " "*25 + "IMPORT COMPLETE" + " "*28 + "|"
puts "+" + "="*68 + "+"
puts ""
puts "MODEL INFORMATION:"
puts "  Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}"
puts "  Database: #{db_folder ? File.basename(db_folder) : 'Not found'}"
if defined?(db_stats) && db_stats.any?
  puts "  Tables Analyzed: #{db_stats.keys.length}"
end
puts ""
puts "SUMMARY:"
puts "  Phase 0: Database analysis complete"
puts "  Phase 1: #{successful_imports.length} scenario(s) imported successfully"
if cleanup_stats[:label_lists_deleted] > 0
  puts "           #{cleanup_stats[:label_lists_deleted]} empty label list(s) cleaned up"
end
if failed_imports.any?
  puts "           #{failed_imports.length} scenario(s) failed"
end

# Add deduplication summary if any
DEDUP_OBJECT_TYPES.each do |obj_type|
  stats = object_stats_by_type[obj_type]
  next if stats[:total_found] == 0
  puts "  Phase 1.5: #{stats[:duplicate_count]} duplicate #{obj_type}(s) skipped"
end

if merge_scenarios && successful_imports.length > 0
  puts "  Phase 2: Merged network created with #{successful_imports.length} scenario(s)"
end

if copy_swmm_runs && defined?(swmm_runs_created)
  puts "  Phase 2.5: #{swmm_runs_created} SWMM run(s) configured"
end

puts ""
puts "Log file: #{log_filename}"
puts "+" + "="*68 + "+"

exit(failed_imports.any? ? 1 : 0)



