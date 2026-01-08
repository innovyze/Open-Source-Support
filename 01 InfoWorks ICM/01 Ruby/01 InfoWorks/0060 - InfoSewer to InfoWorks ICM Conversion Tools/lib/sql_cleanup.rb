# Post-import SQL cleanup operations
# These are based on the SQL scripts from the 0060 InfoSewer conversion tools
# Adapted to work with the new Ruby-based import workflow

# Run all cleanup operations after importing the BASE scenario
#
# @param network [WSOpenNetwork] the network to clean up

def run_all_cleanup_sql(network)
  puts ""
  puts "Running post-import cleanup..."
  
  # Operations that can be done in a single transaction
  network.transaction_begin
  
  sql_set_outfall_types(network)
  sql_create_subcatchments(network)
  sql_set_number_of_barrels(network)
  sql_resolve_conduit_lengths(network)
  sql_assign_r_values(network)
  
  network.transaction_commit
  puts "  [OK] Basic cleanup complete"
  
  # Pump operations (need to be done outside transaction due to table changes)
  begin
    sql_find_and_convert_pumps(network)
    puts "  [OK] Pumps converted"
  rescue => err
    # No pumps in model
  end
  
  # Operations on pumps (must be after pump conversion)
  network.transaction_begin
  
  sql_set_pump_downstream_nodes(network)
  sql_set_forcemain_nodes_to_break(network)
  sql_calculate_wetwell_areas(network)
  sql_insert_pump_curves(network)
  
  network.transaction_commit
  puts "  [OK] Pump configuration complete"
end

# Set node_type to 'Outfall' for nodes marked as outfalls in InfoSewer
#
# @param network [WSOpenNetwork] the network

