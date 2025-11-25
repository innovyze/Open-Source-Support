# Simulation Diagnostic Tool
# This script parses simulation log files and creates selection lists based on extracted diagnostic information
# It helps identify issues during simulation runs by categorizing problems into different phases

# Get the current network and database
net = WSApplication.current_network
db = WSApplication.current_database

# Function to find parent model group
def find_parent_group(db, network_object)
  parent_id = network_object.parent_id
  begin
    group = db.model_object_from_type_and_id('Model Group', parent_id)
  rescue
    parent_object = db.model_object_from_type_and_id('Model Network', parent_id)
    parent_id = parent_object.parent_id
    group = db.model_object_from_type_and_id('Model Group', parent_id)
  end
  group
end

# Function to create a unique selection list name
def create_unique_name(group, base_name)
  # Collect all existing child names
  existing_names = group.children.map { |child| child.name }
  
  # Find a unique name
  list_name = base_name
  counter = 1
  while existing_names.include?(list_name)
    list_name = "#{base_name}_#{counter}"
    counter += 1
  end
  
  list_name
end

# Function to parse log file and extract issues
def parse_log_file(log_path)
  return nil unless File.exist?(log_path)
  
  issues = {
    errors: [],
    warnings: [],
    convergence: [],
    mass_balance: [],
    timestep: [],
    instability: []
  }
  
  File.readlines(log_path).each do |line|
    line = line.strip
    next if line.empty?
    
    # Extract errors
    if line.match?(/ERROR|FATAL/i)
      issues[:errors] << line
      issues[:convergence] << line if line.match?(/convergence|failed to converge/i)
      issues[:mass_balance] << line if line.match?(/mass balance|massbalance/i)
      issues[:instability] << line if line.match?(/instability|unstable/i)
    end
    
    # Extract warnings
    if line.match?(/WARNING|WARN/i)
      issues[:warnings] << line
      issues[:timestep] << line if line.match?(/timestep|time step|reducing/i)
    end
  end
  
  issues
end

