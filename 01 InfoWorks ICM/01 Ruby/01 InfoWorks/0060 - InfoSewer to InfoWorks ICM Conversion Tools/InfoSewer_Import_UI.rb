# ============================================================================
# InfoSewer to InfoWorks ICM Import Tool - UI SCRIPT
# ============================================================================
#
# PURPOSE:
#   User-facing script for importing InfoSewer models to InfoWorks ICM
#
# WHAT THIS SCRIPT DOES:
#   1. Prompts user for InfoSewer model location and import settings
#   2. Auto-detects available scenarios from model data
#   3. Lets user select which scenarios to import (BASE is required)
#   4. Reads InfoSewer data files directly
#   5. Imports BASE scenario geometry and data
#   6. Creates subcatchments for all manholes
#   7. Applies post-import cleanup (SQL and Ruby)
#   8. Creates scenarios in ICM for each selected scenario
#   9. Imports scenario-specific data (MHHYD, PIPEHYD, PUMPHYD, WWELLHYD)
#  10. Imports InfoSewer selection sets as ICM selection lists
#  11. Imports InfoSewer query sets as ICM selection lists
#
# HOW TO USE:
#   1. Open your ICM database
#   2. Create or open an empty InfoWorks network
#   3. Go to: Network menu -> Run Ruby Script
#   4. Select this file: InfoSewer_Import_UI.rb
#   5. Follow the dialogs
#   6. Wait for import to complete
#
# KEY FEATURES:
#   - No Excel required (reads InfoSewer data natively)
#   - No manual file conversion required
#   - No ArcCatalog shapefile conversion required
#   - Automatic scenario detection and selection
#   - Comprehensive field mapping via configuration files
#   - Post-import cleanup and validation
#   - Progress logging to script window
#
# REQUIREMENTS:
#   - InfoWorks ICM 2024+
#   - InfoSewer model (.IEDB folder)
#   - Open ICM database with current network
#
# ============================================================================

# Load helper modules
load File.join(__dir__, 'lib', 'dbf_reader.rb')
load File.join(__dir__, 'lib', 'data.rb')
load File.join(__dir__, 'lib', 'prompts.rb')
load File.join(__dir__, 'lib', 'geo.rb')
load File.join(__dir__, 'lib', 'sql_cleanup.rb')
load File.join(__dir__, 'lib', 'scenario_import.rb')
load File.join(__dir__, 'lib', 'selection_sets.rb')
load File.join(__dir__, 'lib', 'active_selection.rb')
load File.join(__dir__, 'lib', 'query_sets.rb')

