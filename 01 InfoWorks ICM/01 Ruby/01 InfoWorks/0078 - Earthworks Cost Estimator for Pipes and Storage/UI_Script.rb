# InfoWorks ICM UI Script
# Earthworks Cost Estimator (Pipes, Storage Nodes, and Ponds)
# 
# This script calculates high-level earthworks cost estimates for selected objects:
# - Pipes: Based on trench volume (length × width × average depth)
# - Storage Nodes/Ponds: Based on storage array volume below ground level
#
# Usage:
# 1. Select pipes, storage nodes, and/or ponds in the network
# 2. Run this script from the ICM UI
# 3. Enter the standard trench width when prompted (for pipes)
# 4. Enter the cost per cubic meter for earthworks
# 5. Review the results in the output window and exported CSV
#
# Documentation:
# @https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=GUID-C5C29FB2-8F6A-4F3A-9F3E-3B0F8E8F8F8F

# Access the current network
net = WSApplication.current_network

# Ensure a network is open
unless net
  WSApplication.message_box('No network is currently open. Please open a network and try again.', 'OK', 'Stop', false)
  exit
end

# Get selected objects
selected_pipes = net.row_objects_selection('hw_conduit')
selected_nodes = net.row_objects_selection('hw_node')

# Count pipes
pipe_count = selected_pipes.nil? ? 0 : selected_pipes.count

# Count storage nodes and ponds
storage_count = 0
if !selected_nodes.nil?
  selected_nodes.each do |node|
    node_type = node.node_type
    if !node_type.nil? && (node_type.downcase == 'storage' || node_type.downcase == 'pond')
      storage_count += 1
    end
  end
end

# Check if anything is selected
if pipe_count == 0 && storage_count == 0
  WSApplication.message_box('No pipes, storage nodes, or ponds selected. Please select objects and try again.', 'OK', 'Stop', false)
  exit
end

puts "Found #{pipe_count} selected pipes"
puts "Found #{storage_count} selected storage nodes/ponds"

# Prompt user for additional trench width and cost per cubic meter
prompt_layout = [
  ['Trench Additional Width (m)', 'NUMBER', 1],
  ['Cost per Cubic Meter ($/m^3)', 'NUMBER', 50.0],
  ['Export Results to CSV', 'BOOLEAN', false]
]

begin
  user_input = WSApplication.prompt('Earthworks Cost Estimator - Parameters', prompt_layout, false)
rescue StandardError => e
  puts "Prompt canceled or error occurred: #{e.message}"
  exit
end

unless user_input
  puts "User canceled the operation"
  exit
end

additional_width = user_input[0]
cost_per_m3 = user_input[1]
export_csv = user_input[2]

# Validate inputs
if additional_width.nil? || additional_width < 0
  WSApplication.message_box('Invalid additional trench width. Must be greater than or equal to 0.', 'OK', 'Stop', false)
  exit
end

if cost_per_m3.nil? || cost_per_m3 <= 0
  WSApplication.message_box('Invalid cost per cubic meter. Must be greater than 0.', 'OK', 'Stop', false)
  exit
end

puts "Trench additional width: #{additional_width} m"
puts "Cost per m^3: $#{cost_per_m3}"
puts ""
puts "Calculating earthworks volumes and costs..."
puts "=" * 80

# Initialize totals
total_volume = 0.0
total_cost = 0.0
pipe_results = []
storage_results = []
errors = []

