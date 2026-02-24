################################################################################
# Script Name: multi_simulation_report.rb
# Description: Multi-Simulation Pressure and Velocity Violation Report
#              - Gets the parent model group from the current network
#              - Lists all Run objects in that group
#              - Prompts user to select multiple Runs and specify thresholds
#              - Iterates through all Simulations under each Run
#              - Counts customer points with min pressure below threshold
#              - Counts pipes with velocity above threshold
#              - Generates a text report with results grouped by Run
#
# Requirements:
#              - Network must be open in WS Pro UI
#              - Run objects must exist in the parent model group
#
# Author: Autodesk
# Date: December 2025
# Software: InfoWorks WS Pro 2026+
#
################################################################################

# ==============================================================================
# Configuration
# ==============================================================================
ENABLE_LOGGING = false  # Set to true to see detailed progress output

# Helper method for conditional logging
def log(message)
  puts message if ENABLE_LOGGING
end

# ==============================================================================
# Get current network and database
# ==============================================================================
net = WSApplication.current_network
db = WSApplication.current_database

if net.nil?
  WSApplication.message_box("No network is currently open.", "ok", "stop", false)
  exit
end

# ==============================================================================
# Navigate to parent model group
# ==============================================================================
log "=" * 80
log "MULTI-SIMULATION REPORT"
log "=" * 80
log ""
log "Getting parent model group..."

# Get the network model object - use network_model_object to always get the network
# even if a simulation is currently loaded
current_network_mo = net.network_model_object
log "Current network: #{current_network_mo.name} (Type: #{current_network_mo.type}, ID: #{current_network_mo.id})"

parent_id = current_network_mo.parent_id
parent_type = current_network_mo.parent_type

log "Parent: Type=#{parent_type}, ID=#{parent_id}"

if parent_id == 0 || parent_type == 'Master Database'
  WSApplication.message_box("Network is at the root of the database. Please place it inside a Model Group.", "ok", "stop", false)
  exit
end

# Get the parent - navigate up until we find a Model Group
model_group = nil
begin
  model_group = db.model_object_from_type_and_id(parent_type, parent_id)
  log "Found parent: #{model_group.name} (Type: #{model_group.type})"
  
  # If the parent is a Wesnet Run Group, go up one more level to the Model Group
  if model_group.type == 'Wesnet Run Group'
    log "Parent is a Run Group, navigating up to Model Group..."
    parent_id = model_group.parent_id
    parent_type = model_group.parent_type
    
    if parent_id == 0 || parent_type == 'Master Database'
      WSApplication.message_box("Run Group is at the root of the database.", "ok", "stop", false)
      exit
    end
    
    model_group = db.model_object_from_type_and_id(parent_type, parent_id)
    log "Found Model Group: #{model_group.name} (Type: #{model_group.type})"
  end
  
rescue => e
  WSApplication.message_box("Could not find parent model group: #{e.message}", "ok", "stop", false)
  exit
end

# ==============================================================================
# Find all Run objects in the Model Group
# ==============================================================================
log ""
log "Searching for Run objects in Model Group..."

runs = []

# Look through direct children of the Model Group
# Runs are typically inside Wesnet Run Groups, which are children of the Model Group
model_group.children.each do |child|
  if child.type == 'Wesnet Run'
    # Direct run under model group
    runs << child
  elsif child.type == 'Wesnet Run Group'
    # Wesnet Run Group - look for runs inside it
    log "  Found Run Group: #{child.name}"
    child.children.each do |run_child|
      if run_child.type == 'Wesnet Run'
        runs << run_child
      end
    end
  end
end

if runs.empty?
  WSApplication.message_box("No Run objects found. Please ensure you have run objects in the same model group as your network.", "ok", "stop", false)
  exit
end

log "Found #{runs.length} Run object(s):"
runs.each { |r| log "  - #{r.name} (ID: #{r.id})" }
log ""

# ==============================================================================
# Build checkbox prompt for multiple Run selection
# ==============================================================================
# Build prompt layout with checkboxes for each run, plus threshold fields
prompt_layout = []

