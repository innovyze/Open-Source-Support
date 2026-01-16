# Scenario-specific data import functions
# Imports MHHYD, PIPEHYD, PUMPHYD, WWELLHYD data per scenario

# Read SCENARIO.DBF and build scenario metadata
#
# @param iedb_path [String] path to the IEDB folder
# @return [Hash] scenario data with parent relationships and folder sets

def read_scenario_metadata(iedb_path)
  scenario_dbf_path = File.join(iedb_path, "SCENARIO.DBF")
  
  unless File.exist?(scenario_dbf_path)
    puts "  Warning: Scenario data not found - cannot import scenario data"
    return {}
  end
  
  scenario_data = {}
  
  begin
    rows = read_dbf(scenario_dbf_path, false)
    rows.each do |row|
      scenario_id = row["ID"]
      scenario_data[scenario_id] = {
        "ID" => scenario_id,
        "PARENT" => row["PARENT"].to_s.strip,
        "MH_SET" => row["MH_SET"].to_s.strip,
        "PIPE_SET" => row["PIPE_SET"].to_s.strip,
        "PUMP_SET" => row["PUMP_SET"].to_s.strip,
        "WELL_SET" => row["WELL_SET"].to_s.strip,
        "CTRL_SET" => row["CTRL_SET"].to_s.strip,
        "FAC_TYPE" => row["FAC_TYPE"].to_i  # Facility type: 0=Active Network, 1=Entire Network, 2=Query Set, etc.
      }
    end
  rescue => err
    puts "  Warning: Error reading scenario data: #{err.message}"
    return {}
  end
  
  return scenario_data
end

# Resolve which data set to use for a scenario (with parent inheritance)
#
# @param scenario_id [String] the scenario ID
# @param set_type [String] the type of set (MH_SET, PIPE_SET, etc.)
# @param scenario_data [Hash] scenario metadata
# @return [String] the resolved set name

def resolve_data_set(scenario_id, set_type, scenario_data)
  current_scenario = scenario_data[scenario_id]
  return "BASE" unless current_scenario
  
  set_value = current_scenario[set_type].to_s.strip
  parent_scenario = current_scenario["PARENT"].to_s.strip
  
  # Traverse up the parent chain if set is blank
  while set_value.empty? && !parent_scenario.empty?
    parent_data = scenario_data[parent_scenario]
    break unless parent_data
    
    set_value = parent_data[set_type].to_s.strip
    parent_scenario = parent_data["PARENT"].to_s.strip
  end
  
  set_value = "BASE" if set_value.empty?
  return set_value
end

# Import MHHYD data for a scenario (manhole loads and patterns)
#
# @param network [WSOpenNetwork] the network
# @param scenario_id [String] the scenario ID
# @param iedb_path [String] path to the IEDB folder
# @param mh_set [String] the manhole set name
# @return [Boolean] success

