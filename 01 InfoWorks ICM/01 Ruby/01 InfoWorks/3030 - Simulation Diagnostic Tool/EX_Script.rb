# Script: Initialization Phase-In Diagnostic Tool
# Context: Exchange
# Purpose: Parse simulation log files for initialization phase-in issues (Message 317/250)
# Outputs: CSV summary + Selection Lists for each phase failure
# Usage: Run from Exchange, enter simulation ID when prompted

require 'csv'
require 'set'

# ============================================================================
# CONFIGURATION
# ============================================================================
# Specify your database path here, or leave as nil to use most recently opened
# Examples:
#   DATABASE_PATH = 'C:/MyDatabases/MyDatabase.icmm'              # Standalone
#   DATABASE_PATH = 'localhost:40000/MyDatabase'                  # Workgroup
#   DATABASE_PATH = 'cloud://mydatabase.4@63f653b1c7cf77/name'    # Cloud
#   DATABASE_PATH = nil                                           # Most recent
DATABASE_PATH = nil
# ============================================================================

begin
  puts "="*80
  puts "Initialization Phase-In Diagnostic Tool"
  puts "="*80
  
  # Step 1: Open database
  if DATABASE_PATH.nil? || DATABASE_PATH.strip.empty?
    puts "\nOpening most recently used database..."
    begin
      db = WSApplication.open
    rescue => e
      puts "\nERROR: Could not open database."
      puts "No database path configured and no recently opened database found."
      puts "Error: #{e.message}"
      puts "\nTo fix: Edit the script and set DATABASE_PATH at the top:"
      puts "  DATABASE_PATH = 'C:/Path/To/Your/Database.icmm'"
      return
    end
  else
    puts "\nOpening database: #{DATABASE_PATH}"
    begin
      db = WSApplication.open(DATABASE_PATH)
    rescue => e
      puts "\nERROR: Could not open database: #{DATABASE_PATH}"
      puts "Error: #{e.message}"
      puts "\nPlease check the database path is correct."
      return
    end
  end
  
  puts "Database opened: #{db.path}"
  
  # Prompt for simulation ID (use command line argument or STDIN)
  sim_id = nil
  
  # Try to read simulation ID from temporary file (set by batch file)
  temp_file = File.join(ENV['TEMP'] || ENV['TMP'] || '/tmp', 'icm_sim_id.txt')
  
  if File.exist?(temp_file)
    sim_id_str = File.read(temp_file).strip
    sim_id = sim_id_str.to_i
    puts "Reading Simulation ID from input: #{sim_id_str}"
  elsif ARGV.length > 0
    # Fallback: simulation ID provided as command line argument
    sim_id = ARGV[0].to_i
    puts "Using command-line argument: #{ARGV[0]}"
  else
    puts "ERROR: No simulation ID provided."
    puts "Please run this script via the batch file."
    return
  end
  
  if sim_id <= 0
    puts "ERROR: Invalid simulation ID '#{sim_id}'. Please enter a valid numeric ID."
    puts "Script terminated."
    return
  end
  
  # Get simulation object
  sim_mo = db.model_object_from_type_and_id('Sim', sim_id)
  
  if sim_mo.nil?
    puts "ERROR: Simulation with ID #{sim_id} not found in database."
    return
  end
  
  puts "\nAnalyzing simulation: #{sim_mo.name} (ID: #{sim_id})"
  
  # Get results path and construct log file path
  results_path = sim_mo.results_path
  
  if results_path.nil? || results_path.empty?
    puts "ERROR: Results path not found for simulation ID #{sim_id}."
    puts "Has this simulation been run?"
    return
  end
  
  # results_path may include the .iwr file, extract directory
  results_dir = File.dirname(results_path)
  log_file_path = File.join(results_dir, "SIM#{sim_id}.log")
  
  unless File.exist?(log_file_path)
    puts "ERROR: Log file not found: #{log_file_path}"
    puts "Expected file: SIM#{sim_id}.log in results folder"
    return
  end
  
  puts "Log file found: #{log_file_path}"
  
  # Step 2: Parse log identifying Message 317/250 blocks
  puts "\nParsing log file..."
  
  lines = File.readlines(log_file_path)
  phases = [] # Array of phase data: {phase_num, timestamp, greatest_change_line, halving_lines}
  phase_counter = 0
  
  lines.each_with_index do |line, idx|
    # Check for Message 317 or Message 250
    if line.match?(/Message 317.*phase in/) || line.match?(/Message 250.*Initialisation failed/)
      phase_counter += 1
      
      # Backtrack to find "Greatest change at" line and halving lines
      # We need to find the block just before Message 261
      greatest_change_line = nil
      timestamp_line = nil
      halving_lines = []
      
      # Look backwards for Message 261 (which should be immediately before 317/250)
      msg_261_idx = idx - 1
      if msg_261_idx >= 0 && lines[msg_261_idx].match?(/Message 261/)
        # Now backtrack from Message 261 to find halving lines and greatest change
        (msg_261_idx-1).downto([msg_261_idx-50, 0].max) do |back_idx|
          current_line = lines[back_idx]
          
          # Collect halving lines
          if current_line.match?(/Halving:/)
            halving_lines.unshift(current_line.strip)
          end
          
          # Find the last "Greatest change at" before halvings
          if current_line.match?(/Greatest change at/)
            greatest_change_line = current_line.strip
            
            # Find the timestep for this greatest change
            (back_idx-1).downto([back_idx-5, 0].max) do |ts_idx|
              if lines[ts_idx].match?(/Timestep:/)
                timestamp_line = lines[ts_idx].strip
                break
              end
            end
            
            break # Found the block we need
          end
        end
      end
      
      phases << {
        phase_num: phase_counter,
        timestamp: timestamp_line ? timestamp_line.strip : "Unknown",
        greatest_change: greatest_change_line ? greatest_change_line.strip : "",
        halving_lines: halving_lines
      }
      
      # Stop at phase 5 (Message 250)
      break if phase_counter >= 5
    end
  end
  
  if phases.empty?
    puts "\n" + "="*80
    puts "No initialisation phase in failures - check passed!"
    puts "="*80
    return
  end
  
  puts "Found #{phases.length} initialization phase failure(s)"
  
  # Step 3: Build network ID lookup and validate extracted IDs
  puts "\nOpening model network and building ID lookup..."
  
  # Get the parent run object to access the model network
  run_id = sim_mo.parent_id
  run_mo = db.model_object_from_type_and_id('Run', run_id)
  net_id = run_mo['Model Network']
  net_mo = db.model_object_from_type_and_id('Model Network', net_id)
  
  begin
    net = net_mo.open
  rescue => e
    puts "\n" + "="*80
    puts "ERROR: Unable to open network"
    puts "="*80
    puts "Network: #{net_mo.name}"
    puts "Reason: #{e.message}"
    puts "\nThis error typically occurs when:"
    puts "  - The network is already open in InfoWorks ICM UI"
    puts "  - The network is being edited by another user"
    puts "  - The database is in use by another process"
    puts "\nPlease close the network in InfoWorks ICM and try again."
    puts "="*80
    return
  end
  
  # Build hash of valid IDs
  valid_ids = {}
  
  net.row_objects('_nodes').each do |node|
    valid_ids[node.id] = 'node'
  end
  
  net.row_objects('_links').each do |link|
    valid_ids[link.id] = 'link'
  end
  
  puts "Network has #{valid_ids.count { |k,v| v == 'node' }} nodes and #{valid_ids.count { |k,v| v == 'link' }} links"
  
  # Process each phase to extract and validate IDs
  phase_data = []
  
  phases.each do |phase|
    puts "\n--- Processing Phase #{phase[:phase_num]} ---"
    
    valid_links = Set.new
    valid_nodes = Set.new
    unmatched_ids = []
    
    # Parse "Greatest change at" line
    # Format: "Greatest change at link ID for depth, ID for flow, and node ID for level."
    gc_line = phase[:greatest_change]
    
    if gc_line && !gc_line.empty?
      # Extract link for depth (between "link " and " for depth")
      depth_match = gc_line.match(/link\s+(.+?)\s+for depth/)
      if depth_match && depth_match[1].strip != '--'
        candidate_id = depth_match[1].strip
        # Strip _BE/_BO from the ID (before any dot if present)
        candidate_id = candidate_id.sub(/_BE(\.|\/|$)/, '\1').sub(/_BO(\.|\/|$)/, '\1')
        
        if valid_ids[candidate_id]
          valid_links.add(candidate_id) if valid_ids[candidate_id] == 'link'
          valid_nodes.add(candidate_id) if valid_ids[candidate_id] == 'node'
        else
          unmatched_ids << candidate_id unless unmatched_ids.include?(candidate_id)
        end
      end
      
      # Extract link for flow (between first "," and " for flow")
      flow_match = gc_line.match(/,\s*(.+?)\s+for flow/)
      if flow_match && flow_match[1].strip != '--'
        candidate_id = flow_match[1].strip
        candidate_id = candidate_id.sub(/_BE(\.|\/|$)/, '\1').sub(/_BO(\.|\/|$)/, '\1')
        
        if valid_ids[candidate_id]
          valid_links.add(candidate_id) if valid_ids[candidate_id] == 'link'
          valid_nodes.add(candidate_id) if valid_ids[candidate_id] == 'node'
        else
          unmatched_ids << candidate_id unless unmatched_ids.include?(candidate_id)
        end
      end
      
      # Extract node for level (between "node " and " for level")
      level_match = gc_line.match(/node\s+(.+?)\s+for level/)
      if level_match && level_match[1].strip != '--'
        candidate_id = level_match[1].strip
        candidate_id = candidate_id.sub(/_BE(\.|\/|$)/, '\1').sub(/_BO(\.|\/|$)/, '\1')
        
        if valid_ids[candidate_id]
          valid_nodes.add(candidate_id) if valid_ids[candidate_id] == 'node'
          valid_links.add(candidate_id) if valid_ids[candidate_id] == 'link'
        else
          unmatched_ids << candidate_id unless unmatched_ids.include?(candidate_id)
        end
      end
    end
    
    # Parse halving lines
    # Format: "Halving: H: ..., Q: ..., N: ID, Reason: ..."
    phase[:halving_lines].each do |halv_line|
      # Extract N: field value (between "N: " and ",")
      node_match = halv_line.match(/N:\s*([^,]+),/)
      if node_match
        candidate_id = node_match[1].strip
        # Skip empty values
        next if candidate_id.empty?
        
        candidate_id = candidate_id.sub(/_BE(\.|\/|$)/, '\1').sub(/_BO(\.|\/|$)/, '\1')
        
        if valid_ids[candidate_id]
          valid_nodes.add(candidate_id) if valid_ids[candidate_id] == 'node'
          valid_links.add(candidate_id) if valid_ids[candidate_id] == 'link'
        else
          unmatched_ids << candidate_id unless unmatched_ids.include?(candidate_id)
        end
      end
    end
    
    puts "  Valid links: #{valid_links.size}"
    puts "  Valid nodes: #{valid_nodes.size}"
    
    if !unmatched_ids.empty?
      puts "  WARNING: #{unmatched_ids.size} unmatched IDs: #{unmatched_ids.join(', ')}"
    end
    
    phase_data << {
      phase_num: phase[:phase_num],
      timestamp: phase[:timestamp],
      valid_links: valid_links.to_a,
      valid_nodes: valid_nodes.to_a,
      unmatched_ids: unmatched_ids
    }
  end
  
  # Step 4: Export summary CSV
  csv_filename = "SIM#{sim_id}_initialization_issues.csv"
  csv_path = File.join(results_dir, csv_filename)
  
  puts "\nExporting CSV summary..."
  
  CSV.open(csv_path, 'w') do |csv|
    csv << ['Sim_ID', 'Phase_Number', 'Timestamp', 'Valid_Links', 'Valid_Nodes', 'Unmatched_IDs']
    
    phase_data.each do |phase|
      csv << [
        sim_id,
        phase[:phase_num],
        phase[:timestamp],
        phase[:valid_links].join('; '),
        phase[:valid_nodes].join('; '),
        phase[:unmatched_ids].join('; ')
      ]
    end
  end
  
  puts "CSV exported: #{csv_path}"
  
  # Step 5: Create versioned selection lists
  phases_with_objects = phase_data.select { |p| !p[:valid_links].empty? || !p[:valid_nodes].empty? }
  
  if phases_with_objects.empty?
    puts "\n" + "="*80
    puts "No valid objects found after validation - selection lists not created"
    puts "="*80
    return
  end
  
  puts "\nCreating selection lists..."
  
  # Find parent Model Group (simulation -> run -> model group)
  run_parent_id = run_mo.parent_id
  parent_group = db.model_object_from_type_and_id('Model Group', run_parent_id)
  
  # Get commit ID for versioning (from run object)
  commit_id = run_mo['Model Network Commit ID']
  
  # Create a new Model Group to organize the selection lists
  # Ensure unique name by appending ! if already exists
  diagnostics_group_name = "Sim#{sim_id} Diagnostics"
  original_group_name = diagnostics_group_name
  
  parent_group.children.each do |child|
    while child.name == diagnostics_group_name
      diagnostics_group_name += '!'
    end
  end
  
  if diagnostics_group_name != original_group_name
    puts "Model Group '#{original_group_name}' already exists, using: #{diagnostics_group_name}"
  end
  
  begin
    diagnostics_group = parent_group.new_model_object('Model Group', diagnostics_group_name)
    puts "Created Model Group: #{diagnostics_group_name}"
    puts "Selection lists will be saved under this group"
  rescue => e
    puts "\n" + "="*80
    puts "ERROR: Unable to create Model Group"
    puts "="*80
    puts "Group name: #{diagnostics_group_name}"
    puts "Reason: #{e.message}"
    puts "\nThis may occur if:"
    puts "  - A group with this name already exists"
    puts "  - You don't have permission to create groups"
    puts "="*80
    return
  end
  
  # Create selection list for each phase under the diagnostics group
  phases_with_objects.each do |phase|
    # Clear selection
    net.clear_selection
    
    # Select valid nodes
    phase[:valid_nodes].each do |node_id|
      node_obj = net.row_object('_nodes', node_id)
      if node_obj
        node_obj.selected = true
      end
    end
    
    # Select valid links
    phase[:valid_links].each do |link_id|
      link_obj = net.row_object('_links', link_id)
      if link_obj
        link_obj.selected = true
      end
    end
    
    # Create selection list with versioned name
    # Ensure unique name by checking existing children
    list_name = "#{sim_mo.name} Init Phase #{phase[:phase_num]}_v#{commit_id}"
    original_list_name = list_name
    
    diagnostics_group.children.each do |child|
      while child.name == list_name
        list_name += '!'
      end
    end
    
    begin
      sel_list = diagnostics_group.new_model_object('Selection List', list_name)
      net.save_selection(sel_list)
      
      if list_name != original_list_name
        puts "  Created: #{list_name} (#{phase[:valid_nodes].size} nodes, #{phase[:valid_links].size} links) [name adjusted for uniqueness]"
      else
        puts "  Created: #{list_name} (#{phase[:valid_nodes].size} nodes, #{phase[:valid_links].size} links)"
      end
    rescue => e
      puts "  WARNING: Failed to create selection list '#{list_name}': #{e.message}"
    end
  end
  
  puts "\n" + "="*80
  puts "Script completed successfully!"
  puts "="*80
  puts "Summary:"
  puts "  - Analyzed #{phases.length} initialization phase failure(s)"
  puts "  - Created #{phases_with_objects.length} selection list(s) in: #{diagnostics_group_name}"
  puts "  - CSV exported to: #{csv_path}"
  puts "="*80
  
rescue => e
  puts "\n" + "="*80
  puts "ERROR: Script failed with exception"
  puts "="*80
  puts e.message
  puts e.backtrace.join("\n")
  puts "="*80
end