# Add a checkbox for each run (default checked)
runs.each do |run|
  prompt_layout << ["#{run.name}", 'BOOLEAN', true]
end

# Add threshold fields
prompt_layout << ['Min Pressure Threshold (m)', 'NUMBER', 10.0]
prompt_layout << ['Max Velocity Threshold (m/s)', 'NUMBER', 3.0]

user_input = WSApplication.prompt("Select Runs to Analyze", prompt_layout, false)

if user_input.nil?
  puts "User cancelled."
  exit
end

# Extract selected runs and thresholds
selected_runs = []
runs.each_with_index do |run, idx|
  selected_runs << run if user_input[idx]
end

min_pressure_threshold = user_input[runs.length]
max_velocity_threshold = user_input[runs.length + 1]

if selected_runs.empty?
  WSApplication.message_box("No Runs selected.", "ok", "stop", false)
  exit
end

log "-" * 80
log "Configuration:"
log "  Selected Runs: #{selected_runs.map(&:name).join(', ')}"
log "  Min Pressure Threshold: #{min_pressure_threshold} m"
log "  Max Velocity Threshold: #{max_velocity_threshold} m/s"
log "-" * 80
log ""

# ==============================================================================
# Analyze each selected Run and its Simulations
# ==============================================================================
# Store results grouped by run
all_results = {}  # { run_name => [simulation_results] }

selected_runs.each do |selected_run|
  log "=" * 40
  log "Processing Run: #{selected_run.name}"
  log "=" * 40
  
  # Find all Simulations under this Run
  simulations = []
  selected_run.children.each do |child|
    if child.type == 'Wesnet Sim'
      simulations << child
    end
  end
  
  if simulations.empty?
    log "  No simulations found under this run - skipping"
    all_results[selected_run.name] = []
    next
  end
  
  log "Found #{simulations.length} simulation(s)"
  
  run_results = []
  
  simulations.each_with_index do |sim, idx|
    log "Processing simulation #{idx + 1}/#{simulations.length}: #{sim.name}..."
    
    # Check simulation status (case-insensitive comparison)
    sim_status = sim.status.to_s.downcase
    if sim_status != 'success'
      log "  WARNING: Simulation status is '#{sim.status}' - skipping"
      run_results << {
        name: sim.name,
        pressure_violations: 'N/A',
        velocity_violations: 'N/A',
        status: sim.status
      }
      next
    end
    
    begin
      # Open the simulation results onto the current network (UI method)
      log "  Opening simulation results: #{sim.name}..."
      net.open_results(sim)
      
      # Now use the current network which has results loaded
      # Count pressure violations at customer points (address points or nodes with demand)
      pressure_violation_count = 0
      
      # First try customer points / address points
      begin
        customer_points = net.row_objects('wn_address_point')
        if customer_points && customer_points.length > 0
          customer_points.each do |cp|
            begin
              # Get pressure results for customer point
              pressure_results = cp.results('pressure')
              if pressure_results && pressure_results.length > 0
                min_pressure = pressure_results.min
                if !min_pressure.nil? && min_pressure < min_pressure_threshold
                  pressure_violation_count += 1
                end
              end
            rescue
              # Customer point may not have results, skip
            end
          end
        end
      rescue
        # wn_address_point table may not exist
      end
      
      # If no customer points found, use nodes as proxy
      if pressure_violation_count == 0
        nodes = net.row_objects('wn_node')
        if nodes && nodes.length > 0
          nodes.each do |node|
            begin
              pressure_results = node.results('pressure')
              if pressure_results && pressure_results.length > 0
                min_pressure = pressure_results.min
                if !min_pressure.nil? && min_pressure < min_pressure_threshold
                  pressure_violation_count += 1
                end
              end
            rescue
              # Node may not have pressure results
            end
          end
        end
      end
      
      # Count velocity violations on pipes
      velocity_violation_count = 0
      
      pipes = net.row_objects('wn_pipe')
      if pipes && pipes.length > 0
        pipes.each do |pipe|
          begin
            # Try to get velocity results - field name may be 'velocity' or we calculate from flow
            velocity_results = nil
            begin
              velocity_results = pipe.results('velocity')
            rescue
              # Velocity field may not exist, try to calculate from flow
            end
            
            if velocity_results && velocity_results.length > 0
              max_velocity = velocity_results.max
              if !max_velocity.nil? && max_velocity > max_velocity_threshold
                velocity_violation_count += 1
              end
            else
              # Try calculating velocity from flow and diameter
              begin
                flow_results = pipe.results('flow')
                diameter = pipe['diameter'] # in mm typically
                
                if flow_results && flow_results.length > 0 && diameter && diameter > 0
                  # Convert diameter from mm to m
                  diameter_m = diameter > 20 ? diameter / 1000.0 : diameter
                  area = Math::PI * (diameter_m / 2.0) ** 2
                  
                  # Flow in l/s, convert to m³/s (divide by 1000)
                  # Velocity = Flow / Area
                  flow_results.each do |flow|
                    if !flow.nil?
                      # Assuming flow is in l/s
                      flow_m3s = flow.abs / 1000.0
                      velocity = flow_m3s / area
                      if velocity > max_velocity_threshold
                        velocity_violation_count += 1
                        break # Count pipe only once
                      end
                    end
                  end
                end
              rescue
                # Skip if we can't calculate velocity
              end
            end
          rescue => e
            # Skip pipe if error accessing results
          end
        end
      end
      
      run_results << {
        name: sim.name,
        pressure_violations: pressure_violation_count,
        velocity_violations: velocity_violation_count,
        status: 'success'
      }
      
      log "  Pressure violations: #{pressure_violation_count}"
      log "  Velocity violations: #{velocity_violation_count}"
      
    rescue => e
      log "  ERROR: #{e.message}"
      run_results << {
        name: sim.name,
        pressure_violations: 'ERROR',
        velocity_violations: 'ERROR',
        status: e.message
      }
    end
  end
  
  all_results[selected_run.name] = run_results