def import_scenario_mhhyd(network, scenario_id, iedb_path, mh_set)
  dbf_path = File.join(iedb_path, "Manhole", mh_set, "MHHYD.DBF")
  
  # If scenario folder doesn't exist, fall back to root IEDB folder
  unless File.exist?(dbf_path)
    dbf_path = File.join(iedb_path, "MHHYD.DBF")
    unless File.exist?(dbf_path)
      return false
    end
  end
  
  # Read MHHYD data
  mhhyd_data = {}
  begin
    rows = read_dbf(dbf_path, false)
    rows.each do |row|
      node_id = row["ID"]
      next if node_id.nil? || node_id.to_s.strip.empty?
      # For nodes, match by original ID (no downcase)
      mhhyd_data[node_id] = {
        "RIM_ELEV" => row["RIM_ELEV"],
        "DIAMETER" => row["DIAMETER"],
        "LOAD1" => row["LOAD1"],
        "LOAD2" => row["LOAD2"],
        "LOAD3" => row["LOAD3"],
        "LOAD4" => row["LOAD4"],
        "LOAD5" => row["LOAD5"],
        "LOAD6" => row["LOAD6"],
        "LOAD7" => row["LOAD7"],
        "LOAD8" => row["LOAD8"],
        "LOAD9" => row["LOAD9"],
        "LOAD10" => row["LOAD10"],
        "PATTERN1" => row["PATTERN1"],
        "PATTERN2" => row["PATTERN2"],
        "PATTERN3" => row["PATTERN3"],
        "PATTERN4" => row["PATTERN4"],
        "PATTERN5" => row["PATTERN5"],
        "PATTERN6" => row["PATTERN6"],
        "PATTERN7" => row["PATTERN7"],
        "PATTERN8" => row["PATTERN8"],
        "PATTERN9" => row["PATTERN9"],
        "PATTERN10" => row["PATTERN10"]
      }
    end
  rescue => err
    puts "    Warning: Error reading MHHYD for #{scenario_id}: #{err.message}"
    return false
  end
  
  # Update nodes (manholes/outlets) with ground_level
  nodes_updated = 0
  network.row_objects('hw_node').each do |node|
    begin
      node_id = node.node_id
      next if node_id.nil?
      
      data = mhhyd_data[node_id]
      next unless data
      
      node.ground_level = data["RIM_ELEV"]
      
      node.write
      nodes_updated += 1
    rescue => e
      # Skip invalid objects (e.g., objects that were deleted or are invalid in this scenario)
      next
    end
  end
  
  # Update subcatchments
  subcatchments_updated = 0
  
  network.row_objects('hw_subcatchment').each do |subcatchment|
    begin
      node_id = subcatchment.node_id
      next if node_id.nil?
      
      data = mhhyd_data[node_id]
      next unless data
      
      (1..10).each do |i|
        load_value = data["LOAD#{i}"]
        pattern_value = data["PATTERN#{i}"]
        subcatchment.send("user_number_#{i}=", load_value)
        subcatchment.send("user_text_#{i}=", pattern_value)
      end
      
      subcatchment.write
      subcatchments_updated += 1
    rescue => e
      # Skip invalid objects (e.g., objects that were deleted or are invalid in this scenario)
      next
    end
  end
  
  return (nodes_updated > 0 || subcatchments_updated > 0)
end

# Import PIPEHYD data for a scenario (pipe hydraulics)
#
# @param network [WSOpenNetwork] the network
# @param scenario_id [String] the scenario ID
# @param iedb_path [String] path to the IEDB folder
# @param pipe_set [String] the pipe set name
# @return [Boolean] success

def import_scenario_pipehyd(network, scenario_id, iedb_path, pipe_set)
  dbf_path = File.join(iedb_path, "Pipe", pipe_set, "PIPEHYD.DBF")
  
  # If scenario folder doesn't exist, fall back to root IEDB folder
  unless File.exist?(dbf_path)
    dbf_path = File.join(iedb_path, "PIPEHYD.DBF")
    unless File.exist?(dbf_path)
      return false
    end
  end
  
  # Read PIPEHYD data
  pipehyd_data = {}
  begin
    rows = read_dbf(dbf_path, false)
    rows.each do |row|
      link_id = row["ID"]
      next if link_id.nil? || link_id.strip.empty?
      pipehyd_data[link_id.strip.downcase] = {
        "FROM_INV" => row["FROM_INV"],
        "TO_INV" => row["TO_INV"],
        "LENGTH" => row["LENGTH"],
        "DIAMETER" => row["DIAMETER"],
        "COEFF" => row["COEFF"],
        "PARALLEL" => row["PARALLEL"]
      }
    end
  rescue => err
    puts "    Warning: Error reading PIPEHYD for #{scenario_id}: #{err.message}"
    return false
  end
  
  # Update conduits
  updated_count = 0
  
  network.row_objects('hw_conduit').each do |conduit|
    begin
      next if conduit.asset_id.nil?
      
      data = pipehyd_data[conduit.asset_id.strip.downcase]
      next unless data
      
      conduit.us_invert = data["FROM_INV"]
      conduit.ds_invert = data["TO_INV"]
      conduit.conduit_length = data["LENGTH"]
      conduit.conduit_height = data["DIAMETER"]
      conduit.conduit_width = data["DIAMETER"]
      conduit.bottom_roughness_N = data["COEFF"]
      conduit.top_roughness_N = data["COEFF"]
      conduit.bottom_roughness_HW = data["COEFF"]
      conduit.top_roughness_HW = data["COEFF"]
      conduit.number_of_barrels = data["PARALLEL"].to_i.zero? ? 1 : data["PARALLEL"].to_i
      
      conduit.write
      updated_count += 1
    rescue => e
      # Skip invalid objects (e.g., objects that were converted to pumps or are invalid in this scenario)
      next
    end
  end
  
  return updated_count > 0
