################################################################################
# Script Name: loggers_location.rb
# Description: Analyzes hydrant elevations by area and selects monitoring points
#              - Finds lowest and highest elevation hydrant for each area
#              - Counts customer properties by area (from address points)
#              - Selects hydrants for monitoring:
#                * Formula: 1 hydrant per X properties (user configurable, default 250)
#                * Minimum: 2 hydrants per area (lowest and highest elevation)
#                * Example: 700 properties with ratio 250 = 3 hydrants
#              - Selected hydrants are SPATIALLY evenly distributed (by location)
#              - User can select which areas to analyze via checkbox dialog
#
# Author: Paolo Teixeira
# Date: November 7, 2024
#
################################################################################

# Helper function to calculate distance between two hydrants
def distance(hydrant1, hydrant2)
  dx = hydrant1[:x] - hydrant2[:x]
  dy = hydrant1[:y] - hydrant2[:y]
  Math.sqrt(dx * dx + dy * dy)
end

# Select hydrants that are spatially well-distributed
# Always includes min and max elevation hydrants, then adds hydrants that maximize spatial coverage
def select_nodes_spatially(hydrants, min_hydrant, max_hydrant, hydrants_to_select)
  return hydrants if hydrants_to_select >= hydrants.length
  return [min_hydrant, max_hydrant] if hydrants_to_select == 2
  
  selected = [min_hydrant, max_hydrant]
  remaining = hydrants.reject { |h| h[:id] == min_hydrant[:id] || h[:id] == max_hydrant[:id] }
  
  # Add additional hydrants by selecting the one furthest from any selected hydrant
  (hydrants_to_select - 2).times do
    break if remaining.empty?
    
    # Find the hydrant with maximum minimum distance to any selected hydrant
    best_hydrant = nil
    best_min_distance = -1
    
    remaining.each do |candidate|
      # Find minimum distance from this candidate to any selected hydrant
      min_distance = selected.map { |s| distance(candidate, s) }.min
      
      if min_distance > best_min_distance
        best_min_distance = min_distance
        best_hydrant = candidate
      end
    end
    
    if best_hydrant
      selected << best_hydrant
      remaining.delete(best_hydrant)
    end
  end
  
  selected
end

# Get the current network
net = WSApplication.current_network
if net.nil?
  WSApplication.message_box('Please open a network before running this script.', "ok", "exclamation", false)
  exit
end