end

log ""

# ==============================================================================
# Generate Report (always output, regardless of ENABLE_LOGGING)
# ==============================================================================
puts "=" * 80
puts "MULTI-SIMULATION REPORT"
puts "=" * 80
puts ""
puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
puts "Min Pressure Threshold: #{min_pressure_threshold} m"
puts "Max Velocity Threshold: #{max_velocity_threshold} m/s"
puts ""

# Track grand totals
grand_total_pressure = 0
grand_total_velocity = 0
grand_total_sims = 0

# Output results for each run
all_results.each do |run_name, results|
  puts "-" * 80
  puts "RUN: #{run_name}"
  puts "-" * 80
  
  if results.empty?
    puts "  No simulations found"
    puts ""
    next
  end
  
  # Calculate column widths
  sim_name_width = [results.map { |r| r[:name].length }.max || 10, 20].max
  pressure_width = 20
  velocity_width = 20
  
  # Print header
  header = sprintf("%-#{sim_name_width}s  %#{pressure_width}s  %#{velocity_width}s", 
                   "Simulation", "Pressure Violations", "Velocity Violations")
  puts header
  puts "-" * header.length
  
  # Print data rows
  results.each do |r|
    puts sprintf("%-#{sim_name_width}s  %#{pressure_width}s  %#{velocity_width}s",
                 r[:name],
                 r[:pressure_violations].to_s,
                 r[:velocity_violations].to_s)
  end
  
  # Calculate run totals
  run_pressure = results.select { |r| r[:pressure_violations].is_a?(Numeric) }
                        .map { |r| r[:pressure_violations] }
                        .sum
  run_velocity = results.select { |r| r[:velocity_violations].is_a?(Numeric) }
                        .map { |r| r[:velocity_violations] }
                        .sum
  
  puts "-" * header.length
  puts sprintf("%-#{sim_name_width}s  %#{pressure_width}s  %#{velocity_width}s",
               "Run Total", run_pressure.to_s, run_velocity.to_s)
  puts ""
  
  grand_total_pressure += run_pressure
  grand_total_velocity += run_velocity
  grand_total_sims += results.length