end

# Import PUMPHYD data for a scenario (pump curve data)
#
# @param network [WSOpenNetwork] the network
# @param scenario_id [String] the scenario ID
# @param iedb_path [String] path to the IEDB folder
# @param pump_set [String] the pump set name
# @return [Boolean] success

def import_scenario_pumphyd(network, scenario_id, iedb_path, pump_set)
  dbf_path = File.join(iedb_path, "Pump", pump_set, "PUMPHYD.DBF")
  
  # If scenario folder doesn't exist, fall back to root IEDB folder
  unless File.exist?(dbf_path)
    dbf_path = File.join(iedb_path, "PUMPHYD.DBF")
    unless File.exist?(dbf_path)
      return false
    end
  end
  
  # Read PUMPHYD data
  pumphyd_data = {}
  begin
    rows = read_dbf(dbf_path, false)
    rows.each do |row|
      pump_id = row["ID"]
      next if pump_id.nil? || pump_id.strip.empty?
      pumphyd_data[pump_id.strip.downcase] = {
        "CAPACITY" => row["CAPACITY"],
        "SHUT_HEAD" => row["SHUT_HEAD"],
        "DSGN_HEAD" => row["DSGN_HEAD"],
        "DSGN_FLOW" => row["DSGN_FLOW"],
        "HIGH_HEAD" => row["HIGH_HEAD"],
        "HIGH_FLOW" => row["HIGH_FLOW"]
      }
    end
  rescue => err
    puts "    Warning: Error reading PUMPHYD for #{scenario_id}: #{err.message}"
    return false
  end
  
  # Update pumps
  updated_count = 0
  
  network.row_objects('hw_pump').each do |pump|
    begin
      next if pump.asset_id.nil?
      data = pumphyd_data[pump.asset_id.strip.downcase]
      next unless data
      
      pump.discharge = data["CAPACITY"]
      pump.user_number_1 = data["CAPACITY"]
      pump.user_number_2 = data["SHUT_HEAD"]
      pump.user_number_3 = data["DSGN_HEAD"]
      pump.user_number_4 = data["DSGN_FLOW"]
      pump.user_number_5 = data["HIGH_HEAD"]
      pump.user_number_6 = data["HIGH_FLOW"]
      
      pump.write
      updated_count += 1
    rescue => e
      # Skip invalid objects (e.g., objects that are invalid in this scenario)
      next
    end
  end
  
  return updated_count > 0
end

# Import WWELLHYD data for a scenario (wetwell hydraulics)
#
# @param network [WSOpenNetwork] the network
# @param scenario_id [String] the scenario ID
# @param iedb_path [String] path to the IEDB folder
# @param well_set [String] the wetwell set name
# @return [Boolean] success

