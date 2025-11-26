# Creates selection list for root-level active network (last saved state)
# Based on ANODE.DBF and ALINK.DBF in root IEDB folder
#
# @param open_net [WSOpenNetwork] The opened network
# @param parent_object [Object] Parent model group or model network
# @param iedb_path [String] Path to the IEDB folder
# @return [Integer] 1 if created, 0 otherwise

def create_root_active_network_selection(open_net, parent_object, iedb_path)
  # Build hashes of network objects for quick lookup
  id_to_link = {}
  id_to_node = {}
  id_to_subcatchment = {}
  asset_to_link_id = {}
  
  open_net.row_objects('_links').each do |ro| 
    id_to_link[ro.id] = ro
    asset_to_link_id[ro.asset_id] = ro.us_node_id + '.' + ro.link_suffix if ro.asset_id
  end
  
  open_net.row_objects('_nodes').each do |ro| 
    id_to_node[ro.node_id] = ro
  end
  
  open_net.row_objects('_subcatchments').each do |ro| 
    id_to_subcatchment[ro.subcatchment_id] = ro
  end
  
  # Check for root-level ANODE/ALINK files
  root_anode_file = File.join(iedb_path, 'ANODE.DBF')
  root_alink_file = File.join(iedb_path, 'ALINK.DBF')
  
  unless File.exist?(root_anode_file) || File.exist?(root_alink_file)
    puts ""
    puts "No root ANODE.DBF or ALINK.DBF found - skipping AN_Root creation"
    return 0
  end
  
  puts ""
  puts "Creating selection list for root active network (last saved)..."
  
  # Clear selection before processing
  open_net.clear_selection
  
  # Read and process root ANODE.DBF
  node_count = 0
  anode_total = 0
  if File.exist?(root_anode_file)
    begin
      anode_data = read_dbf(root_anode_file, true)  # hash_by_id = true
      anode_total = anode_data.length
      anode_data.each do |node_id, row|
        # Select the node
        if node = id_to_node[node_id]
          node.selected = true
          node.write
          node_count += 1
        end
        
        # Also select matching subcatchment (if exists)
        if subcatch = id_to_subcatchment[node_id]
          subcatch.selected = true
          subcatch.write
        end
      end
    rescue => e
      puts "  [ERROR] Failed to read root ANODE.DBF - #{e.message}"
    end
  end
  
  # Read and process root ALINK.DBF
  link_count = 0
  alink_total = 0
  if File.exist?(root_alink_file)
    begin
      alink_data = read_dbf(root_alink_file, true)  # hash_by_id = true
      alink_total = alink_data.length
      alink_data.each do |asset_id, row|
        # Convert asset_id to link_id format (us_node_id.link_suffix)
        if link_id = asset_to_link_id[asset_id]
          if link = id_to_link[link_id]
            link.selected = true
            link.write
            link_count += 1
          end
        end
      end
    rescue => e
      puts "  [ERROR] Failed to read root ALINK.DBF - #{e.message}"
    end
  end
  
  # Report what was found
  puts "  Root: ANODE has #{anode_total} records (matched #{node_count}), ALINK has #{alink_total} records (matched #{link_count})"
  
  # Create selection list
  if node_count > 0 || link_count > 0
    selection_name = "AN_Root"
    
    begin
      sl = parent_object.new_model_object('Selection List', selection_name)
      open_net.save_selection(sl)
      puts "  [OK] Created '#{selection_name}' (#{node_count} nodes, #{link_count} links)"
      open_net.clear_selection
      return 1
    rescue => e
      # If selection list already exists, try to update it
      begin
        sl = parent_object.list_model_objects('Selection List').find { |obj| obj.name == selection_name }
        if sl
          open_net.save_selection(sl)
          puts "  [OK] Updated '#{selection_name}' (#{node_count} nodes, #{link_count} links)"
          open_net.clear_selection
          return 1
        else
          puts "  [ERROR] Could not create or update root selection list - #{e.message}"
        end
      rescue => e2
        puts "  [ERROR] Could not create or update root selection list - #{e2.message}"
      end
    end
  else
    puts "  [SKIP] Root active network is empty"
  end
  
  # Clear selection after processing
  open_net.clear_selection
  return 0
end

# Creates selection lists for scenario-specific active networks (FAC_TYPE = 0)
# Based on ANODE.DBF and ALINK.DBF in scenario subfolders
#
# @param open_net [WSOpenNetwork] The opened network
# @param parent_object [Object] Parent model group or model network
# @param scenarios [Hash] Hash of scenario metadata from read_scenario_metadata (keyed by scenario ID)
# @param iedb_path [String] Path to the IEDB folder
# @return [Integer] Number of selection lists created