def sql_set_outfall_types(network)
  network.run_SQL("_nodes", "
    SET node_type = 'Outfall' WHERE user_text_2 = '2';
    SET user_text_10 = 'Outfall' WHERE user_text_2 = '2';
  ")
end

# Create subcatchments for all manholes
#
# @param network [WSOpenNetwork] the network

def sql_create_subcatchments(network)
  network.run_SQL("_nodes", "
    INSERT INTO subcatchment (subcatchment_id, node_id, total_area, x, y, connectivity, system_type)
    SELECT node_id, node_id, 0.10, x, y, 100, 'sanitary' WHERE user_text_10 = 'Manhole';
  ")
end

# Set number_of_barrels to 1 where it's 0 (InfoSewer default)
#
# @param network [WSOpenNetwork] the network

def sql_set_number_of_barrels(network)
  network.run_SQL("_links", "
    SET number_of_barrels = 1 WHERE number_of_barrels = 0;
  ")
end

# Resolve conduit lengths - set minimum to 3.3 ft for ICM
# ICM requires conduit_length >= 3.3 ft (1 meter)
# Also set maximum to 16404 ft (5000 meters) - ICM limit
#
# @param network [WSOpenNetwork] the network

def sql_resolve_conduit_lengths(network)
  begin
    # Count how many conduits need fixing BEFORE
    # Only check hw_conduit (pipes/force mains), not pumps or other link types
    short_count = 0
    long_count = 0
    network.row_objects('hw_conduit').each do |link|
      len = link.conduit_length
      short_count += 1 if len.nil? || len < 3.3
      long_count += 1 if !len.nil? && len > 16404
    end
    
    if short_count > 0 || long_count > 0
      # Fix short, long, and NULL/0 conduits
      # ICM requires: 3.3 ft (1m) <= conduit_length <= 16404 ft (5000m)
      network.run_SQL("hw_conduit", "
        SET conduit_length = 3.3 WHERE conduit_length IS NULL OR conduit_length < 3.3;
        SET conduit_length = 16404 WHERE conduit_length > 16404;
      ")
      
      # Verify the fix worked
      still_short = 0
      network.row_objects('hw_conduit').each do |link|
        len = link.conduit_length
        still_short += 1 if len.nil? || len < 3.3
      end
      
      if still_short > 0
        puts "    WARNING: #{still_short}/#{short_count} conduits still < 3.3 ft after SQL fix!"
      else
        puts "    Fixed #{short_count} short conduit(s) to 3.3 ft minimum" if short_count > 0
        puts "    Fixed #{long_count} long conduit(s) to 16404 ft maximum" if long_count > 0
      end
    end
  rescue => err
    puts "  WARNING: Could not resolve conduit lengths: #{err.message}"
    puts "    #{err.backtrace[0]}"
  end
end

# Calculate R values for RDII hydrographs from InfoSewer percentages
#
# @param network [WSOpenNetwork] the network

def sql_assign_r_values(network)
  network.run_SQL("RTK hydrograph", "
    SET R1 = (user_number_2/100.0)*(user_number_1/100.0),
        R2 = (user_number_3/100.0)*(user_number_1/100.0),
        R3 = ((100.0 - user_number_2 - user_number_3)/100.0)*(user_number_1/100.0);
  ")
rescue => err
  # RTK hydrograph table might not exist if no RDII data
  puts "  Note: Could not set R values (no RDII data?)"
end

# Find conduits marked as pumps and convert them to pump objects
# This is a complex operation that changes object types
#
# @param network [WSOpenNetwork] the network

def sql_find_and_convert_pumps(network)
  network.run_SQL("_links", "
    LIST \$asset_id String;
    SELECT DISTINCT asset_id INTO \$asset_id WHERE user_text_10 = 'Pump';
    LET \$i = 1;
    WHILE \$i <= LEN(\$asset_id);
      SELECT us_node_id INTO \$us_node_id WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT ds_node_id INTO \$ds_node_id WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT link_suffix INTO \$link_suffix WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT discharge INTO \$discharge WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT switch_on_level INTO \$switch_on WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT switch_off_level INTO \$switch_off WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_number_1 INTO \$un1 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_number_2 INTO \$un2 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_number_3 INTO \$un3 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_number_4 INTO \$un4 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_number_5 INTO \$un5 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_number_6 INTO \$un6 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_text_1 INTO \$ut1 WHERE asset_id = AREF(\$i, \$asset_id);
      SELECT user_text_2 INTO \$ut2 WHERE asset_id = AREF(\$i, \$asset_id);
      DELETE WHERE asset_id = AREF(\$i, \$asset_id);
      INSERT INTO Pump (us_node_id, ds_node_id, link_suffix, asset_id, discharge, switch_on_level, switch_off_level, user_number_1, user_number_2, user_number_3, user_number_4, user_number_5, user_number_6, user_text_1, user_text_2)
      VALUES(\$us_node_id, \$ds_node_id, \$link_suffix, AREF(\$i, \$asset_id), \$discharge, \$switch_on, \$switch_off, \$un1, \$un2, \$un3, \$un4, \$un5, \$un6, \$ut1, \$ut2);
      LET \$i = \$i + 1;
    WEND;
  ")
rescue => err
  puts "  Warning: Error converting pumps: #{err.message}"
end

# Set downstream nodes of pumps to 'Break' type
# This ensures proper hydraulic connectivity
#
# @param network [WSOpenNetwork] the network

def sql_set_pump_downstream_nodes(network)
  network.run_SQL("Pump", "
    SET ds_node.node_type = 'Break' WHERE (link_type = 'FIXPMP' OR link_type = 'ROTPMP');
  ")
rescue => err
  puts "  Note: Could not set pump downstream nodes: #{err.message}"
end

# Set all nodes along forcemains to 'Break' type
# Forcemains are pressurized pipes, so all nodes on them should be break nodes
#
# @param network [WSOpenNetwork] the network

def sql_set_forcemain_nodes_to_break(network)
  # Set any node that has a forcemain as a downstream link to Break
  network.run_SQL("hw_node", "
    SET node_type = 'Break' WHERE ds_links.solution_model = 'Forcemain';
  ")
rescue => err
  puts "  Note: Could not set forcemain nodes: #{err.message}"
end

# Calculate wet well chamber and shaft areas from diameters
# NOTE: This assumes wetwells use a fixed diameter. If your InfoSewer model
# uses wetwell CURVES instead of diameters, the chamber_area and shaft_area
# will not be calculated correctly. You'll need to manually set these.
#
# @param network [WSOpenNetwork] the network

def sql_calculate_wetwell_areas(network)
  network.run_SQL("_nodes", "
    SET chamber_area = 3.14159 * (chamber_area/2.0) * (chamber_area/2.0) WHERE user_text_10 = 'WetWell';
    SET shaft_area = 3.14159 * (shaft_area/2.0) * (shaft_area/2.0) WHERE user_text_10 = 'WetWell';
    SET ground_level = ground_level + chamber_floor WHERE user_text_10 = 'WetWell';
  ")
rescue => err
  puts "  Note: Could not calculate wetwell areas: #{err.message}"
end

# Count wetwells in the network
# Returns the count so the UI script can display the notice
#
# @param network [WSOpenNetwork] the network
# @return [Integer] number of wetwells found

def count_wetwells(network)
  wetwell_count = 0
  network.row_objects('hw_node').each do |node|
    if node.user_text_10 && node.user_text_10.to_s == 'WetWell'
      wetwell_count += 1
    end
  end
  return wetwell_count
rescue => err
  return 0
end

# Insert pump curves based on InfoSewer pump types
# Type 1 = Design point pump (1-point curve expanded to 3 points)
# Type 2 = 3-point exponential pump curve
#
# @param network [WSOpenNetwork] the network

def sql_insert_pump_curves(network)
  network.run_SQL("Pump", "
    SET link_type = 'ROTPMP' WHERE user_text_1 = '1' OR user_text_1 = '2';
    SELECT WHERE link_type = 'ROTPMP';
    INSERT INTO [Head Discharge] (head_discharge_id) SELECT SELECTED asset_id FROM Pump;
    SET head_discharge_id = asset_id;
    DELETE ALL FROM [Head discharge].HDP_table;
    INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, 1.33 * user_number_3, 0 FROM Pump WHERE user_text_1 = '1';
    INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_3, user_number_4  FROM Pump WHERE user_text_1 = '1';
    INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, 0, 2 * user_number_4  FROM Pump WHERE user_text_1 = '1';
    INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_2, 0 FROM Pump WHERE user_text_1 = '2';
    INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_3, user_number_4  FROM Pump WHERE user_text_1 = '2';
    INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_5, user_number_6  FROM Pump WHERE user_text_1 = '2';
    DESELECT ALL;
  ")
rescue => err
  puts "  Note: Could not insert pump curves: #{err.message}"
end

# Apply additional post-processing using Ruby (for things SQL can't do well)
#
# @param network [WSOpenNetwork] the network

def run_ruby_cleanup(network)
  # This function exists for potential future post-processing
  # Currently all transformations are handled by SQL (matching 0060)
  
  # Count objects for reporting
  network.transaction_begin
  
  node_count = network.row_objects('_nodes').size
  link_count = network.row_objects('hw_conduit').size
  sub_count = network.row_objects('hw_subcatchment').size
  
  pump_count = 0
  begin
    pump_count = network.row_objects('hw_pump').size
  rescue
    # No pumps
  end
  
  network.transaction_commit
  
  puts ""
  puts "Network summary:"
  puts "  Nodes: #{node_count}  |  Links: #{link_count}"
  puts "  Subcatchments: #{sub_count}  |  Pumps: #{pump_count}"
end

