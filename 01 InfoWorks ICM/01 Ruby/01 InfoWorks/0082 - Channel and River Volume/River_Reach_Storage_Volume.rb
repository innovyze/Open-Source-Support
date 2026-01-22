 # River Reach Storage Volume Calculator
# Calculates water storage volume for selected river reaches using cross-section data
# Supports two calculation methods: by depth or by elevation

# Get the current network
net = WSApplication.current_network
raise "No network open." unless net

# Helper method: Calculate polygon area using shoelace formula
def shoelace_area(poly)
  return 0.0 if poly.nil? || poly.size < 3
  area = 0.0
  n = poly.size
  (0...n).each do |i|
    x1, z1 = poly[i][:x], poly[i][:z]
    x2, z2 = poly[(i + 1) % n][:x], poly[(i + 1) % n][:z]
    area += (x1 * z2) - (x2 * z1)
  end
  (area.abs * 0.5).round(3)
end

# Helper method: Calculate distance between two points
def point_distance(x1, y1, x2, y2)
  Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
end

# Helper method: Find closest point on line segment to a given point
# Returns [closest_x, closest_y, distance_along_segment]
def closest_point_on_segment(px, py, x1, y1, x2, y2)
  dx = x2 - x1
  dy = y2 - y1
  len_sq = dx * dx + dy * dy
  return [x1, y1, 0.0] if len_sq == 0  # Segment is a point
  
  t = [(((px - x1) * dx + (py - y1) * dy) / len_sq), 0.0].max
  t = [t, 1.0].min
  
  closest_x = x1 + t * dx
  closest_y = y1 + t * dy
  [closest_x, closest_y, t * Math.sqrt(len_sq)]
end

# Helper method: Calculate chainage of a point along a polyline
def calculate_chainage(point_x, point_y, centreline, cumulative_dist)
  best_chainage = 0.0
  best_dist = Float::INFINITY
  
  (1...centreline.length).each do |i|
    cx, cy, seg_offset = closest_point_on_segment(
      point_x, point_y,
      centreline[i-1][:x], centreline[i-1][:y],
      centreline[i][:x], centreline[i][:y]
    )
    dist_to_line = point_distance(point_x, point_y, cx, cy)
    
    if dist_to_line < best_dist
      best_dist = dist_to_line
      best_chainage = cumulative_dist[i-1] + seg_offset
    end
  end
  
  best_chainage
end

# Helper method: Calculate wetted area at a given water level for a cross-section
def calculate_wetted_area(points, water_level)
  return 0.0 if points.nil? || points.size < 2
  return 0.0 if points.nil? || points.size < 2
  
  # Build wetted polygon - points below water level
  wetted = points.select { |pt| pt[:z] <= water_level }.sort_by { |pt| pt[:x] }
  
  # Interpolate water level intersections
  points.each_cons(2) do |a, b|
    if (a[:z] < water_level && b[:z] > water_level) || (a[:z] > water_level && b[:z] < water_level)
      ratio = (water_level - a[:z]) / (b[:z] - a[:z])
      x_interp = a[:x] + ratio * (b[:x] - a[:x])
      wetted << { x: x_interp, z: water_level }
    end
  end
  
  return 0.0 if wetted.size < 2
  wetted.sort_by! { |pt| pt[:x] }
  
  # Close polygon with water surface
  wetted_polygon = []
  wetted_polygon << { x: wetted.first[:x], z: water_level }
  wetted.each { |pt| wetted_polygon << pt }
  wetted_polygon << { x: wetted.last[:x], z: water_level }
  
  shoelace_area(wetted_polygon)
end

# Process only selected hw_river_reach links
selected_reaches = net.row_objects_selection('hw_river_reach')
if selected_reaches.size == 0
  puts "No river reaches selected. Please select river reaches and re-run."
  exit
end
puts "Found #{selected_reaches.size} selected river reach(es)."

# Gather statistics across all selected reaches
all_sections_data = []
global_min_invert = Float::INFINITY
global_max_invert = -Float::INFINITY
global_min_bank = Float::INFINITY
global_min_section_height = Float::INFINITY
global_max_section_height = -Float::INFINITY
total_length = 0.0
total_sections = 0