# Function to extract node/link IDs from log messages
def extract_ids(messages, type = 'node')
  ids = []
  messages.each do |msg|
    # Common patterns for node/link IDs in log messages
    # Pattern 1: "at node NODE_ID" or "at link LINK_ID"
    match = msg.match(/at\s+#{type}\s+['"]?([^'"\s,]+)/i)
    if match
      ids << match[1]
    end
    
    # Pattern 2: "Node NODE_ID" or "Link LINK_ID"
    match = msg.match(/#{type}\s+['"]?([^'"\s,]+)/i)
    if match
      ids << match[1]
    end
    
    # Pattern 3: ID in brackets or quotes
    match = msg.match(/['"]([^'"]+)['"]/)
    if match
      potential_id = match[1]
      ids << potential_id if potential_id.length < 50
    end
  end
  ids.uniq
end

# Main script execution
begin
  # Prompt user for simulation ID
  result = WSApplication.prompt("Simulation Diagnostic Tool", [
    ['Enter Simulation ID or Name:', 'String', '', nil, nil, 'Simulation identifier']
  ], false)
  
  # Exit if user cancels
  if result.nil?
    puts "Script cancelled by user."
    return
  end
  
  sim_identifier = result[0].to_s.strip
  
  if sim_identifier.empty?
    WSApplication.message_box("Simulation ID cannot be empty. Script aborted.", "OK", "!", false)
    return
  end
  
  # Try to find the simulation object
  sim_object = nil
  
  # First, try to get by ID if it's numeric
  if sim_identifier.match?(/^\d+$/)
    begin
      sim_object = db.model_object_from_type_and_id('Sim', sim_identifier.to_i)
    rescue
      # Not found by ID
    end
  end
  
  # If not found by ID, try to find by name
  if sim_object.nil?
    all_sims = db.model_object_collection('Sim')
    all_sims.each do |sim|
      if sim.name == sim_identifier || sim.id.to_s == sim_identifier
        sim_object = sim
        break
      end
    end
  end
  
  if sim_object.nil?
    WSApplication.message_box("Simulation '#{sim_identifier}' not found in database. Please verify the ID or name.", "OK", "!", false)
    return
  end
  
  puts "Found simulation: #{sim_object.name} (ID: #{sim_object.id})"
  
  # Get the log file path
  # Try to get results path from simulation object
  results_path = nil
  begin
    results_path = sim_object.results_path
  rescue
    # If results_path is not available, construct likely path
    puts "Note: Could not determine results path from simulation object"
  end
  
  # Construct log file path - try multiple patterns
  log_file = nil
  if results_path && Dir.exist?(results_path)
    # Pattern 1: SIM[ID].log
    potential_log = File.join(results_path, "SIM#{sim_object.id}.log")
    log_file = potential_log if File.exist?(potential_log)
    
    # Pattern 2: [SimName].log
    if log_file.nil?
      potential_log = File.join(results_path, "#{sim_object.name}.log")
      log_file = potential_log if File.exist?(potential_log)
    end
  end
  
  # If still not found, prompt user for log file location
  if log_file.nil? || !File.exist?(log_file)
    file_result = WSApplication.prompt("Log File Location", [
      ['Select the simulation log file:', 'String', '', nil, 'FILE', 'Log file path']
    ], false)
    
    if file_result.nil?
      puts "Log file selection cancelled."
      return
    end
    
    log_file = file_result[0]
    
    unless File.exist?(log_file)
      WSApplication.message_box("Log file not found: #{log_file}", "OK", "!", false)
      return
    end
  end
  
  puts "Parsing log file: #{log_file}"
  
  # Parse the log file
  issues = parse_log_file(log_file)
  
  # Display summary
  puts "\n=== Simulation Diagnostic Summary ==="
  puts "Total Errors: #{issues[:errors].length}"
  puts "Total Warnings: #{issues[:warnings].length}"
  puts "Convergence Issues: #{issues[:convergence].length}"
  puts "Mass Balance Issues: #{issues[:mass_balance].length}"
  puts "Timestep Reductions: #{issues[:timestep].length}"
  puts "Instability Issues: #{issues[:instability].length}"
  
  # Get parent group for creating selection lists
  group = find_parent_group(db, net.model_object)
  
  # Create selection lists for each category with issues
  created_lists = []
  
  net.transaction_begin
  
  # Process convergence issues
  if issues[:convergence].length > 0
    puts "\n--- Creating selection list for Convergence Issues ---"
    node_ids = extract_ids(issues[:convergence], 'node')
    link_ids = extract_ids(issues[:convergence], 'link')
    
    if node_ids.length > 0 || link_ids.length > 0
      net.clear_selection
      
      # Select nodes
      node_ids.each do |id|
        if node = net.row_object('_nodes', id)
          node.selected = true
          node.write
          puts "Selected node: #{id}"
        end
      end
      
      # Select links
      link_ids.each do |id|
        if link = net.row_object('_links', id)
          link.selected = true
          link.write
          puts "Selected link: #{id}"
        end
      end
      
      list_name = create_unique_name(group, "Sim#{sim_object.id}_Convergence")
      sl = group.new_model_object('Selection List', list_name)
      net.save_selection(sl)
      created_lists << list_name
      puts "Created selection list: #{list_name}"
    end
  end
  
  # Process mass balance issues
  if issues[:mass_balance].length > 0
    puts "\n--- Creating selection list for Mass Balance Issues ---"
    node_ids = extract_ids(issues[:mass_balance], 'node')
    
    if node_ids.length > 0
      net.clear_selection
      
      node_ids.each do |id|
        if node = net.row_object('_nodes', id)
          node.selected = true
          node.write
          puts "Selected node: #{id}"
        end
      end
      
      list_name = create_unique_name(group, "Sim#{sim_object.id}_MassBalance")
      sl = group.new_model_object('Selection List', list_name)
      net.save_selection(sl)
      created_lists << list_name
      puts "Created selection list: #{list_name}"
    end
  end
  
  # Process instability issues
  if issues[:instability].length > 0
    puts "\n--- Creating selection list for Instability Issues ---"
    node_ids = extract_ids(issues[:instability], 'node')
    link_ids = extract_ids(issues[:instability], 'link')
    
    if node_ids.length > 0 || link_ids.length > 0
      net.clear_selection
      
      node_ids.each do |id|
        if node = net.row_object('_nodes', id)
          node.selected = true
          node.write
          puts "Selected node: #{id}"
        end
      end
      
      link_ids.each do |id|
        if link = net.row_object('_links', id)
          link.selected = true
          link.write
          puts "Selected link: #{id}"
        end
      end
      
      list_name = create_unique_name(group, "Sim#{sim_object.id}_Instability")
      sl = group.new_model_object('Selection List', list_name)
      net.save_selection(sl)
      created_lists << list_name
      puts "Created selection list: #{list_name}"
    end
  end
  
  # Process all errors (general category for errors not in specific categories)
  if issues[:errors].length > 0
    puts "\n--- Creating selection list for All Error Locations ---"
    node_ids = extract_ids(issues[:errors], 'node')
    link_ids = extract_ids(issues[:errors], 'link')
    
    if node_ids.length > 0 || link_ids.length > 0
      net.clear_selection
      
      node_ids.each do |id|
        if node = net.row_object('_nodes', id)
          node.selected = true
          node.write
          puts "Selected node: #{id}"
        end
      end
      
      link_ids.each do |id|
        if link = net.row_object('_links', id)
          link.selected = true
          link.write
          puts "Selected link: #{id}"
        end
      end
      
      list_name = create_unique_name(group, "Sim#{sim_object.id}_AllErrors")
      sl = group.new_model_object('Selection List', list_name)
      net.save_selection(sl)
      created_lists << list_name
      puts "Created selection list: #{list_name}"
    end
  end
  
  net.transaction_commit
  
  # Final summary
  puts "\n=== Processing Complete ==="
  if created_lists.length > 0
    puts "Created #{created_lists.length} selection list(s):"
    created_lists.each { |name| puts "  - #{name}" }
    puts "\nRefresh the database tree to view the new selection lists."
    WSApplication.message_box("Processing complete!\n\nCreated #{created_lists.length} selection list(s).\n\nSee console output for details.", "OK", "i", false)
  else
    puts "No issues with identifiable nodes/links were found in the log file."
    puts "Check the console output above for the diagnostic summary."
    WSApplication.message_box("Processing complete!\n\nNo selection lists created (no identifiable nodes/links in issues).\n\nSee console output for diagnostic summary.", "OK", "i", false)
  end
  
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.join("\n")
  WSApplication.message_box("An error occurred: #{e.message}\n\nCheck console for details.", "OK", "!", false)
  net.transaction_rollback if net
end