def import_scenario_wwellhyd(network, scenario_id, iedb_path, well_set)
  dbf_path = File.join(iedb_path, "Wetwell", well_set, "WWELLHYD.DBF")
  
  # If scenario folder doesn't exist, fall back to root IEDB folder
  unless File.exist?(dbf_path)
    dbf_path = File.join(iedb_path, "WWELLHYD.DBF")
    unless File.exist?(dbf_path)
      return false
    end
  end
  
  # Read WWELLHYD data
  wwellhyd_data = {}
  begin
    rows = read_dbf(dbf_path, false)
    rows.each do |row|
      node_id = row["ID"]
      next if node_id.nil? || node_id.to_s.strip.empty?
      # For nodes, match by original ID (no downcase)
      wwellhyd_data[node_id] = {
        "BTM_ELEV" => row["BTM_ELEV"],
        "MIN_LEVEL" => row["MIN_LEVEL"],
        "MAX_LEVEL" => row["MAX_LEVEL"],
        "INIT_LEVEL" => row["INIT_LEVEL"],
        "DIAMETER" => row["DIAMETER"]
      }
    end
  rescue => err
    puts "    Warning: Error reading WWELLHYD for #{scenario_id}: #{err.message}"
    return false
  end
  
  # Update wetwell nodes
  updated_count = 0
  network.row_objects('hw_node').each do |node|
    begin
      next unless node.user_text_10 && node.user_text_10.to_s == 'WetWell'
      next if node.node_id.nil?
      
      data = wwellhyd_data[node.node_id]
      next unless data
      
      node.chamber_floor = data["BTM_ELEV"]
      node.ground_level = data["MAX_LEVEL"].to_f + data["BTM_ELEV"].to_f
      node.shaft_area = data["DIAMETER"].to_f * data["DIAMETER"].to_f * 3.14159 / 4
      node.chamber_area = data["DIAMETER"].to_f * data["DIAMETER"].to_f * 3.14159 / 4
      
      node.user_number_1 = data["DIAMETER"]
      node.user_number_2 = data["BTM_ELEV"]
      node.user_number_3 = data["MIN_LEVEL"]
      node.user_number_4 = data["MAX_LEVEL"]
      node.user_number_5 = data["INIT_LEVEL"]
      
      node.write
      updated_count += 1
    rescue => e
      # Skip invalid objects (e.g., objects that are invalid in this scenario)
      next
    end
  end
  
  return updated_count > 0
end

# Import CONTROL data for a scenario (pump control levels)
#
# @param network [WSOpenNetwork] the network
# @param scenario_id [String] the scenario ID
# @param iedb_path [String] path to the IEDB folder
# @param control_set [String] the control set name
# @return [Boolean] success

def import_scenario_control(network, scenario_id, iedb_path, control_set)
  dbf_path = File.join(iedb_path, "Control", control_set, "CONTROL.DBF")
  
  # If scenario folder doesn't exist, fall back to root IEDB folder
  unless File.exist?(dbf_path)
    dbf_path = File.join(iedb_path, "CONTROL.DBF")
    unless File.exist?(dbf_path)
      return false
    end
  end
  
  # Read CONTROL data
  control_data = {}
  begin
    rows = read_dbf(dbf_path, false)
    rows.each do |row|
      pump_id = row["ID"]
      next if pump_id.nil? || pump_id.strip.empty?
      control_data[pump_id.strip.downcase] = {
        "ON" => row["ON"],
        "OFF" => row["OFF"]
      }
    end
  rescue => err
    puts "    Warning: Error reading CONTROL for #{scenario_id}: #{err.message}"
    return false
  end
  
  # Update pumps
  updated_count = 0
  
  network.row_objects('hw_pump').each do |pump|
    begin
      next if pump.asset_id.nil?
      
      # Get wetwell chamber_floor from upstream node
      us_node = pump.us_node
      next unless us_node
      chamber_floor = us_node.chamber_floor || 0
      
      # Check if control data exists for this pump
      data = control_data[pump.asset_id.strip.downcase]
      
      if data && (data["ON"] || data["OFF"])
        # Use CONTROL.DBF data
        on_level = data["ON"].to_f
        off_level = data["OFF"].to_f
      elsif pump.user_text_1 == '0'
        # TYPE = 0 (Constant/Fixed Capacity) with no control data
        # Set defaults: OFF = 1 ft above chamber floor, ON = 3 ft above chamber floor
        on_level = 3.0
        off_level = 1.0
      else
        # Skip pumps without control data and not TYPE=0
        next
      end
      
      # Convert relative levels to absolute elevations
      pump.switch_on_level = on_level + chamber_floor
      pump.switch_off_level = off_level + chamber_floor
      
      pump.write
      updated_count += 1
    rescue => e
      # Skip invalid objects
      next
    end
  end
  
  return updated_count > 0