selected_reaches.each do |reach|
  sections_blob = reach.sections
  next if sections_blob.nil? || sections_blob.length == 0
  
  reach_length = reach.length.to_f
  total_length += reach_length
  
  # Build centreline from point_array for chainage calculation
  point_array = reach.point_array
  centreline = []
  (0...point_array.length).step(2) do |i|
    centreline << { x: point_array[i], y: point_array[i+1] }
  end
  
  # Calculate cumulative distances along centreline
  cumulative_dist = [0.0]
  (1...centreline.length).each do |i|
    d = point_distance(centreline[i-1][:x], centreline[i-1][:y], 
                       centreline[i][:x], centreline[i][:y])
    cumulative_dist << cumulative_dist.last + d
  end
  
  # Group all section points by key (section name) - O(n) hash lookup
  # Use XY coordinates for chainage and offset calculation
  sections_by_key = {}
  (0...sections_blob.length).each do |i|
    key = sections_blob[i].key
    sections_by_key[key] ||= []
    sections_by_key[key] << { 
      map_x: sections_blob[i].X.to_f, 
      map_y: sections_blob[i].Y.to_f, 
      z: sections_blob[i].Z.to_f 
    }
  end
  
  reach_sections = []
  
  sections_by_key.each do |section_key, raw_points|
    next if raw_points.empty?
    
    # Calculate offset (horizontal distance across section) from XY coordinates
    section_points = []
    cumulative_offset = 0.0
    raw_points.each_with_index do |pt, i|
      if i > 0
        dx = pt[:map_x] - raw_points[i-1][:map_x]
        dy = pt[:map_y] - raw_points[i-1][:map_y]
        cumulative_offset += Math.sqrt(dx*dx + dy*dy)
      end
      section_points << { x: cumulative_offset, z: pt[:z] }
    end
    
    # Calculate chainage using section midpoint projected onto centreline
    mid_x = (raw_points.first[:map_x] + raw_points.last[:map_x]) / 2.0
    mid_y = (raw_points.first[:map_y] + raw_points.last[:map_y]) / 2.0
    chainage = calculate_chainage(mid_x, mid_y, centreline, cumulative_dist)
    
    # Calculate section statistics
    min_z = section_points.map { |p| p[:z] }.min
    max_z = section_points.map { |p| p[:z] }.max
    left_bank_z = section_points.first[:z]
    right_bank_z = section_points.last[:z]
    min_bank_z = [left_bank_z, right_bank_z].min
    max_bank_z = [left_bank_z, right_bank_z].max
    section_height = min_bank_z - min_z
    
    # Update global stats
    global_min_invert = min_z if min_z < global_min_invert
    global_max_invert = min_z if min_z > global_max_invert
    global_min_bank = min_bank_z if min_bank_z < global_min_bank
    global_min_section_height = section_height if section_height < global_min_section_height
    global_max_section_height = section_height if section_height > global_max_section_height
    
    reach_sections << {
      reach_id: reach.id,
      chainage: chainage,
      points: section_points,
      min_z: min_z,
      max_z: max_z,
      min_bank_z: min_bank_z,
      max_bank_z: max_bank_z,
      section_height: section_height
    }
    total_sections += 1
  end
  
  # Sort sections by chainage
  reach_sections.sort_by! { |s| s[:chainage] }
  all_sections_data << { reach: reach, sections: reach_sections, length: reach_length }
end

if total_sections == 0
  puts "No valid cross-sections found in selected reaches. Exiting."
  exit
end

# Build statistics string for display in dialogs
stats_text = "=== Statistics ===\n" +
  "Reaches: #{selected_reaches.size}, Length: #{total_length.round(2)} m, Sections: #{total_sections}\n" +
  "Invert range: #{global_min_invert.round(2)} - #{global_max_invert.round(2)} mAD\n" +
  "Min bank elevation: #{global_min_bank.round(2)} mAD\n" +
  "Section height range: #{global_min_section_height.round(2)} - #{global_max_section_height.round(2)} m"

# Display statistics to console
puts "\n#{stats_text}"
puts ""