end

# Print grand totals if multiple runs
if selected_runs.length > 1
  puts "=" * 80
  puts "GRAND TOTALS"
  puts "=" * 80
  puts "Runs analyzed: #{selected_runs.length}"
  puts "Total simulations: #{grand_total_sims}"
  puts "Total pressure violations: #{grand_total_pressure}"
  puts "Total velocity violations: #{grand_total_velocity}"
end

puts ""
puts "=" * 80

# ==============================================================================
# Ask user if they want to save the report
# ==============================================================================
save_result = WSApplication.message_box(
  "Analysis complete!\n\n" +
  "Runs analyzed: #{selected_runs.length}\n" +
  "Total simulations: #{grand_total_sims}\n" +
  "Total pressure violations: #{grand_total_pressure}\n" +
  "Total velocity violations: #{grand_total_velocity}\n\n" +
  "Would you like to save the report to a file?",
  "yesno",
  "?",
  false
)

if save_result == "yes"
  # Get save file location
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  default_filename = "multi_simulation_report_#{timestamp}"
  
  save_path = WSApplication.file_dialog(false, 'txt', 'Text files', default_filename, false, true)
  
  if save_path && !save_path.empty?
    File.open(save_path, 'w') do |file|
      file.puts "=" * 80
      file.puts "MULTI-SIMULATION REPORT"
      file.puts "=" * 80
      file.puts ""
      file.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      file.puts "Min Pressure Threshold: #{min_pressure_threshold} m"
      file.puts "Max Velocity Threshold: #{max_velocity_threshold} m/s"
      file.puts ""
      
      # Output results for each run
      all_results.each do |run_name, results|
        file.puts "-" * 80
        file.puts "RUN: #{run_name}"
        file.puts "-" * 80
        
        if results.empty?
          file.puts "  No simulations found"
          file.puts ""
          next
        end
        
        # Calculate column widths
        sim_name_width = [results.map { |r| r[:name].length }.max || 10, 20].max
        pressure_width = 20
        velocity_width = 20
        
        # Print header
        header = sprintf("%-#{sim_name_width}s  %#{pressure_width}s  %#{velocity_width}s", 
                         "Simulation", "Pressure Violations", "Velocity Violations")
        file.puts header
        file.puts "-" * header.length
        
        # Print data rows
        results.each do |r|
          file.puts sprintf("%-#{sim_name_width}s  %#{pressure_width}s  %#{velocity_width}s",
                           r[:name],
                           r[:pressure_violations].to_s,
                           r[:velocity_violations].to_s)
        end
        
        # Calculate run totals
        run_pressure = results.select { |r| r[:pressure_violations].is_a?(Numeric) }
                              .map { |r| r[:pressure_violations] }
                              .sum
        run_velocity = results.select { |r| r[:velocity_violations].is_a?(Numeric) }
                              .map { |r| r[:velocity_violations] }
                              .sum
        
        file.puts "-" * header.length
        file.puts sprintf("%-#{sim_name_width}s  %#{pressure_width}s  %#{velocity_width}s",
                         "Run Total", run_pressure.to_s, run_velocity.to_s)
        file.puts ""
      end
      
      # Print grand totals if multiple runs
      if selected_runs.length > 1
        file.puts "=" * 80
        file.puts "GRAND TOTALS"
        file.puts "=" * 80
        file.puts "Runs analyzed: #{selected_runs.length}"
        file.puts "Total simulations: #{grand_total_sims}"
        file.puts "Total pressure violations: #{grand_total_pressure}"
        file.puts "Total velocity violations: #{grand_total_velocity}"
      end
      
      file.puts ""
      file.puts "=" * 80
    end
    
    puts "Report saved to: #{save_path}"
    WSApplication.message_box("Report saved successfully!\n\n#{save_path}", "ok", "information", false)
  end
end

puts ""
puts "Script completed."