# Helper function to calculate storage volume below ground level
def calculate_storage_volume(storage_array, ground_level)
  return 0.0 if storage_array.nil? || storage_array.length == 0 || ground_level.nil?
  
  # Extract all level-area pairs and sort by level
  all_points = []
  storage_array.each do |row|
    level = row['level']
    area = row['area']
    next if level.nil? || area.nil?
    all_points << { level: level, area: area }
  end
  
  return 0.0 if all_points.length < 2
  
  # Sort by level (ascending)
  all_points.sort_by! { |pt| pt[:level] }
  
  # Calculate volume using trapezoidal rule, but only for portions below ground level
  # We need to handle three cases:
  # 1. Both points below ground - add full segment
  # 2. Lower point below, upper point above - add partial segment up to ground level
  # 3. Both points above ground - skip segment
  
  total_volume = 0.0
  (0...all_points.length - 1).each do |i|
    h1 = all_points[i][:level]
    h2 = all_points[i + 1][:level]
    a1 = all_points[i][:area]
    a2 = all_points[i + 1][:area]
    
    # Skip if both points are above ground level
    next if h1 > ground_level
    
    # If lower point is below ground but upper point is above ground
    # Calculate partial volume up to ground level using linear interpolation
    if h2 > ground_level
      # Interpolate area at ground level
      height_ratio = (ground_level - h1) / (h2 - h1)
      area_at_ground = a1 + (a2 - a1) * height_ratio
      
      # Calculate volume from h1 to ground_level
      height = ground_level - h1
      volume_segment = height * (a1 + area_at_ground) / 2.0
      total_volume += volume_segment
      break  # No more segments below ground level
    else
      # Both points are below ground level - add full segment
      height = h2 - h1
      volume_segment = height * (a1 + a2) / 2.0
      total_volume += volume_segment
    end
  end
  
  total_volume
end

# Process each selected pipe
if !selected_pipes.nil?
  selected_pipes.each do |pipe|
  begin
    # Get pipe properties
    pipe_id = pipe.id
    us_node_id = pipe.us_node_id
    ds_node_id = pipe.ds_node_id
    pipe_length = pipe.conduit_length
    us_invert = pipe.us_invert
    ds_invert = pipe.ds_invert
    pipe_diameter_mm = pipe.conduit_width  # Get pipe diameter in mm
    
    # Validate pipe data
    if pipe_length.nil? || pipe_length <= 0
      errors << "#{pipe_id}: Invalid or missing pipe length"
      next
    end
    
    if us_invert.nil? || ds_invert.nil?
      errors << "#{pipe_id}: Missing invert levels"
      next
    end
    
    if pipe_diameter_mm.nil? || pipe_diameter_mm <= 0
      errors << "#{pipe_id}: Invalid or missing pipe diameter"
      next
    end
    
    # Convert pipe diameter from mm to m
    pipe_diameter = pipe_diameter_mm / 1000.0
    
    # Get upstream and downstream nodes
    us_node = net.row_object('hw_node', us_node_id)
    ds_node = net.row_object('hw_node', ds_node_id)
    
    if us_node.nil?
      errors << "#{pipe_id}: Upstream node '#{us_node_id}' not found"
      next
    end
    
    if ds_node.nil?
      errors << "#{pipe_id}: Downstream node '#{ds_node_id}' not found"
      next
    end
    
    # Get ground levels
    us_ground_level = us_node.ground_level
    ds_ground_level = ds_node.ground_level
    
    if us_ground_level.nil?
      errors << "#{pipe_id}: Upstream node '#{us_node_id}' missing ground level"
      next
    end
    
    if ds_ground_level.nil?
      errors << "#{pipe_id}: Downstream node '#{ds_node_id}' missing ground level"
      next
    end
    
    # Calculate depths (ground level - invert level)
    us_depth = us_ground_level - us_invert
    ds_depth = ds_ground_level - ds_invert
    
    # Check for negative depths (pipe above ground)
    if us_depth < 0
      errors << "#{pipe_id}: Warning - Upstream invert above ground level (depth: #{us_depth.round(2)} m)"
      us_depth = 0.0
    end
    
    if ds_depth < 0
      errors << "#{pipe_id}: Warning - Downstream invert above ground level (depth: #{ds_depth.round(2)} m)"
      ds_depth = 0.0
    end
    
    # Calculate average depth
    avg_depth = (us_depth + ds_depth) / 2.0
    
    # Calculate trench width (pipe diameter + additional width)
    trench_width = pipe_diameter + additional_width
    
    # Calculate trench volume (length × width × average depth)
    volume = pipe_length * trench_width * avg_depth
    
    # Calculate cost
    cost = volume * cost_per_m3
    
    # Add to totals
    total_volume += volume
    total_cost += cost
    
    # Store results
    pipe_results << {
      type: 'Pipe',
      id: pipe_id,
      us_node_id: us_node_id,
      ds_node_id: ds_node_id,
      length: pipe_length,
      diameter: pipe_diameter,
      trench_width: trench_width,
      us_depth: us_depth,
      ds_depth: ds_depth,
      avg_depth: avg_depth,
      volume: volume,
      cost: cost
    }
    
    # Output individual pipe results
    puts "Pipe: #{pipe_id}"
    puts "  Length: #{pipe_length.round(2)} m"
    puts "  Diameter: #{pipe_diameter.round(3)} m | Trench Width: #{trench_width.round(3)} m"
    puts "  US Depth: #{us_depth.round(2)} m | DS Depth: #{ds_depth.round(2)} m | Avg: #{avg_depth.round(2)} m"
    puts "  Volume: #{volume.round(2)} m^3"
    puts "  Cost: $#{cost.round(2)}"
    puts ""
    
  rescue StandardError => e
    errors << "Pipe #{pipe_id}: Error processing - #{e.message}"
  end
  end
