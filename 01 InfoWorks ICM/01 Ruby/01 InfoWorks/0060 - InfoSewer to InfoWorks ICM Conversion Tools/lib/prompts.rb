require 'yaml'

# Show user prompt to customize the import
#
# @param config_file [String] path to the config file
# @return [Hash] returns a hash of config options and values

def prompt_get_config(config_file)
  # Load previous config if it exists, otherwise use defaults
  if File.exist?(config_file)
    previous = YAML.load_file(config_file)
  else
    # Default config for first run
    script_dir = File.dirname(config_file)
    previous = {
      'model_path' => '',
      'fields_path' => File.join(script_dir, 'field_mappings')
    }
  end
  
  # Options hash
  # The keys are symbols for each config option
  # The values are the WSApplication.prompt layout structure
  options = {
    model_path: ['InfoSewer Model (.IEDB folder)', 'String', previous['model_path'], nil, 'FOLDER', 'Select the .IEDB folder'],
    fields_path: ['Field mapping YAML folder', 'String', previous['fields_path'], nil, 'FOLDER', 'Folder containing YAML files']
  }
  
  response = WSApplication.prompt('InfoSewer to ICM Importer - Configuration', options.values, false)
  
  # Check if user cancelled
  return nil if response.nil?
  
  # Build config hash from response
  config = Hash.new
  options.keys.each_with_index { |key, i| config[key] = response[i] }
  
  # Validate paths - check they exist, and convert to Unix style
  [:model_path, :fields_path].each do |path|
    unless file_exists?(config[path])
      WSApplication.message_box(
        "Invalid path: #{path.to_s}\n\n#{config[path]}\n\nPath does not exist.",
        "OK",
        "!",
        false
      )
      return nil
    end
    config[path] = path_to_unix(config[path])
  end
  
  # Save the config for next time
  yaml_hash = Hash.new
  config.each { |key, value| yaml_hash[key.to_s] = value }
  File.write(config_file, yaml_hash.to_yaml)
  
  return config
end

# Prompt user if they want to delete network contents
#
# @return [Boolean] true if user wants to continue, false if cancelled

def prompt_delete_network
  response = WSApplication.message_box(
    "Network is not empty!\n\n" +
    "The current network contains existing objects.\n" +
    "If you continue, these objects will be deleted.\n\n" +
    "Are you sure you want to continue?",
    'YesNo',
    '?',
    true
  )
  
  return (response == 'Yes')
end

# Read scenario names from SCENARIO.DBF file
#
# @param iedb_path [String] path to the .IEDB folder
# @return [Array] array of scenario names found

def read_scenario_names_from_dbf(iedb_path)
  scenario_names = []
  
  # Try different possible names for the scenario file
  possible_files = [
    File.join(iedb_path, "SCENARIO.DBF"),
    File.join(iedb_path, "Scenario.dbf"),
    File.join(iedb_path, "scenario.DBF")
  ]
  
  scenario_dbf = possible_files.find { |f| File.exist?(f) }
  
  return scenario_names unless scenario_dbf
  
  begin
    # Read DBF file to get scenario names
    File.open(scenario_dbf, 'rb') do |file|
      # Read DBF header
      version = file.read(1)
      raise "File is empty or unreadable" if version.nil?
      
      last_update = file.read(3)
      num_records_bytes = file.read(4)
      header_length_bytes = file.read(2)
      record_length_bytes = file.read(2)
      
      raise "DBF header is incomplete" if num_records_bytes.nil?
      
      num_records = num_records_bytes.unpack('V')[0]
      header_length = header_length_bytes.unpack('v')[0]
      record_length = record_length_bytes.unpack('v')[0]
      
      file.read(20)  # Reserved
      
      # Read field descriptors
      fields = []
      field_offset = 1  # First byte is delete flag
      
      loop do
        field_name_bytes = file.read(11)
        break if field_name_bytes.nil? || field_name_bytes[0] == "\r" || field_name_bytes[0] == "\x0D"
        
        field_name = field_name_bytes.unpack('Z11')[0]
        break if field_name.nil? || field_name.empty?
        
        field_type = file.read(1)
        file.read(4)  # Reserved
        field_length = file.read(1).unpack('C')[0]
        file.read(15)  # Decimals + reserved
        
        fields << {
          name: field_name.strip,
          type: field_type,
          offset: field_offset,
          length: field_length
        }
        
        field_offset += field_length
      end
      
      # Find the ID field (could be ID, SCEN_ID, NAME, etc.)
      id_field = fields.find { |f| ['ID', 'SCEN_ID', 'NAME', 'SCENID'].include?(f[:name].upcase) }
      
      return scenario_names if id_field.nil?
      
      # Skip to data records
      file.seek(header_length)
      
      # Read each record
      num_records.times do
        record = file.read(record_length)
        next if record.nil? || record[0] == '*'  # Skip deleted records
        
        # Extract ID field value
        id_value = record[id_field[:offset], id_field[:length]].strip
        scenario_names << id_value unless id_value.empty?
      end
    end
  rescue => e
    puts "WARNING: Could not read SCENARIO.DBF: #{e.message}"
  end
  
  return scenario_names
end

# Prompt user to select scenarios to import
#
# @param scenario_names [Array] array of available scenario names
# @return [Array, nil] array of selected scenario names, or nil if cancelled

def prompt_select_scenarios(scenario_names)
  if scenario_names.empty?
    # Fallback to manual entry
    layout = [
      ['Could not detect scenarios automatically.', 'READONLY', ''],
      ['Enter scenario names (comma-separated):', 'String', 'BASE']
    ]
    
    result = WSApplication.prompt('Enter Scenarios Manually', layout, false)
    return nil if result.nil?
    
    return result[1].split(',').map(&:strip)
  end
  
  # Separate BASE from other scenarios
  base_scenario = scenario_names.find { |s| s.upcase == 'BASE' }
  other_scenarios = scenario_names.reject { |s| s.upcase == 'BASE' }
  
  # Build prompt with checkboxes
  layout = [
    ['BASE will be imported automatically', 'READONLY', ''],
    ['', 'READONLY', ''],  # Blank line
    ['Select additional scenarios to import:', 'READONLY', ''],
    ['Select All', 'Boolean', false]
  ]
  
  other_scenarios.each do |scenario|
    layout << [scenario, 'Boolean', false]
  end
  
  result = WSApplication.prompt('Select Scenarios to Import', layout, false)
  return nil if result.nil?
  
  # Check if "Select All" is checked
  select_all = result[3]
  
  # Collect selected scenarios
  selected_scenarios = []
  other_scenarios.each_with_index do |scenario, index|
    if select_all || result[index + 4]
      selected_scenarios << scenario
    end
  end
  
  # Always add BASE first
  if base_scenario
    selected_scenarios.unshift(base_scenario)
  else
    puts "WARNING: No BASE scenario found - using first scenario as master"
  end
  
  return selected_scenarios
end