begin
  # Get all hydrants from the network
  puts "Collecting hydrants..."
  hydrants_ro = net.row_objects('wn_hydrant')
  
  if hydrants_ro.nil? || hydrants_ro.length == 0
    puts "No hydrants found in the network."
    exit
  end
  
  puts "Found #{hydrants_ro.length} hydrants"
  puts ""
  
  # Group hydrants by area and count customer points
  area_data = Hash.new { |h, k| h[k] = {hydrants: [], customer_count: 0} }
  
  puts "Processing hydrants..."
  hydrants_ro.each do |hydrant|
    area = hydrant.area
    elevation = hydrant.ground_level
    
    # Skip if no area or elevation
    next if area.nil? || area.to_s.strip.empty?
    next if elevation.nil?
    
    area_data[area][:hydrants] << {
      id: hydrant.node_id,
      elevation: elevation,
      x: hydrant.x,
      y: hydrant.y
    }
  end
  
  # Count customer properties from address points
  puts "Counting customer properties from address points..."
  begin
    address_points_ro = net.row_objects('wn_address_point')
    if address_points_ro
      puts "Found #{address_points_ro.length} address points"
      address_points_ro.each do |address_point|
        allocated_pipe_id = address_point["allocated_pipe_id"]
        if !allocated_pipe_id.nil? && !allocated_pipe_id.empty?
          pipe = net.row_object('wn_pipe', allocated_pipe_id)
          next if pipe.nil?
          
          demand_at_us_node = address_point["demand_at_us_node"] ? true : false
          nodes = pipe.navigate(demand_at_us_node ? 'us_node' : 'ds_node')
          
          if nodes.length > 0
            node = nodes[0]
            area = node['area']
            no_of_properties = address_point['no_of_properties']
            
            if !no_of_properties.nil? && no_of_properties > 0 && !area.nil? && !area.empty?
              area_data[area][:customer_count] += no_of_properties
            end
          end
        end
      end
    end
  rescue => e
    puts "Warning: Could not count address points (#{e.message})"
  end
  
  puts ""
  
  if area_data.empty?
    puts "No hydrants with both area and elevation found."
    exit
  end
  
  puts "Found hydrants in #{area_data.keys.length} different areas"
  puts ""
  
  # ============================================================================
  # USER INPUT SECTION - Build prompt based on areas detected
  # ============================================================================
  
  sorted_areas = area_data.keys.sort
  selected_areas = []
  logger_to_property_ratio = 250  # Default value
  
  # Build prompt layout
  prompt_layout = [
    ['Logger to Property Ratio (1 logger per X properties)', 'NUMBER', 250, 0]
  ]
  
  if sorted_areas.length > 1
    # Multiple areas detected - add checkboxes for each area
    puts "Multiple areas detected. Prompting user for configuration..."
    
    prompt_layout << ['', 'READONLY', '=== Select Areas to Analyze ===']
    
    sorted_areas.each do |area|
      hydrant_count = area_data[area][:hydrants].length
      customer_count = area_data[area][:customer_count]
      prompt_layout << ["#{area} (#{hydrant_count} hydrants, #{customer_count} properties)", 'BOOLEAN', true]
    end
  else
    # Single area - just get the ratio
    puts "Single area detected - prompting for logger ratio only..."
  end
  
  # Show the prompt
  user_input = WSApplication.prompt(
    "Logger Location Analysis - Configuration",
    prompt_layout,
    false
  )
  
  if user_input.nil?
    puts "Script cancelled by user."
    exit
  end
  
  # Extract logger to property ratio
  logger_to_property_ratio = user_input[0].to_i
  if logger_to_property_ratio <= 0
    WSApplication.message_box("Invalid ratio. Please enter a positive number.", "ok", "exclamation", false)
    exit
  end
  
  # Extract selected areas
  if sorted_areas.length > 1
    # Skip first input (ratio) and second input (readonly separator)
    sorted_areas.each_with_index do |area, idx|
      if user_input[idx + 2]  # +2 to skip ratio and separator
        selected_areas << area
      end
    end
    
    if selected_areas.empty?
      WSApplication.message_box("No areas selected. Script cancelled.", "ok", "exclamation", false)
      puts "No areas selected by user."
      exit
    end
    
    puts "User selected #{selected_areas.length} area(s) for analysis:"
    selected_areas.each { |area| puts "  - #{area}" }
  else
    # Single area - use all areas
    selected_areas = sorted_areas
    puts "Analyzing entire network"
  end
  
  puts ""
  puts "=" * 80
  puts "HYDRANT ELEVATION ANALYSIS & LOGGER SELECTION BY AREA"
  puts "(Spatial Distribution)"
  puts "=" * 80
  puts "Logger to Property Ratio: 1 logger per #{logger_to_property_ratio} properties"
  puts "=" * 80
  
  puts ""
  puts "=" * 80
  puts "RESULTS BY AREA"
  puts "=" * 80
  puts ""
  
  # ============================================================================
  # ANALYSIS AND SELECTION
  # ============================================================================
  
  # Clear any existing selection
  net.clear_selection
  
  total_selected = 0
  
  # Find min and max elevation for each selected area and select hydrants
  selected_areas.each do |area|
    area_info = area_data[area]
    hydrants = area_info[:hydrants]
    customer_count = area_info[:customer_count]
    
    # Find hydrant with minimum elevation
    min_hydrant = hydrants.min_by { |h| h[:elevation] }
    
    # Find hydrant with maximum elevation
    max_hydrant = hydrants.max_by { |h| h[:elevation] }
    
    # Calculate how many hydrants to select for this area
    # Formula: 1 hydrant per X properties (user configured), minimum 2
    hydrants_to_select = [(customer_count / logger_to_property_ratio.to_f).ceil, 2].max
    
    # Make sure we don't try to select more hydrants than exist
    hydrants_to_select = [hydrants_to_select, hydrants.length].min
    
    puts "Area: #{area}"
    puts "  Total hydrants: #{hydrants.length}"
    puts "  Customer properties: #{customer_count}"
    puts "  Hydrants to select: #{hydrants_to_select}"
    puts ""
    puts "  LOWEST ELEVATION:"
    puts "    Hydrant ID: #{min_hydrant[:id]}"
    puts "    Elevation:  #{min_hydrant[:elevation].round(2)} m"
    puts "    Location:   (#{min_hydrant[:x].round(2)}, #{min_hydrant[:y].round(2)})"
    puts ""
    puts "  HIGHEST ELEVATION:"
    puts "    Hydrant ID: #{max_hydrant[:id]}"
    puts "    Elevation:  #{max_hydrant[:elevation].round(2)} m"
    puts "    Location:   (#{max_hydrant[:x].round(2)}, #{max_hydrant[:y].round(2)})"
    puts ""
    
    # Select hydrants spatially distributed
    selected_hydrants = select_nodes_spatially(hydrants, min_hydrant, max_hydrant, hydrants_to_select)
    
    # Actually select the hydrants in the network
    selected_hydrants.each do |hydrant_data|
      hydrant_ro = net.row_object('wn_hydrant', hydrant_data[:id])
      if hydrant_ro
        hydrant_ro.selected = true
        total_selected += 1
      end
    end
    
    puts "  Selected #{selected_hydrants.length} hydrants (spatially distributed):"
    selected_hydrants.each do |h|
      puts "    - #{h[:id]} (Elev: #{h[:elevation].round(2)} m, Loc: #{h[:x].round(1)}, #{h[:y].round(1)})"
    end
    
    puts ""
    puts "  Elevation range: #{(max_hydrant[:elevation] - min_hydrant[:elevation]).round(2)} m"
    puts ""
    puts "-" * 80
    puts ""
  end
  
  puts "=" * 80
  puts "SUMMARY"
  puts "=" * 80
  puts "Total areas analyzed: #{selected_areas.length}"
  puts "Total hydrants with area and elevation: #{selected_areas.map { |a| area_data[a][:hydrants].length }.sum}"
  puts "Total customer properties: #{selected_areas.map { |a| area_data[a][:customer_count] }.sum}"
  puts "Total hydrants selected: #{total_selected}"
  puts ""
  
  # ============================================================================
  # FINAL USER PROMPT - SELECT RECOMMENDED HYDRANTS
  # ============================================================================
  
  if total_selected > 0
    select_result = WSApplication.message_box(
      "Analysis complete!\n\n" +
      "#{total_selected} hydrants have been recommended for logger placement.\n\n" +
      "Would you like to select these hydrants on the map now?",
      "yesno",
      "?",
      false
    )
    
    if select_result == "no"
      # User chose not to select - clear the selection
      net.clear_selection
      puts "User chose not to select hydrants on the map."
      puts "Script completed - no hydrants selected."
    else
      puts "#{total_selected} hydrants are now selected in the network."
      puts "Script completed successfully!"
    end
  else
    puts "No hydrants were selected."
  end
  
rescue => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  WSApplication.message_box("An error occurred: #{e.message}", "ok", "stop", false)
end

puts "=" * 80