end

# Process each selected storage node/pond
if !selected_nodes.nil?
  selected_nodes.each do |node|
    begin
      node_type = node.node_type
      next if node_type.nil?
      next unless node_type.downcase == 'storage' || node_type.downcase == 'pond'
      
      node_id = node.id
      ground_level = node.ground_level
      
      # Validate node data
      if ground_level.nil?
        errors << "Storage/Pond #{node_id}: Missing ground level"
        next
      end
      
      # Get storage array
      storage_array = node.storage_array
      
      if storage_array.nil? || storage_array.length == 0
        errors << "Storage/Pond #{node_id}: No storage array data"
        next
      end
      
      # Calculate volume below ground level
      volume = calculate_storage_volume(storage_array, ground_level)
      
      if volume <= 0
        errors << "Storage/Pond #{node_id}: No storage volume below ground level"
        next
      end
      
      # Calculate cost
      cost = volume * cost_per_m3
      
      # Add to totals
      total_volume += volume
      total_cost += cost
      
      # Get storage array details for reporting
      array_length = storage_array.length
      min_level = nil
      max_level = nil
      storage_array.each do |row|
        level = row['level']
        next if level.nil?
        min_level = level if min_level.nil? || level < min_level
        max_level = level if max_level.nil? || level > max_level
      end
      
      # Store results
      storage_results << {
        type: node_type,
        id: node_id,
        ground_level: ground_level,
        array_points: array_length,
        min_level: min_level,
        max_level: max_level,
        volume: volume,
        cost: cost
      }
      
      # Output individual storage node results
      puts "#{node_type}: #{node_id}"
      puts "  Ground Level: #{ground_level.round(2)} m"
      puts "  Storage Array: #{array_length} points (#{min_level.round(2)} to #{max_level.round(2)} m)"
      puts "  Excavation Volume: #{volume.round(2)} m^3"
      puts "  Cost: $#{cost.round(2)}"
      puts ""
      
    rescue StandardError => e
      errors << "Storage/Pond #{node.id}: Error processing - #{e.message}"
    end
  end
end

# Output summary
puts "=" * 80
puts "SUMMARY"
puts "=" * 80
puts "Pipes processed: #{pipe_results.count}"
puts "Storage nodes/ponds processed: #{storage_results.count}"
puts "Total objects processed: #{pipe_results.count + storage_results.count}"
puts "Total excavation volume: #{total_volume.round(2)} m^3"
puts "Total estimated cost: $#{total_cost.round(2)}"
puts ""