end

# SQL cleanup for scenario-specific assumptions and data corrections
# Only run for non-BASE scenarios
#
# @param network [WSOpenNetwork] the network
# @param scenario_name [String] the scenario name

def sql_cleanup_scenario_assumptions(network, scenario_name)
  # Flag and fix pipes longer than ICM's maximum length (~16404 ft)
  # ICM has a hard limit on conduit length
  begin
    network.run_SQL("_links", "
      SET conduit_length = 16404.0
      WHERE conduit_length > 16404.0;
    ")
  rescue => err
    # No pipes over limit, which is fine
  end
  
rescue => err
  puts "    Note: Scenario cleanup warnings: #{err.message}"
end

# Import all scenario-specific data for selected scenarios
#
# @param network [WSOpenNetwork] the network
# @param selected_scenarios [Array] list of scenario names to import data for
# @param iedb_path [String] path to the IEDB folder

def import_all_scenario_data(network, selected_scenarios, iedb_path)
  puts ""
  puts "Importing scenario-specific data..."
  
  # Read scenario metadata
  scenario_data = read_scenario_metadata(iedb_path)
  
  if scenario_data.empty?
    puts "  No scenario metadata found - skipping scenario data import"
    return
  end
  
  puts "  Read #{scenario_data.size} scenario(s)"
  
  # Import data for each selected scenario
  selected_scenarios.each do |scenario_name|
    # Handle BASE/Base naming:
    # - InfoSewer uses "BASE"
    # - ICM uses "Base"
    scenario_id = scenario_name  # For data lookups (e.g., "BASE")
    icm_scenario_name = (scenario_name.upcase == 'BASE') ? 'Base' : scenario_name  # For ICM (e.g., "Base")
    
    puts "  Scenario: #{icm_scenario_name}"
    
    # Resolve which data sets to use
    mh_set = resolve_data_set(scenario_id, "MH_SET", scenario_data)
    pipe_set = resolve_data_set(scenario_id, "PIPE_SET", scenario_data)
    pump_set = resolve_data_set(scenario_id, "PUMP_SET", scenario_data)
    well_set = resolve_data_set(scenario_id, "WELL_SET", scenario_data)
    control_set = resolve_data_set(scenario_id, "CTRL_SET", scenario_data)
    
    # Switch to this scenario (using ICM name)
    network.current_scenario = icm_scenario_name
    
    network.transaction_begin
    
    # Import each data type
    imported_any = false
    
    if import_scenario_mhhyd(network, scenario_id, iedb_path, mh_set)
      puts "    [OK] MHHYD (set: #{mh_set})"
      imported_any = true
    end
    
    if import_scenario_pipehyd(network, scenario_id, iedb_path, pipe_set)
      puts "    [OK] PIPEHYD (set: #{pipe_set})"
      imported_any = true
    end
    
    if import_scenario_pumphyd(network, scenario_id, iedb_path, pump_set)
      puts "    [OK] PUMPHYD (set: #{pump_set})"
      imported_any = true
    end
    
    if import_scenario_wwellhyd(network, scenario_id, iedb_path, well_set)
      puts "    [OK] WWELLHYD (set: #{well_set})"
      imported_any = true
    end
    
    # Import pump control levels AFTER wetwell data (needs updated chamber_floor)
    if import_scenario_control(network, scenario_id, iedb_path, control_set)
      puts "    [OK] CONTROL (set: #{control_set})"
      imported_any = true
    end
    
    # Run scenario-specific cleanup (only for non-BASE scenarios)
    unless icm_scenario_name == 'Base'
      sql_cleanup_scenario_assumptions(network, icm_scenario_name)
    end
    
    unless imported_any
      puts "    (No data files found)"
    end
    
    network.transaction_commit
  end
  
  # Return to Base scenario
  network.current_scenario = "Base"
  
  puts "Scenario data import complete"
end

