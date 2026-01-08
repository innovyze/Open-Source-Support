# Import InfoSewer selection sets as ICM selection lists
# Reads SELSET.DBF and creates ICM selection lists from SS/{SET_NAME}/ANODE.DBF and ALINK.DBF
#
# @param network [WSOpenNetwork] the network
# @param iedb_path [String] path to the .IEDB folder
# @param parent_object [WSModelObject] the parent Model Group for creating selection lists

def import_selection_sets(network, iedb_path, parent_object)
  puts ""
  puts "Importing InfoSewer selection sets..."
  
  # Path to SELSET file
  selset_path = File.join(iedb_path, "SELSET.DBF")
  
  unless File.exist?(selset_path)
    puts "  No selection sets found - skipping"
    return
  end
  
  # Read selection set definitions
  selection_sets = []
  begin
    rows = read_dbf(selset_path, false)
    rows.each do |row|
      set_id = row["ID"]
      next if set_id.nil? || set_id.to_s.strip.empty?
      
      selection_sets << {
        id: set_id.strip,
        description: row["DESCRIPT"] || ""
      }
    end
  rescue => err
    puts "  Warning: Could not read selection sets: #{err.message}"
    return
  end
  
  if selection_sets.empty?
    puts "  No selection sets defined"
    return
  end
  
  puts "  Found #{selection_sets.size} selection set(s)"
  
  # Build asset_id to ICM link ID mapping
  # InfoSewer ALINK.DBF stores asset IDs, but ICM uses compound IDs (us_node_id.link_suffix)
  asset_to_link_id = {}
  network.row_objects('_links').each do |link|
    next if link.asset_id.nil?
    asset_to_link_id[link.asset_id] = link.id  # link.id is the compound format
  end
  
  # Build node_id lookup
  id_to_node = {}
  network.row_objects('_nodes').each do |node|
    next if node.node_id.nil?
    id_to_node[node.node_id] = node
  end
  
  # Build link_id lookup (using compound ID)
  id_to_link = {}
  network.row_objects('_links').each do |link|
    id_to_link[link.id] = link
  end
  
  # Build subcatchment lookup
  id_to_subcatchment = {}
  network.row_objects('_subcatchments').each do |sub|
    next if sub.subcatchment_id.nil?
    id_to_subcatchment[sub.subcatchment_id] = sub
  end
  
  created_count = 0
  
  # Process each selection set
  selection_sets.each do |set_info|
    set_name = set_info[:id]
    set_folder = File.join(iedb_path, "SS", set_name)
    
    # Check if the selection set folder exists
    unless Dir.exist?(set_folder)
      puts "  Warning: Folder not found for selection set '#{set_name}' - skipping"
      next
    end
    
    # Clear current selection
    network.clear_selection
    
    nodes_selected = 0
    links_selected = 0
    subcatchments_selected = 0
    
    # Process ANODE file (nodes)
    anode_path = File.join(set_folder, "ANODE.DBF")
    if File.exist?(anode_path)
      begin
        anode_rows = read_dbf(anode_path, false)
        anode_rows.each do |row|
          node_id = row["ID"]
          next if node_id.nil? || node_id.to_s.strip.empty?
          
          node_id = node_id.strip
          
          # Select the node
          if node = id_to_node[node_id]
            node.selected = true
            node.write
            nodes_selected += 1
          end
          
          # Also select the subcatchment if it exists with same ID
          if sub = id_to_subcatchment[node_id]
            sub.selected = true
            sub.write
            subcatchments_selected += 1
          end
        end
      rescue => err
        puts "  Warning: Error reading node data for '#{set_name}': #{err.message}"
      end
    end
    
    # Process ALINK file (links using asset IDs)
    alink_path = File.join(set_folder, "ALINK.DBF")
    if File.exist?(alink_path)
      begin
        alink_rows = read_dbf(alink_path, false)
        alink_rows.each do |row|
          asset_id = row["ID"]
          next if asset_id.nil? || asset_id.to_s.strip.empty?
          
          asset_id = asset_id.strip
          
          # Map InfoSewer asset_id to ICM compound link ID
          if link_id = asset_to_link_id[asset_id]
            if link = id_to_link[link_id]
              link.selected = true
              link.write
              links_selected += 1
            end
          end
        end
      rescue => err
        puts "  Warning: Error reading link data for '#{set_name}': #{err.message}"
      end
    end
    
    # Create the selection list if any elements were selected
    if nodes_selected > 0 || links_selected > 0 || subcatchments_selected > 0
      begin
        # Create the selection list with SS_ prefix
        list_name = "SS_#{set_name}"
        selection_list = parent_object.new_model_object('Selection List', list_name)
        network.save_selection(selection_list)
        
        puts "  [OK] #{list_name} (#{nodes_selected} nodes, #{links_selected} links, #{subcatchments_selected} subcatchments)"
        created_count += 1
      rescue => err
        # Check if this is a duplicate name error
        if err.message.include?("already") || err.message.include?("exist") || err.message.include?("duplicate")
          puts "  Skipped: #{list_name} (selection list already exists in database)"
        else
          puts "  Warning: Could not create selection list '#{list_name}': #{err.message}"
        end
      end
    else
      puts "  Warning: No elements found for selection set '#{set_name}' - skipping"
    end
    
    # Clear selection for next set
    network.clear_selection
  end
  
  # Clear final selection
  network.clear_selection
  
  puts "Selection set import complete (#{created_count} list(s) created)"
end