def main()
  # Clear global variables (these persist between UI script runs)
  $dbf_hash = nil        # Hash of InfoSewer DBFs to their filepaths
  $data_cached = Hash.new # Cached data
  $field_maps = nil      # Field mappings for each object type
  $config = nil          # Config hash
  $scenarios = nil       # Scenario data hash
  $sanitized_ids = nil   # Track IDs that were sanitized for ICM compatibility
  $case_corrections = nil # Track node IDs that were case-corrected
  
  # ----------------------------------------------------------------
  # Get the current network
  # ----------------------------------------------------------------
  network = WSApplication.current_network
  
  if network.nil?
    WSApplication.message_box(
      "No network is currently open!\n\n" +
      "Please open or create an InfoWorks network first.",
      "OK",
      "!",
      false
    )
    return false
  end
  
  # ----------------------------------------------------------------
  # Verify network type (must be InfoWorks, not SWMM)
  # ----------------------------------------------------------------
  begin
    # Try to access hw_node table - this will fail if not an InfoWorks network
    test_table = network.row_objects('hw_node')
  rescue => err
    # Network doesn't support hw_node table - wrong network type
    WSApplication.message_box(
      "Wrong Network Type!\n\n" +
      "InfoSewer models are converted to InfoWorks networks, not SWMM.\n\n" +
      "Solution:\n" +
      "  1. Right-click on your Model Group\n" +
      "  2. Select: New InfoWorks > InfoWorks Network\n" +
      "  3. Open the new network and re-run this script",
      "OK",
      "!",
      false
    )
    return false
  end
  
  # Check if the network is empty - if not, prompt the user
  unless is_network_empty?(network)
    continue = prompt_delete_network()
    unless continue
      WSApplication.message_box(
        "Import cancelled by user.",
        "OK",
        "!",
        false
      )
      return false
    end
  end
  
  # ----------------------------------------------------------------
  # Get configuration from user
  # ----------------------------------------------------------------
  config_path = File.join(__dir__, 'config.yaml')
  $config = prompt_get_config(config_path)
  
  if $config.nil?
    WSApplication.message_box(
      "Import cancelled by user.",
      "OK",
      "!",
      false
    )
    return false
  end
  
  # Ensure we have the IEDB path
  iedb_path = $config[:model_path]
  unless iedb_path.end_with?('.IEDB') || iedb_path.end_with?('.iedb')
    iedb_path = File.join(File.dirname(iedb_path), File.basename(iedb_path, '.*') + '.IEDB')
  end
  
  unless Dir.exist?(iedb_path)
    WSApplication.message_box(
      "Cannot find IEDB folder!\n\n#{iedb_path}\n\nPlease check the model path.",
      "OK",
      "!",
      false
    )
    return false
  end
  
  # ----------------------------------------------------------------
  # Read and select scenarios
  # ----------------------------------------------------------------
  scenario_names = read_scenario_names_from_dbf(iedb_path)
  
  if scenario_names.empty?
    scenario_names = ['BASE']
  end
  
  selected_scenarios = prompt_select_scenarios(scenario_names)
  
  if selected_scenarios.nil? || selected_scenarios.empty?
    WSApplication.message_box(
      "Import cancelled - no scenarios selected.",
      "OK",
      "!",
      false
    )
    return false
  end
  
  # ----------------------------------------------------------------
  # Load field mappings
  # ----------------------------------------------------------------
  types = ['manhole', 'outlet', 'wetwell', 'pipe', 'forcemain', 'pump', 'subcatchment', 'unit_hydrograph']
  $field_maps = get_field_maps($config[:fields_path], types)
  
  # ----------------------------------------------------------------
  # Confirm import
  # ----------------------------------------------------------------
  message = "Ready to import InfoSewer model.\n\n" +
            "Model: #{File.basename($config[:model_path], '.*')}\n" +
            "Scenarios: #{selected_scenarios.join(', ')}\n\n" +
            "Do you want to proceed?"
  
  proceed = WSApplication.message_box(
    message,
    "YesNo",
    "?",
    false
  )
  
  if proceed == "No"
    WSApplication.message_box(
      "Import cancelled by user.",
      "OK",
      "!",
      false
    )
    return false
  end
  
  # ----------------------------------------------------------------
  # Print header - all user confirmations done, starting import
  # ----------------------------------------------------------------
  puts ""
  puts "="*70
  puts " InfoSewer to InfoWorks ICM Import Tool"
  puts "="*70
  puts ""
  puts "Using model folder for data import"
  puts ""
  puts "Model: #{File.basename(iedb_path, '.IEDB')}"
  puts "IEDB: #{iedb_path}"
  
  if scenario_names.any?
    puts ""
    puts "Found #{scenario_names.length} scenario(s): #{scenario_names.join(', ')}"
  end
  
  puts ""
  puts "Scenarios: #{selected_scenarios.join(', ')}"
  puts ""
  puts "Loaded #{$field_maps.keys.length} field mapping(s)"
  
  # ----------------------------------------------------------------
  # Read data files
  # ----------------------------------------------------------------
  $dbf_hash = get_dbf_files_for_import(iedb_path)
  puts "\nFound #{$dbf_hash.keys.length} data file(s) for BASE scenario"
  puts "(Scenario-specific data in subfolders will be used during scenario import)"
  
  # ----------------------------------------------------------------
  # Read and validate network geometry
  # ----------------------------------------------------------------
  puts "\nReading network geometry..."
  
  nodes, links = get_network_geometry()
  
  puts "  Nodes: #{nodes.length}"
  puts "  Links: #{links.length}"
  
  # Report sanitized IDs if any
  if $sanitized_ids && !$sanitized_ids.empty?
    puts ""
    puts "Note: #{$sanitized_ids.length} ID(s) sanitized for ICM compatibility:"
    $sanitized_ids.first(5).each { |s| puts "  #{s[:original]} -> #{s[:sanitized]}" }
    puts "  ... and #{$sanitized_ids.length - 5} more" if $sanitized_ids.length > 5
    puts "(Dots replaced with underscores - ICM node IDs cannot contain dots)"
    puts ""
  end
  
  # Report case corrections
  if $case_corrections && !$case_corrections.empty?
    puts ""
    puts "Note: #{$case_corrections.length} node ID(s) corrected for case sensitivity:"
    $case_corrections.first(5).each { |c| puts "  #{c[:original]} -> #{c[:corrected]}" }
    puts "  ... and #{$case_corrections.length - 5} more" if $case_corrections.length > 5
    puts "(Link references matched to actual node IDs - case-insensitive)"
    puts ""
  end
  
  # ----------------------------------------------------------------
  # Import BASE scenario to ICM
  # ----------------------------------------------------------------
  puts "\nImporting BASE scenario network to ICM..."
  
  network.transaction_begin
  clear_network(network)
  import_nodes(network, nodes)
  import_links(network, links)
  import_unit_hydrographs(network)
  network.transaction_commit
  
  puts "  [OK] Import complete"
  
  # ----------------------------------------------------------------
  # Post-import cleanup
  # ----------------------------------------------------------------
  run_all_cleanup_sql(network)
  run_ruby_cleanup(network)
  
  # Check for wetwell limitation and display notice
  wetwell_count = 0
  network.row_objects('hw_node').each do |node|
    if node.user_text_10 && node.user_text_10.to_s == 'WetWell'
      wetwell_count += 1
    end
  end
  
  if wetwell_count > 0
    puts ""
    puts "="*70
    puts " WETWELL LIMITATION"
    puts "="*70
    puts " This tool assumes wetwells use a fixed DIAMETER."
    puts " If your InfoSewer model uses wetwell CURVES instead,"
    puts " you must manually set chamber_area and shaft_area."
    puts " Wetwells found: #{wetwell_count}"
    puts "="*70
  end
  
  # ----------------------------------------------------------------
  # Create scenarios
  # ----------------------------------------------------------------
  if selected_scenarios.length > 1
    puts "\nCreating scenarios in ICM..."
    
    # Delete all scenarios except BASE
    network.scenarios do |scenario|
      network.delete_scenario(scenario) unless scenario == 'Base'
    end
    
    # Add selected scenarios (skip BASE as it already exists)
    selected_scenarios.each do |scenario_name|
      next if scenario_name.upcase == 'BASE'
      
      begin
        network.add_scenario(scenario_name, nil, '')
        puts "  [OK] Created scenario: #{scenario_name}"
      rescue => err
        puts "  ! Error creating scenario #{scenario_name}: #{err.message}"
      end
    end
    
    puts "Scenario creation complete"
  end
  
  # ----------------------------------------------------------------
  # Import scenario-specific data
  # ----------------------------------------------------------------
  if selected_scenarios.length > 0
    import_all_scenario_data(network, selected_scenarios, iedb_path)
    
    # Re-validate conduit lengths after scenario imports
    # (scenario-specific PIPEHYD data may have overwritten lengths)
    network.transaction_begin
    sql_resolve_conduit_lengths(network)
    network.transaction_commit
  end
  
  # ----------------------------------------------------------------
  # Create root active network selection list (always run)
  # ----------------------------------------------------------------
  begin
    # Get parent object (Model Group) for creating selection lists
    db = WSApplication.current_database
    current_network_object = network.model_object
    parent_id = current_network_object.parent_id
    
    # Try to find parent as Model Group, if that fails, find its parent
    begin
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    rescue
      parent_object = db.model_object_from_type_and_id('Model Network', parent_id)
      parent_id = parent_object.parent_id
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    end
    
    # Create AN_Root selection list from root ANODE/ALINK files
    create_root_active_network_selection(network, parent_object, iedb_path)
  rescue => err
    puts "\nWarning: Could not create root active network selection list: #{err.message}"
  end
  
  # ----------------------------------------------------------------
  # Create selection lists for Active Network scenarios (FAC_TYPE=0)
  # ----------------------------------------------------------------
  begin
    # Get parent object (Model Group) for creating selection lists
    db = WSApplication.current_database
    current_network_object = network.model_object
    parent_id = current_network_object.parent_id
    
    # Try to find parent as Model Group, if that fails, find its parent
    begin
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    rescue
      parent_object = db.model_object_from_type_and_id('Model Network', parent_id)
      parent_id = parent_object.parent_id
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    end
    
    # Read scenario metadata to identify FAC_TYPE=0 scenarios
    scenario_metadata = read_scenario_metadata(iedb_path)
    
    # Create selection lists for active network scenarios
    if scenario_metadata && !scenario_metadata.empty?
      create_active_network_selections(network, parent_object, scenario_metadata, iedb_path)
    end
  rescue => err
    puts "\nWarning: Could not create active network selection lists: #{err.message}"
  end
  
  # ----------------------------------------------------------------
  # Import InfoSewer selection sets as ICM selection lists
  # ----------------------------------------------------------------
  begin
    # Get parent object (Model Group) for creating selection lists
    db = WSApplication.current_database
    current_network_object = network.model_object
    parent_id = current_network_object.parent_id
    
    # Try to find parent as Model Group, if that fails, find its parent
    begin
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    rescue
      parent_object = db.model_object_from_type_and_id('Model Network', parent_id)
      parent_id = parent_object.parent_id
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    end
    
    import_selection_sets(network, iedb_path, parent_object)
  rescue => err
    puts "\nWarning: Could not import selection sets: #{err.message}"
  end
  
  # ----------------------------------------------------------------
  # Import InfoSewer query sets as ICM selection lists
  # ----------------------------------------------------------------
  begin
    # Get parent object (Model Group) for creating selection lists
    db = WSApplication.current_database
    current_network_object = network.model_object
    parent_id = current_network_object.parent_id
    
    # Try to find parent as Model Group, if that fails, find its parent
    begin
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    rescue
      parent_object = db.model_object_from_type_and_id('Model Network', parent_id)
      parent_id = parent_object.parent_id
      parent_object = db.model_object_from_type_and_id('Model Group', parent_id)
    end
    
    import_query_sets(network, iedb_path, parent_object)
  rescue => err
    puts "\nWarning: Could not import query sets: #{err.message}"
  end
  
  # ----------------------------------------------------------------
  # Print summary statistics
  # ----------------------------------------------------------------
  print_import_summary(network)
  
  
  # ----------------------------------------------------------------
  # Done!
  # ----------------------------------------------------------------
  puts ""
  puts "="*70
  puts " Import Complete!"
  puts "="*70
  puts ""
  puts "Next steps:"
  puts "  1. Validate the network"
  puts "  2. Review node/link properties"
  puts "  3. Set up rainfall and simulation parameters"
  puts ""
  puts "="*70
  
  return true  # Import completed successfully
