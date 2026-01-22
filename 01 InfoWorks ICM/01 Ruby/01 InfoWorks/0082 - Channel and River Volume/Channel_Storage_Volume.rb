# Get the current network
net = WSApplication.current_network
raise "No network open." unless net
#puts "Network loaded successfully."

# Helper method: Clip polygon at a given elevation
def clip_polygon(polygon, clip_z)
  below = []
  above = []

  polygon.each_with_index do |curr, i|
    nxt = polygon[(i + 1) % polygon.size]
    curr_below = curr[:z] <= clip_z
    next_below = nxt[:z] <= clip_z

    if curr_below
      below << curr
    else
      above << curr
    end

    if curr_below != next_below
      ratio = (clip_z - curr[:z]) / (nxt[:z] - curr[:z])
      x_interp = curr[:x] + ratio * (nxt[:x] - curr[:x])
      interp_point = { x: x_interp, z: clip_z }
      below << interp_point
      above << interp_point
    end
  end

  return below, above
end

# Helper method: Calculate polygon area using shoelace formula
def shoelace_area(poly)
  area = 0.0
  n = poly.size
  (0...n).each do |i|
    x1, z1 = poly[i][:x], poly[i][:z]
    x2, z2 = poly[(i + 1) % n][:x], poly[(i + 1) % n][:z]
    area += (x1 * z2) - (x2 * z1)
  end
  (area.abs * 0.5).round(3)
end

# Prompt user for water level (datum-based)
input = WSApplication.input_box("Enter water level (mAD):", "Water Level Input", "")
if input.nil? || input.strip.empty?
  puts "No water level entered. Exiting."
  exit
end
user_level = input.to_f
puts "User entered water level: #{user_level} mAD"

# Cache all channel shape profiles
shape_profiles = {}
#puts "Caching channel shape profiles..."
net.row_objects('hw_channel_shape').each do |shape|
  shape_profiles[shape.shape_id] = shape.profile
end
#puts "Cached #{shape_profiles.size} shape profiles."

# Process only selected hw_channel links
selected_channels = net.row_objects_selection('hw_channel')
if selected_channels.size == 0
  puts "No channels selected. Please select channels and re-run."
  exit
end
puts "Found #{selected_channels.size} selected channel(s)."

# Initialize total volume accumulator
total_volume_all_links = 0.0

selected_channels.each do |channel|
  puts "\nProcessing channel: #{channel.id}"

  shape_id = channel.shape
  profile = shape_profiles[shape_id]
  if profile.nil?
    puts "No profile found for shape ID #{shape_id}. Skipping..."
    next
  end

  us_invert = channel.us_invert
  ds_invert = channel.ds_invert
  length = channel.length
  if length.nil? || length == 0
    puts "Invalid channel length. Skipping..."
    next
  end

  # Check if water level is below channel invert
  min_invert = [us_invert, ds_invert].min
  if user_level < min_invert
    puts "Water level #{user_level} mAD is below channel invert (#{min_invert} mAD). Skipping..."
    next
  end

  gradient = (us_invert - ds_invert) / length.to_f
  #puts "Shape ID: #{shape_id}, Length: #{length}, Gradient: #{gradient}"

  # Determine min and max X
  min_x = Float::INFINITY
  max_x = -Float::INFINITY
  profile.each do |p|
    x = p['x'].to_f
    min_x = x if x < min_x
    max_x = x if x > max_x
  end
  x_range = max_x - min_x

  # Guard against malformed profile data
  if x_range == 0
    puts "Invalid profile (zero X range) for shape ID #{shape_id}. Skipping..."
    next
  end

  # Convert profile to absolute elevation points
  points = []
  max_rel_z = -Float::INFINITY
  profile.each do |p|
    x = p['x'].to_f
    rel_z = p['z'].to_f
    rel_pos = (x - min_x) / x_range
    invert_at_x = us_invert - rel_pos * (us_invert - ds_invert)
    abs_z = invert_at_x + rel_z
    points << { x: x, z: abs_z }
    max_rel_z = rel_z if rel_z > max_rel_z
  end

  max_bank_elev = [us_invert, ds_invert].min + max_rel_z
  #puts "Max bank elevation = #{max_bank_elev} m"

  # Build wetted polygon
  wetted = points.select { |pt| pt[:z] <= user_level }.sort_by { |pt| pt[:x] }

  # Interpolate water level intersections
  points.each_cons(2) do |a, b|
    if (a[:z] < user_level && b[:z] > user_level) || (a[:z] > user_level && b[:z] < user_level)
      ratio = (user_level - a[:z]) / (b[:z] - a[:z])
      x_interp = a[:x] + ratio * (b[:x] - a[:x])
      wetted << { x: x_interp, z: user_level }
    end
  end
  wetted.sort_by! { |pt| pt[:x] }

  # Close polygon with water surface
  wetted_polygon = []
  wetted_polygon << { x: wetted.first[:x], z: user_level }
  wetted.each { |pt| wetted_polygon << pt }
  wetted_polygon << { x: wetted.last[:x], z: user_level }

  # Clip polygon at bank elevation
  in_channel_poly, above_bank_poly = clip_polygon(wetted_polygon, max_bank_elev)

  # Calculate areas using shoelace formula
  area_in_channel = shoelace_area(in_channel_poly)
  area_above_bank = shoelace_area(above_bank_poly)
  total_area = area_in_channel + area_above_bank

  #puts "In-channel area = #{area_in_channel} m²"
  #puts "Above-bank area = #{area_above_bank} m²"
  #puts "Total wetted area = #{total_area} m²"

  # Adjust length for slope
  adjusted_length = length * Math.sqrt(1 + gradient**2)
  #puts "Adjusted length = #{adjusted_length.round(3)} m"

  # Volumes
  volume_in_channel = area_in_channel * adjusted_length
  volume_above_bank = area_above_bank * adjusted_length
  total_volume = volume_in_channel + volume_above_bank

  puts "In-channel volume = #{volume_in_channel.round(2)} m³"
  puts "Above-bank volume = #{volume_above_bank.round(2)} m³"
  puts "Total volume = #{total_volume.round(2)} m³ at level #{user_level} m"

  # Accumulate total volume
  total_volume_all_links += total_volume
end

# Final summary
puts "\n=== Summary ==="
puts "Total volume for all links = #{total_volume_all_links.round(2)} m³ at level #{user_level} m"