# Prompt user for calculation method (simple dialog)
method_input = WSApplication.input_box(
  "Enter calculation method:\n  1 = By depth (m)\n  2 = By elevation (mAD)",
  "Calculation Method",
  "1"
)

if method_input.nil? || method_input.strip.empty?
  puts "No method selected. Exiting."
  exit
end

calc_method = method_input.to_i
unless [1, 2].include?(calc_method)
  puts "Invalid method selected. Please enter 1 or 2. Exiting."
  exit
end

# Determine water level based on method
case calc_method
when 1
  # Depth-based (show statistics in this dialog)
  depth_input = WSApplication.input_box(
    "#{stats_text}\n\nEnter depth (m)\nMax safe depth = #{global_min_section_height.round(2)} m",
    "Water Depth",
    global_min_section_height.round(2).to_s
  )
  if depth_input.nil? || depth_input.strip.empty?
    puts "No depth entered. Exiting."
    exit
  end
  user_depth = depth_input.to_f
  if user_depth <= 0
    puts "Depth must be positive. Exiting."
    exit
  end
  puts "\nUsing depth: #{user_depth} m above invert at each section"
  
when 2
  # Elevation-based (show statistics in this dialog)
  elev_input = WSApplication.input_box(
    "#{stats_text}\n\nEnter water level (mAD)\nRange: #{global_min_invert.round(2)} - #{global_min_bank.round(2)} mAD",
    "Water Level",
    global_min_bank.round(2).to_s
  )
  if elev_input.nil? || elev_input.strip.empty?
    puts "No elevation entered. Exiting."
    exit
  end
  user_level = elev_input.to_f
  if user_level < global_min_invert
    puts "Water level #{user_level} mAD is below minimum invert (#{global_min_invert.round(2)} mAD). Exiting."
    exit
  end
  puts "\nUsing water level: #{user_level} mAD"
end

# Calculate volumes using trapezoidal integration between sections
total_volume_all_reaches = 0.0

all_sections_data.each do |reach_data|
  reach = reach_data[:reach]
  sections = reach_data[:sections]
  
  puts "\nProcessing reach: #{reach.id}"
  
  if sections.size < 2
    puts "  Insufficient sections (need at least 2). Skipping..."
    next
  end
  
  reach_volume = 0.0
  
  # Calculate area at each section
  section_areas = []
  sections.each do |section_data|
    # Determine water level for this section
    case calc_method
    when 1
      water_level = section_data[:min_z] + user_depth  # Depth above invert
    when 2
      water_level = user_level  # Fixed elevation
    end
    
    # Check if water level is below section invert
    if water_level < section_data[:min_z]
      area = 0.0
    else
      area = calculate_wetted_area(section_data[:points], water_level)
    end
    
    section_areas << {
      chainage: section_data[:chainage],
      area: area,
      water_level: water_level,
      invert: section_data[:min_z]
    }
  end
  
  # Output section details (compact format)
  puts "  Chainage(m)  Invert(mAD)  WaterLvl(mAD)  Area(m2)"
  section_areas.each do |s|
    puts "  #{s[:chainage].round(1).to_s.ljust(12)} #{s[:invert].round(2).to_s.ljust(12)} #{s[:water_level].round(2).to_s.ljust(14)} #{s[:area].round(2)}"
  end
  
  # Trapezoidal integration between adjacent sections
  section_areas.each_cons(2) do |s1, s2|
    distance = (s2[:chainage] - s1[:chainage]).abs
    avg_area = (s1[:area] + s2[:area]) / 2.0
    segment_volume = avg_area * distance
    reach_volume += segment_volume
  end
  
  puts "  Sections: #{sections.size}"
  puts "  Volume: #{reach_volume.round(2)} m3"
  
  total_volume_all_reaches += reach_volume
end

# Final summary
puts "\n=== Summary ==="
case calc_method
when 1
  puts "Method: Depth-based (#{user_depth} m)"
when 2
  puts "Method: Elevation-based (#{user_level} mAD)"
end
puts "Total volume for all reaches = #{total_volume_all_reaches.round(2)} m3"