end

# Get data for a given DBF file, with caching
# Note: Function name kept as 'get_csv' for backward compatibility
#
# @param name [String] name of the DBF file - lowercase, no extension
# @param hash_by_id [Boolean] whether to return as hash keyed by ID
# @param cache [Boolean] whether to use/store cache
# @return [Hash or Array] the data from the DBF file
#

def get_csv(name, hash_by_id: true, cache: true)
  # Try cache first
  if cache
    data = $data_cached[name]
    return data unless data.nil?
  end
  
  # Read the data file
  path = $dbf_hash[name]
  return hash_by_id ? Hash.new : [] if path.nil?
  
  data = read_csv(path, hash_by_id)
  
  puts "  Read #{data.size} row(s) from #{name.upcase}" if data.size > 0
  
  # Cache it
  $data_cached[name] = data if cache
  
  return data
end

# Get network geometry (nodes and links)
#
# @return [Hash, Hash] nodes and links hashes

def get_network_geometry()
  # Import ALL nodes and links from BASE scenario
  # Note: ANODE/ALINK DBFs contain scenario-specific active elements and are NOT used.
  #       MANHOLE/PIPE DBFs contain the complete BASE network (all elements).
  #       This ensures BASE is always imported correctly regardless of which scenario
  #       was last saved in InfoSewer.
  
  # Read node data
  node_data = get_csv('node', cache: false)
  manhole_data = get_csv('manhole', hash_by_id: false, cache: false)
  wwell_data = get_csv('wwell', hash_by_id: false, cache: false)
  nodes = get_model_nodes(manhole_data, wwell_data, node_data)
  
  # Read link data
  vertex_data = get_csv('vertex', hash_by_id: false, cache: false)
  link_data = get_csv('link', cache: false)
  pipe_data = get_csv('pipe', hash_by_id: false, cache: false)
  pump_data = get_csv('pump', hash_by_id: false, cache: false)
  links = get_model_links(vertex_data, link_data, pipe_data, pump_data, nodes)
  
  # Validate connectivity (removes invalid links, never returns false)
  validate_connectivity(nodes, links)
  
  return nodes, links