def create_active_network_selections(open_net, parent_object, scenarios, iedb_path)
  selection_count = 0
  
  # Map FAC_TYPE to human-readable names
  fac_type_names = {
    0 => 'Active Network',
    1 => 'Entire Network',
    2 => 'Query Set',
    3 => 'Intelli-Selection',
    4 => 'Inherited'
  }
  
  # Count scenarios by FAC_TYPE
  fac_type_counts = Hash.new(0)
  scenarios.each { |id, data| fac_type_counts[data['FAC_TYPE']] += 1 }
  
  # Only process scenarios with FAC_TYPE = 0 (Active Network)
  # scenarios is a hash keyed by scenario ID
  active_network_scenarios = scenarios.select { |id, data| data['FAC_TYPE'] == 0 }
  
  # Report facility type summary
  puts ""
  puts "Scenario Facility Types:"
  fac_type_counts.sort.each do |fac_type, count|
    type_name = fac_type_names[fac_type] || "Unknown (#{fac_type})"
    puts "  #{type_name}: #{count} scenario(s)"
  end
  puts ""
  
  # Build hashes of network objects for quick lookup
  id_to_link = {}
  id_to_node = {}
  id_to_subcatchment = {}
  asset_to_link_id = {}
  
  open_net.row_objects('_links').each do |ro| 
    id_to_link[ro.id] = ro
    asset_to_link_id[ro.asset_id] = ro.us_node_id + '.' + ro.link_suffix if ro.asset_id
  end
  
  open_net.row_objects('_nodes').each do |ro| 
    id_to_node[ro.node_id] = ro
  end
  
  open_net.row_objects('_subcatchments').each do |ro| 
    id_to_subcatchment[ro.subcatchment_id] = ro
  end
  
  # Only process scenarios with FAC_TYPE = 0 (Active Network)
  active_network_scenarios = scenarios.select { |id, data| data['FAC_TYPE'] == 0 }
  
  if active_network_scenarios.empty?
    puts ""
    puts "No Active Network scenarios (FAC_TYPE=0)"
    return selection_count
  end
  
  puts ""
  puts "Creating selection lists for Active Network scenarios..."
  
  # Process each Active Network scenario
  active_network_scenarios.each do |scenario_name, scenario|
    
    # Build paths to ANODE and ALINK files
    scenario_folder = File.join(iedb_path, 'Scenario', scenario_name)
    anode_file = File.join(scenario_folder, 'ANODE.DBF')
    alink_file = File.join(scenario_folder, 'ALINK.DBF')
    
    # Check if scenario folder and files exist
    unless Dir.exist?(scenario_folder)
      puts "  [SKIP] #{scenario_name}: Scenario folder not found"
      next
    end
    
    has_anode = File.exist?(anode_file)
    has_alink = File.exist?(alink_file)
    
    unless has_anode || has_alink
      puts "  [SKIP] #{scenario_name}: No ANODE.DBF or ALINK.DBF found"
      next
    end
    
    # Clear selection before processing
    open_net.clear_selection
    
    # Read and process ANODE.DBF (active nodes)
    node_count = 0
    anode_total = 0
    if has_anode
      begin
        anode_data = read_dbf(anode_file, true)  # hash_by_id = true
        anode_total = anode_data.length
        anode_data.each do |node_id, row|
          # Select the node
          if node = id_to_node[node_id]
            node.selected = true
            node.write
            node_count += 1
          end
          
          # Also select matching subcatchment (if exists)
          if subcatch = id_to_subcatchment[node_id]
            subcatch.selected = true
            subcatch.write
          end
        end
      rescue => e
        puts "  [ERROR] #{scenario_name}: Failed to read ANODE.DBF - #{e.message}"
      end
    end
    
    # Read and process ALINK.DBF (active links)
    link_count = 0
    alink_total = 0
    if has_alink
      begin
        alink_data = read_dbf(alink_file, true)  # hash_by_id = true
        alink_total = alink_data.length
        alink_data.each do |asset_id, row|
          # Convert asset_id to link_id format (us_node_id.link_suffix)
          if link_id = asset_to_link_id[asset_id]
            if link = id_to_link[link_id]
              link.selected = true
              link.write
              link_count += 1
            end
          end
        end
      rescue => e
        puts "  [ERROR] #{scenario_name}: Failed to read ALINK.DBF - #{e.message}"
      end
    end
    
    # Report what was found
    puts "  #{scenario_name}: ANODE has #{anode_total} records (matched #{node_count}), ALINK has #{alink_total} records (matched #{link_count})"
    
    # Create selection list with selected elements
    if node_count > 0 || link_count > 0
      selection_name = "AN_#{scenario_name}"
      
      # Try to create the selection list
      begin
        sl = parent_object.new_model_object('Selection List', selection_name)
        open_net.save_selection(sl)
        puts "  [OK] Created '#{selection_name}' (#{node_count} nodes, #{link_count} links)"
        selection_count += 1
      rescue => e
        # If selection list already exists, try to update it
        begin
          sl = parent_object.list_model_objects('Selection List').find { |obj| obj.name == selection_name }
          if sl
            open_net.save_selection(sl)
            puts "  [OK] Updated '#{selection_name}' (#{node_count} nodes, #{link_count} links)"
            selection_count += 1
          else
            puts "  [ERROR] #{scenario_name}: Could not create or update selection list - #{e.message}"
          end
        rescue => e2
          puts "  [ERROR] #{scenario_name}: Could not create or update selection list - #{e2.message}"
        end
      end
    else
      puts "  [SKIP] #{scenario_name}: All BASE elements active (no selection list needed)"
    end
    
    # Clear selection after processing
    open_net.clear_selection
  end
  
  if selection_count > 0
    puts ""
    puts "Created #{selection_count} Active Network selection list(s)"
  elsif active_network_scenarios.any?
    puts ""
    puts "Note: All FAC_TYPE=0 scenarios use full BASE network (no selection lists created)"
  end
  
  return selection_count
end

