## Source: WGS84
## Converted to: UTM Zone 17 (NAD 83) [EPSG 26917]
## Prompts the user to select an object type from the open network at runtime


# Constants
RAD_PER_DEG = Math::PI / 180
UTM_SCALE_FACTOR = 0.9996

# Ellipsoid model constants (WGS84)
EQUATORIAL_RADIUS = 6378137.0
POLAR_RADIUS = 6356752.314245
ECC_SQUARE = (EQUATORIAL_RADIUS**2 - POLAR_RADIUS**2) / EQUATORIAL_RADIUS**2

# Function to validate that coordinate values are plausible WGS84 decimal degrees.
# Latitude must be within -90..90 and longitude within -180..180.
# Values outside these ranges indicate the coordinates are already projected
# (e.g. UTM easting/northing) or are otherwise not WGS84.
def wgs84_valid?(latitude, longitude)
  latitude  >= -90.0  && latitude  <= 90.0 &&
  longitude >= -180.0 && longitude <= 180.0
end

# Function to calculate UTM zone
def calc_utm_zone(longitude)
  (longitude / 6).floor + 31
end

# Function to convert lat, long to UTM
def latlon_to_utm(latitude, longitude)
  zone = calc_utm_zone(longitude)

  central_meridian = (zone - 1) * 6 - 180 + 3

  lat_rad = latitude * RAD_PER_DEG
  lon_rad = longitude * RAD_PER_DEG
  central_meridian_rad = central_meridian * RAD_PER_DEG

  n = EQUATORIAL_RADIUS / Math.sqrt(1 - ECC_SQUARE * Math.sin(lat_rad)**2)
  t = Math.tan(lat_rad)**2
  c = ECC_SQUARE / (1 - ECC_SQUARE) * Math.cos(lat_rad)**2
  a = Math.cos(lat_rad) * (lon_rad - central_meridian_rad)

  m = EQUATORIAL_RADIUS * (
    (1 - ECC_SQUARE / 4 - 3 * ECC_SQUARE**2 / 64 - 5 * ECC_SQUARE**3 / 256) * lat_rad -
    (3 * ECC_SQUARE / 8 + 3 * ECC_SQUARE**2 / 32 + 45 * ECC_SQUARE**3 / 1024) * Math.sin(2 * lat_rad) +
    (15 * ECC_SQUARE**2 / 256 + 45 * ECC_SQUARE**3 / 1024) * Math.sin(4 * lat_rad) -
    (35 * ECC_SQUARE**3 / 3072) * Math.sin(6 * lat_rad)
  )

  easting = UTM_SCALE_FACTOR * n * (
    a +
    (1 - t + c) * a**3 / 6 +
    (5 - 18 * t + t**2 + 72 * c - 58 * ECC_SQUARE / (1 - ECC_SQUARE)) * a**5 / 120
  ) + 500000

  northing = UTM_SCALE_FACTOR * (
    m + n * Math.tan(lat_rad) * (
      a**2 / 2 +
      (5 - t + 9 * c + 4 * c**2) * a**4 / 24 +
      (61 - 58 * t + t**2 + 600 * c - 330 * ECC_SQUARE / (1 - ECC_SQUARE)) * a**6 / 720
    )
  )

  northing += 10000000 if latitude < 0

  return zone, easting, northing
end


net = WSApplication.current_network

# Build a sorted list of only the object types that have at least one selected object
object_types = []
net.tables.each do |t|
  has_selection = false
  net.row_object_collection(t.name).each do |ro|
    if ro.selected?
      has_selection = true
      break
    end
  end
  object_types << t.name if has_selection
end
object_types.sort!

if object_types.empty?
  WSApplication.message_box 'No selected objects were found in the network. Select objects on the GeoPlan and run the script again.', nil, '!', nil
  puts 'Conversion cancelled - no selected objects found.'
  exit
end

val = WSApplication.prompt 'WGS84 -> UTM Coordinate Conversion',
  [
    ['Object type to convert', 'String', object_types.first, nil, 'LIST', object_types],
    ['Convert all types (ignores selection above)', 'Boolean', false],
    ['Selected objects only are processed','Readonly','']
  ], false

# nil is returned if the user cancels the dialog
if val.nil?
  puts 'Conversion cancelled by user.'
else
  object_type = val[0].to_s
  convert_all = val[1]

  if convert_all
    confirm = WSApplication.message_box(
      "Convert all selected objects across #{object_types.size} object type(s)?\n\n#{object_types.join("\n")}",
      'YesNo', '?', false
    )
    if confirm != 'Yes'
      puts 'Conversion cancelled by user.'
      exit
    end
    types_to_process = object_types
  else
    types_to_process = [object_type]
  end

  puts "=== Coordinate Conversion: WGS84 -> UTM (NAD83) ==="
  puts ""

  total_updated = 0
  total_skipped = 0
  total_invalid = 0

  net.transaction_begin
  types_to_process.each do |type|
    updated_ids = []
    skipped_ids = []
    invalid_ids = []

    net.row_object_collection(type).each do |ro|
      next unless ro.selected?

      lat = ro.y
      lon = ro.x

      if lat.nil? || lon.nil?
        skipped_ids << ro.id
        next
      end

      unless wgs84_valid?(lat, lon)
        invalid_ids << "#{ro.id} (x=#{lon}, y=#{lat})"
        next
      end

      _zone, easting, northing = latlon_to_utm(lat, lon)

      ro.x = easting
      ro.y = northing
      ro.write
      updated_ids << ro.id
    end

    puts "--- #{type} ---"
    puts "Updated (#{updated_ids.size}):"
    updated_ids.each { |id| puts "  [OK]      #{id}" }
    puts "Skipped - nil coordinates (#{skipped_ids.size}):"
    skipped_ids.each { |id| puts "  [SKIP]    #{id}" }
    puts "Skipped - coordinates not in WGS84 range (#{invalid_ids.size}):"
    invalid_ids.each { |id| puts "  [INVALID] #{id}" }
    puts ""

    total_updated += updated_ids.size
    total_skipped += skipped_ids.size
    total_invalid += invalid_ids.size
  end
  net.transaction_commit

  puts "=== Complete. #{total_updated} updated, #{total_skipped + total_invalid} skipped across #{types_to_process.size} object type(s). ==="
end