end

# Import nodes into the network
#
# @param network [WSOpenNetwork] the network
# @param nodes [Hash] hash of nodes to import

def import_nodes(network, nodes)
  nodes.each do |id, data|
    type = data[:type]
    fields = $field_maps[type]
    
    if fields.nil?
      # Skip warning - field mappings are optional
      next
    end
    
    # Create the node
    node = new_node(network, id, fields['table'], data[:x], data[:y], data[:z], nil)
    apply_fields_to_object(node, id, fields, $config)
  end
  
  # Note: Subcatchments are created via SQL after import (sql_create_subcatchments)
  # Scenario-specific subcatchment data is then imported from MHHYD.DBF during scenario import
end

# Import links into the network
#
# @param network [WSOpenNetwork] the network
# @param links [Hash] hash of links to import

def import_links(network, links)
  links.each do |id, data|
    type = data[:type]
    fields = $field_maps[type]
    
    if fields.nil?
      # Skip warning - field mappings are optional
      next
    end
    
    link = new_link(network, id, fields['table'], data[:from], data[:to], data[:bends], nil)
    apply_fields_to_object(link, id, fields, $config)
  end
end

# Import RDII unit hydrographs into the network
#
# @param network [WSOpenNetwork] the network

def import_unit_hydrographs(network)
  fields = $field_maps['unit_hydrograph']
  return if fields.nil?
  
  hydrogrh_csv = get_csv('hydrogrh', hash_by_id: true, cache: true)
  return if hydrogrh_csv.empty?
  
  count = 0
  hydrogrh_csv.each do |id, row|
    begin
      uh = network.new_row_object(fields['table'])
      uh.ID = id
      
      # Apply field mappings
      fields['import'].each do |csv_name, field_hash|
        next unless csv_name == 'hydrogrh'
        csv_data = get_csv(csv_name, hash_by_id: true, cache: true)
        next if csv_data[id].nil?
        
        field_hash.each do |icm_field, infosewer_field|
          next if icm_field.upcase == 'ID'  # Already set
          value = csv_data[id][infosewer_field]
          next if value.nil? || value.to_s.strip.empty?
          
          begin
            uh[icm_field] = value
          rescue => e
            puts "  Warning: Could not set #{icm_field} on unit hydrograph #{id}: #{e.message}"
          end
        end
      end
      
      uh.write
      count += 1
    rescue => e
      puts "  Warning: Could not create unit hydrograph #{id}: #{e.message}"
    end
  end
  
  puts "  Imported #{count} RDII unit hydrograph(s)" if count > 0