if errors.count > 0
  puts "ERRORS AND WARNINGS (#{errors.count}):"
  puts "-" * 80
  errors.each { |error| puts error }
  puts ""
end

# Export to CSV if requested
if export_csv && (pipe_results.count > 0 || storage_results.count > 0)
  begin
    # Get script directory for output file
    script_dir = File.dirname(WSApplication.script_file)
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    csv_file = File.join(script_dir, "earthworks_estimate_#{timestamp}.csv")
    
    # Write CSV file
    File.open(csv_file, 'w') do |file|
      # Write pipes section
      if pipe_results.count > 0
        file.puts "PIPES"
        file.puts "Pipe ID,US Node,DS Node,Length (m),Diameter (m),Trench Width (m),US Depth (m),DS Depth (m),Avg Depth (m),Volume (m^3),Cost per m^3 ($),Cost ($)"
        
        pipe_results.each do |result|
          file.puts "#{result[:id]},#{result[:us_node_id]},#{result[:ds_node_id]},#{result[:length].round(2)},#{result[:diameter].round(3)},#{result[:trench_width].round(3)},#{result[:us_depth].round(2)},#{result[:ds_depth].round(2)},#{result[:avg_depth].round(2)},#{result[:volume].round(2)},#{cost_per_m3},#{result[:cost].round(2)}"
        end
        file.puts ""
      end
      
      # Write storage nodes/ponds section
      if storage_results.count > 0
        file.puts "STORAGE NODES AND PONDS"
        file.puts "Type,Node ID,Ground Level (m),Array Points,Min Level (m),Max Level (m),Volume (m^3),Cost per m^3 ($),Cost ($)"
        
        storage_results.each do |result|
          file.puts "#{result[:type]},#{result[:id]},#{result[:ground_level].round(2)},#{result[:array_points]},#{result[:min_level].round(2)},#{result[:max_level].round(2)},#{result[:volume].round(2)},#{cost_per_m3},#{result[:cost].round(2)}"
        end
        file.puts ""
      end
      
      # Write summary section
      file.puts "SUMMARY"
      file.puts "Description,Value"
      file.puts "Pipes Processed,#{pipe_results.count}"
      file.puts "Storage Nodes/Ponds Processed,#{storage_results.count}"
      file.puts "Total Objects,#{pipe_results.count + storage_results.count}"
      file.puts "Total Volume (m^3),#{total_volume.round(2)}"
      file.puts "Total Cost ($),#{total_cost.round(2)}"
      file.puts "Cost per m^3 ($),#{cost_per_m3}"
      file.puts "Trench Additional Width (m),#{additional_width}"
    end
    
    puts "Results exported to: #{csv_file}"
    WSApplication.message_box("Earthworks cost estimation complete!\n\nPipes: #{pipe_results.count}\nStorage/Ponds: #{storage_results.count}\n\nTotal Volume: #{total_volume.round(2)} m^3\nTotal Cost: $#{total_cost.round(2)}\n\nResults exported to:\n#{csv_file}", 'OK', 'Information', false)
    
  rescue StandardError => e
    puts "Error exporting CSV: #{e.message}"
    WSApplication.message_box("Calculation complete but CSV export failed.\n\nTotal Volume: #{total_volume.round(2)} m^3\nTotal Cost: $#{total_cost.round(2)}\n\nSee output window for details.", 'OK', '!', false)
  end
else
  WSApplication.message_box("Earthworks cost estimation complete!\n\nPipes: #{pipe_results.count}\nStorage/Ponds: #{storage_results.count}\n\nTotal Volume: #{total_volume.round(2)} m^3\nTotal Cost: $#{total_cost.round(2)}\n\nSee output window for detailed results.", 'OK', 'Information', false)
end

puts "Script completed successfully"

