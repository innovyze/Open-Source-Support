# ============================================================================
# InfoSWMM/H2OMapSWMM Multi-Scenario Import - UI SCRIPT (ENHANCED)
# ============================================================================
# 
# ENHANCED VERSION - Supports both:
#   - InfoSWMM (.mxd) files with .ISDB folders
#   - H2OMapSWMM (.hsm) files with .HSDB folders
#   - Comprehensive data field statistics
#
# PURPOSE:
#   User-facing script that collects user input and launches the Exchange script
#
# WHAT THIS SCRIPT DOES:
#   Phase 1:   Import each scenario to separate model groups
#              + Clean up empty label lists after each import
#
#   Phase 1.5: Analyze and deduplicate Rainfall Events & Inflows across all scenarios
#              (Note: Time Patterns and Climatology don't support deduplication)
#
#   Phase 2:   Create merged network with all scenarios combined
#              + Copy only unique objects (deduplicated)
#              + Add all scenarios to merged network
#              + Delete inactive elements from each scenario
#
#   Phase 2.5: Set up SWMM runs for each scenario in the merged network
#              + Create runs with essential configuration (network, scenario, rainfall)
#              + Link to deduplicated rainfall/inflow events in merged group
#              [!] Manual setup required: timesteps, climatology, time patterns, inflows
#
# HOW TO USE:
#   1. Open your ICM database
#   2. Go to: Network menu -> Run Ruby Script
#   3. Select this file: InfoSWMM_Import_UI_Folder_Enhanced.rb
#   4. Follow the dialogs
#   5. Wait for import, cleanup, deduplication, merge, and run setup to complete
#   6. Manually configure timesteps, climatology, time patterns, and inflows in each run
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
    
    if dbf_paths.empty?
      # Show what IS in the folder
      puts "Listing all files in folder:"
      begin
        Dir.entries(@folder_path).each do |entry|
          next if entry == '.' || entry == '..'
          puts "  - #{entry}"
        end
      rescue => e
        puts "Could not list folder contents: #{e.message}"
      end
    end
    
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