end

# Print summary statistics about the imported network
#
# @param network [WSOpenNetwork] the network

def print_import_summary(network)
  # Count objects
  node_count = network.row_objects('_nodes').size
  link_count = network.row_objects('_links').size
  sub_count = network.row_objects('hw_subcatchment').size
  pump_count = network.row_objects('hw_pump').size rescue 0
  
  # Total loadings
  total_loading = 0.0
  network.row_objects('_nodes').each do |node|
    (1..10).each do |i|
      total_loading += node.send("user_number_#{i}").to_f rescue 0.0
    end
  end
  
  puts ""
  puts "="*70
  puts " Import Summary"
  puts "="*70
  puts " Nodes:          #{node_count}"
  puts " Links:          #{link_count}"
  puts " Subcatchments:  #{sub_count}"
  puts " Pumps:          #{pump_count}"
  puts " Total Loading:  #{sprintf('%.2f', total_loading)}"
  puts "="*70
end

# ============================================================================
# Run the main method, catch any errors
# ============================================================================
begin
  start_time = Time.now
  completed = main()
  
  # Only print runtime if import completed (not cancelled)
  if completed
    end_time = Time.now
    runtime = end_time - start_time
    puts ""
    puts "Runtime: #{sprintf('%.2f', runtime)} seconds"
  end
rescue => err
  puts ""
  puts "="*70
  puts " ERROR"
  puts "="*70
  puts err.message
  puts ""
  puts "Stack trace:"
  puts err.backtrace.join("\n")
  puts "="*70
end