# ============================================================================
# Main Import UI Function
# ============================================================================
def run_import_ui
  # Get the script directory
  script_dir = File.dirname(WSApplication.script_file)

  # ----------------------------------------------------------------------------
  # STEP 1: Get InfoSWMM/H2OMapSWMM model file using file dialog
  # ----------------------------------------------------------------------------
  WSApplication.message_box(
    "InfoSWMM / H2OMapSWMM Multi-Scenario Import\n\n" +
    "ENHANCED VERSION - Supports both:\n" +
    "  • InfoSWMM (.mxd) with .ISDB folders\n" +
    "  • H2OMapSWMM (.hsm) with .HSDB folders\n\n" +
    "This script will:\n" +
    "  * Read and analyze all database files\n" +
    "  * Show comprehensive data statistics\n" +
    "  * Import each scenario to a separate group\n" +
    "  * Clean up empty label lists\n" +
    "  * Deduplicate Rainfall Events & Inflows\n" +
    "  * Create a merged network with all scenarios\n" +
    "  * Set up SWMM runs (partial configuration)\n\n" +
    "Next: Choose your model type (mxd or hsm)",
    "OK",
    "Information",
    false
  )

  # Wrap file dialog in exception handler for graceful cancellation
  begin
    # Ask user which file type they want to select using radio-style boolean prompts
    file_type_result = WSApplication.prompt(
      'Select Model Type',
      [
        ['Which model type do you want to import?', 'READONLY', ''],
        ['InfoSWMM (.mxd)', 'BOOLEAN', true],
        ['H2OMapSWMM (.hsm)', 'BOOLEAN', false]
      ],
      false
    )
    
    if file_type_result.nil?
      WSApplication.message_box(
        "Import cancelled.",
        "OK",
        "Information",
        false
      )
      return
    end
    
    # file_type_result[1] = mxd checkbox, file_type_result[2] = hsm checkbox
    use_hsm = file_type_result[2]
    
    if use_hsm
      file_path = WSApplication.file_dialog(
        true,
        'hsm',
        'H2OMapSWMM Model File (.hsm)',
        '',
        false,
        nil
      )
    else
      file_path = WSApplication.file_dialog(
        true,
        'mxd',
        'InfoSWMM Model File (.mxd)',
        '',
        false,
        nil
      )
    end
  rescue Interrupt
    WSApplication.message_box(
      "Import cancelled - no file selected.",
      "OK",
      "Information",
      false
    )
    return
  end

  # Check if user cancelled
  if file_path.nil?
    WSApplication.message_box(
      "Import cancelled - no file selected.",
      "OK",
      "Information",
      false
    )
    return
  end

  puts "\n" + "="*70
  puts " InfoSWMM / H2OMapSWMM Multi-Scenario Import (ENHANCED)"
  puts "="*70
  puts "Model: #{File.basename(file_path)}"

  # ----------------------------------------------------------------------------
  # STEP 2: Determine file type and locate database folder
  # ----------------------------------------------------------------------------
  mxd_dir = File.dirname(file_path)
  ext = File.extname(file_path).downcase
  
  unless ['.mxd', '.hsm'].include?(ext)
    WSApplication.message_box(
      "ERROR: Unsupported file type: #{ext}\n\n" +
      "Expected .mxd (InfoSWMM) or .hsm (H2OMapSWMM)",
      "OK",
      "!",
      false
    )
    return
  end
  
  mxd_basename = File.basename(file_path, ext)
  
  # Determine database folder type based on file extension
  is_hsm = (ext == '.hsm')
  db_type = is_hsm ? 'HSDB' : 'ISDB'
  
  puts "File Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}"
  puts "Expected Database: #{db_type}"
  
  # Try different possible folder names
  possible_db_folders = if is_hsm
    [
      File.join(mxd_dir, "#{mxd_basename}.HSDB"),
      File.join(mxd_dir, "#{mxd_basename}.hsdb"),
      File.join(mxd_dir, "HSDB"),
      File.join(mxd_dir, "hsdb"),
      # Fallback to ISDB in case of mismatch
      File.join(mxd_dir, "#{mxd_basename}.ISDB"),
      File.join(mxd_dir, "#{mxd_basename}.isdb")
    ]
  else
    [
      File.join(mxd_dir, "#{mxd_basename}.ISDB"),
      File.join(mxd_dir, "#{mxd_basename}.isdb"),
      File.join(mxd_dir, "ISDB"),
      File.join(mxd_dir, "isdb"),
      # Fallback to HSDB in case of mismatch
      File.join(mxd_dir, "#{mxd_basename}.HSDB"),
      File.join(mxd_dir, "#{mxd_basename}.hsdb")
    ]
  end
  
  # Find the database folder - use case-insensitive matching
  db_folder = nil
  
  # First, try exact matches
  possible_db_folders.each do |folder|
    if Dir.exist?(folder)
      db_folder = folder
      break
    end
  end
  
  # If not found, try case-insensitive search
  unless db_folder
    puts "Exact folder match not found, trying case-insensitive search..."
    
    # Get all items in the model directory
    Dir.entries(mxd_dir).each do |entry|
      next if entry == '.' || entry == '..'
      full_path = File.join(mxd_dir, entry)
      next unless File.directory?(full_path)
      
      # Check if this folder matches our expected patterns (case-insensitive)
      entry_lower = entry.downcase
      basename_lower = mxd_basename.downcase
      
      if entry_lower == "#{basename_lower}.isdb" ||
         entry_lower == "#{basename_lower}.hsdb" ||
         entry_lower == "isdb" ||
         entry_lower == "hsdb"
        db_folder = full_path
        puts "Found database folder via case-insensitive match: #{entry}"
        break
      end
    end
  end
  
  unless db_folder
    # Show what folders we looked for
    folders_checked = possible_db_folders.map { |f| "  - #{File.basename(f)}" }.join("\n")
    
    WSApplication.message_box(
      "ERROR: Database folder not found!\n\n" +
      "Looking for: #{mxd_basename}.#{db_type}\n" +
      "Location: #{mxd_dir}\n\n" +
      "Folders checked:\n#{folders_checked}\n\n" +
      "Make sure the database folder exists next to the model file.",
      "OK",
      "!",
      false
    )
    return
  end
  
  puts "Found database folder: #{db_folder}"
  
  # List what's in the database folder for diagnostics
  puts "Contents of database folder:"
  begin
    entries = Dir.entries(db_folder)
    if entries.length <= 2  # Only . and ..
      puts "  (folder appears to be empty)"
    else
      entries.each do |entry|
        next if entry == '.' || entry == '..'
        full_path = File.join(db_folder, entry)
        if File.directory?(full_path)
          puts "  [DIR] #{entry}"
        else
          size = File.size(full_path) rescue 0
          puts "  #{entry} (#{size} bytes)"
        end
      end
    end
  rescue => e
    puts "  Error listing folder: #{e.message}"
  end
  
  # ----------------------------------------------------------------------------
  # STEP 3: Scan database folder and collect statistics
  # ----------------------------------------------------------------------------
  puts "\n" + "-"*70
  puts "SCANNING DATABASE FOLDER..."
  puts "-"*70
  puts "Folder: #{db_folder}"
  
  scanner = DatabaseFolderScanner.new(db_folder)
  scanner.scan
  
  if scanner.dbf_files.empty?
    puts "\nWARNING: No DBF files could be read from the database folder!"
    puts "This may indicate:"
    puts "  - The folder is empty"
    puts "  - The DBF files are corrupted"
    puts "  - File permission issues"
  end
  
  # Print summary
  scanner.print_summary
  
  # Save statistics to log file
  log_dir = File.join(mxd_dir, "ICM Import Log Files")
  Dir.mkdir(log_dir) unless Dir.exist?(log_dir)
  
  stats_log_path = File.join(log_dir, "DBF_Statistics_#{Time.now.strftime('%Y%m%d_%H%M%S')}.txt")
  File.open(stats_log_path, 'w') do |log_file|
    log_file.puts "="*70
    log_file.puts "DATABASE STATISTICS REPORT"
    log_file.puts "Generated: #{Time.now}"
    log_file.puts "Model File: #{file_path}"
    log_file.puts "Database Folder: #{db_folder}"
    log_file.puts "="*70
    
    scanner.print_summary(log_file)
    scanner.print_all_stats(log_file)
  end
  
  puts "\nDetailed statistics saved to: #{stats_log_path}"
  
  # ----------------------------------------------------------------------------
  # STEP 4: Read scenario names from SCENARIO.DBF
  # ----------------------------------------------------------------------------
  scenario_names = []
  scenario_reader = scanner.get_reader('SCENARIO')
  
  if scenario_reader
    puts "SCENARIO.DBF found with #{scenario_reader.records.length} records"
    puts "Fields in SCENARIO.DBF: #{scenario_reader.fields.map { |f| f[:name] }.join(', ')}"
    
    # Find the ID field
    id_field = scenario_reader.fields.find { |f| ['ID', 'SCEN_ID', 'NAME', 'SCENID'].include?(f[:name].upcase) }
    
    if id_field
      scenario_names = scenario_reader.get_field_values(id_field[:name])
      puts "\nFound #{scenario_names.length} scenario(s) in SCENARIO.DBF (using field '#{id_field[:name]}'):"
      scenario_names.each { |s| puts "  - #{s}" }
    else
      puts "WARNING: Could not find ID field in SCENARIO.DBF"
      puts "Looking for: ID, SCEN_ID, NAME, or SCENID"
      puts "Fields found: #{scenario_reader.fields.map { |f| f[:name] }.join(', ')}"
      
      # Show first record to help debug
      if scenario_reader.records.any?
        puts "First record data:"
        scenario_reader.records.first.each do |key, value|
          puts "  #{key}: '#{value}'"
        end
      end
    end
  else
    puts "WARNING: SCENARIO.DBF not found in database folder"
    puts "Available DBF files: #{scanner.dbf_files.keys.join(', ')}"
  end
  
  # Show quick statistics summary dialog
  quick_stats = "Database Statistics Summary\n\n"
  quick_stats += "Database Folder: #{File.basename(db_folder)}\n"
  quick_stats += "Tables Found: #{scanner.dbf_files.length}\n\n"
  
  # List key tables with record counts
  key_tables = ['SCENARIO', 'JUNCTION', 'CONDUIT', 'OUTFALL', 'STORAGE', 'PUMP', 'ORIFICE', 'WEIR', 'SUBCATCHMENT']
  key_tables.each do |table|
    reader = scanner.get_reader(table)
    if reader
      quick_stats += "  #{table}: #{reader.records.length} records\n"
    end
  end
  
  quick_stats += "\nFull statistics saved to log file.\n"
  quick_stats += "Continue with scenario selection?"
  
  result = WSApplication.message_box(
    quick_stats,
    "YesNo",
    "Information",
    false
  )
  
  if result == "No"
    WSApplication.message_box(
      "Import cancelled.\n\nStatistics log saved to:\n#{stats_log_path}",
      "OK",
      "Information",
      false
    )
    return
  end
  
  # ----------------------------------------------------------------------------
  # STEP 5: Prompt for scenario selection
  # ----------------------------------------------------------------------------
  if scenario_names.any?
    # Separate BASE from other scenarios
    base_scenario = scenario_names.find { |s| s.upcase == 'BASE' }
    other_scenarios = scenario_names.reject { |s| s.upcase == 'BASE' }
    
    # Build prompt with checkboxes for each scenario
    layout = [
      ['BASE imported automatically', 'READONLY', ''],
      ['', 'READONLY', ''],
      ['Select additional scenarios:', 'READONLY', ''],
      ['Select All', 'BOOLEAN', false]
    ]
    
    other_scenarios.each do |scenario|
      layout << [scenario, 'BOOLEAN', false]
    end
    
    result = WSApplication.prompt(
      'Select Scenarios to Import',
      layout,
      false
    )
    
    if result.nil?
      WSApplication.message_box(
        "Import cancelled - no scenarios selected.",
        "OK",
        "Information",
        false
      )
      return
    end
    
    # Check if "Select All" is checked
    select_all = result[3]
    
    # Collect selected scenarios
    selected_scenarios = []
    other_scenarios.each_with_index do |scenario, index|
      if select_all || result[index + 4]
        selected_scenarios << scenario
      end
    end
    
    # Always add BASE automatically
    if base_scenario
      selected_scenarios.unshift(base_scenario)
      puts "BASE will be imported automatically"
    else
      puts "WARNING: No BASE scenario found in model"
      puts "The first selected scenario will be used as the master network"
    end
    
    # Check if any scenarios were selected
    if selected_scenarios.length == 1 && selected_scenarios.first&.upcase == 'BASE'
      result = WSApplication.message_box(
        "Only BASE Scenario Selected\n\n" +
        "You haven't selected any additional scenarios.\n\n" +
        "This script is designed to merge multiple scenarios.\n" +
        "With only BASE, you'll get a single network.\n\n" +
        "Continue with only BASE?",
        "YesNo",
        "?",
        false
      )
      if result == "No"
        return
      end
    end
    
    scenario_input = selected_scenarios.join(',')
    puts "Importing #{selected_scenarios.length} scenario(s)"
    
  else
    # Fallback to manual entry
    layout = [
      ['Could not auto-detect scenarios.', 'READONLY', 'Enter scenario names manually'],
      ['Scenarios', 'STRING', '', nil]
    ]
    
    result = WSApplication.prompt(
      'Enter Scenarios Manually',
      layout,
      false
    )
    
    if result.nil?
      WSApplication.message_box(
        "Import cancelled - no scenarios entered.",
        "OK",
        "Information",
        false
      )
      return
    end
    
    scenario_input = result[1].strip
    
    if scenario_input.empty?
      WSApplication.message_box(
        "No scenarios entered. Import cancelled.",
        "OK",
        "Information",
        false
      )
      return
    end
    
    selected_scenarios = scenario_input.split(',').map(&:strip)
    puts "Importing #{selected_scenarios.length} scenario(s)"
  end

  puts "="*70

  # ----------------------------------------------------------------------------
  # STEP 6: Verify BASE scenario is included
  # ----------------------------------------------------------------------------
  scenarios_list = scenario_input.split(',').map(&:strip)
  unless scenarios_list.any? { |s| s.upcase == 'BASE' }
    result = WSApplication.message_box(
      "WARNING: No BASE Scenario Found\n\n" +
      "The merged network needs a BASE scenario\n" +
      "to use as the master network.\n\n" +
      "Without BASE, the first selected scenario\n" +
      "will be used as the master.\n\n" +
      "Continue anyway?",
      "YesNo",
      "!",
      false
    )
    
    if result == "No"
      return
    end
  end

  # ----------------------------------------------------------------------------
  # STEP 7: Get database path for Exchange script
  # ----------------------------------------------------------------------------
  db = WSApplication.current_database
  db_guid = db.guid

  # ----------------------------------------------------------------------------
  # STEP 8: Save configuration to YAML file
  # ----------------------------------------------------------------------------
  config = {
    'file_path' => file_path,
    'scenarios' => scenario_input,
    'database_guid' => db_guid,
    'timestamp' => Time.now.to_s,
    'merge_scenarios' => true,
    'cleanup_empty_label_lists' => true,
    'copy_swmm_runs' => true,
    # Enhanced fields
    'file_type' => is_hsm ? 'H2OMapSWMM' : 'InfoSWMM',
    'file_extension' => ext,
    'db_folder' => db_folder,
    'db_type' => db_type,
    'dbf_tables_found' => scanner.dbf_files.keys,
    'stats_log_path' => stats_log_path
  }

  config_file = File.join(log_dir, 'import_config.yaml')
  File.open(config_file, 'w') { |f| f.write(config.to_yaml) }

  # ----------------------------------------------------------------------------
  # STEP 9: Launch Exchange script
  # ----------------------------------------------------------------------------
  exchange_script = File.join(script_dir, 'InfoSWMM_Import_Exchange_Folder_Enhanced.rb')
  
  # Fallback to original if enhanced version not found
  unless File.exist?(exchange_script)
    exchange_script = File.join(script_dir, 'InfoSWMM_Import_Exchange_Folder.rb')
  end
  
  unless File.exist?(exchange_script)
    WSApplication.message_box(
      "ERROR: Exchange script not found!\n\n" +
      "Expected: InfoSWMM_Import_Exchange_Folder.rb\n" +
      "Location: #{script_dir}",
      "OK",
      "!",
      false
    )
    return
  end

  # Pass config file location to Exchange script
  ENV['ICM_IMPORT_CONFIG'] = config_file

  # Find ICMExchange.exe
  icm_exchange = nil
  [
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Ultimate 2026\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Sewer 2026\\ICMExchange.exe",
    "C:\\Program Files\\Autodesk\\InfoWorks ICM Flood 2026\\ICMExchange.exe",
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
    return
  end

  # Launch Exchange script
  command = "\"#{icm_exchange}\" \"#{exchange_script}\" /ICM"

  require 'open3'
  output, status = Open3.capture2(command)
  success = status.success?

  # Parse console output for statistics
  scenarios_imported = output.match(/Phase 1: (\d+) scenario\(s\) imported successfully/)
  label_lists_cleaned = output.match(/(\d+) empty label list\(s\) cleaned up/)
  duplicates_skipped = output.match(/Phase 1\.5: (\d+) duplicate Rainfall Event/)
  merged_created = output.match(/Phase 2: Merged network created with (\d+) scenario/)
  swmm_runs_created = output.match(/Phase 2\.5: (\d+) SWMM run\(s\) created/)

  # Display summary
  puts "\n" + "="*70
  puts " IMPORT SUMMARY"
  puts "="*70
  puts ""
  puts "MODEL INFORMATION:"
  puts "  Type: #{is_hsm ? 'H2OMapSWMM (.hsm)' : 'InfoSWMM (.mxd)'}"
  puts "  Database: #{File.basename(db_folder)}"
  puts "  Tables: #{scanner.dbf_files.length}"
  puts ""

  if scenarios_imported
    puts "PHASE 1: Individual Scenario Import"
    puts "  * #{scenarios_imported[1]} scenario(s) imported to separate groups"
    if label_lists_cleaned
      puts "  * #{label_lists_cleaned[1]} empty label list(s) cleaned up"
    end
    puts ""
  end

  if duplicates_skipped && duplicates_skipped[1].to_i > 0
    puts "PHASE 1.5: Object Deduplication"
    puts "  * #{duplicates_skipped[1]} duplicate Rainfall Event(s) detected"
    puts "  * Only unique events copied to merged network"
    puts ""
  end

  if merged_created
    puts "PHASE 2: Merged Network Creation"
    puts "  * Master network created from BASE scenario"
    puts "  * #{merged_created[1]} scenario(s) combined into one network"
    puts "  * Inactive elements removed from each scenario"
    puts ""
  end

  if swmm_runs_created
    puts "PHASE 2.5: SWMM Run Setup"
    puts "  * #{swmm_runs_created[1]} SWMM run(s) configured in merged network"
    puts ""
  end

  puts "SCENARIOS IMPORTED:"
  selected_scenarios.each do |scenario|
    puts "  * #{scenario}"
  end

  puts ""
  puts "LOG FILES:"
  puts "  Stats: #{stats_log_path}"
  puts "  Logs: #{log_dir}"
  puts ""
  puts "="*70

  # Show completion message
  if success
    summary = "Import Complete!\n\n"
    summary += "Model Type: #{is_hsm ? 'H2OMapSWMM' : 'InfoSWMM'}\n"
    summary += "Database: #{File.basename(db_folder)}\n"
    summary += "Tables Found: #{scanner.dbf_files.length}\n\n"
    
    if scenarios_imported
      summary += "Imported: #{scenarios_imported[1]} scenario(s)\n"
    else
      summary += "Imported: #{selected_scenarios.length} scenario(s)\n"
    end
    
    if merged_created
      summary += "Merged: #{merged_created[1]} scenario(s)\n"
    end
    
    summary += "\nStatistics saved to log folder.\n"
    summary += "See Ruby output window for full details."
    
    WSApplication.message_box(
      summary,
      "OK",
      "Information",
      false
    )
  else
    WSApplication.message_box(
      "Import Failed\n\n" +
      "Check the Ruby output window for details.\n\n" +
      "Statistics saved to:\n#{stats_log_path}",
      "OK",
      "Warning",
      false
    )
  end

end  # End of run_import_ui method

# Run the import UI
run_import_ui
