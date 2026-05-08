## Source: WGS84
## Converted to: UTM Zone 17 (NAD 83) [EPSG 26917]
## General Maintenance objects are processed


# Constants
RAD_PER_DEG = Math::PI / 180
UTM_SCALE_FACTOR = 0.9996

# Ellipsoid model constants (WGS84)
EQUATORIAL_RADIUS = 6378137.0
POLAR_RADIUS = 6356752.314245
ECC_SQUARE = (EQUATORIAL_RADIUS**2 - POLAR_RADIUS**2) / EQUATORIAL_RADIUS**2

# Function to calculate UTM zone
def calc_utm_zone(longitude)
  (longitude / 6).floor + 31
end

# Function to convert lat, long to UTM
def latlon_to_utm(latitude, longitude)
  # Calculate the UTM zone
  zone = calc_utm_zone(longitude)

  # Calculate central meridian of UTM zone
  central_meridian = (zone - 1) * 6 - 180 + 3

  # Convert latitude and longitude to radians
  lat_rad = latitude * RAD_PER_DEG
  lon_rad = longitude * RAD_PER_DEG
  central_meridian_rad = central_meridian * RAD_PER_DEG

  # Calculate easting and northing
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

  if latitude < 0
    northing += 10000000
  end

  return zone, easting, northing
end

net = WSApplication.current_network
updated_ids = []
skipped_ids = []

net.transaction_begin
net.row_object_collection('cams_general_maintenance').each do |ro|
  next unless ro.selected?

  lat = ro.y
  lon = ro.x

  if lat.nil? || lon.nil?
    skipped_ids << ro.id
    next
  end

  _zone, easting, northing = latlon_to_utm(lat, lon)

  ro.x = easting
  ro.y = northing
  ro.write
  updated_ids << ro.id
end
net.transaction_commit

puts "=== Coordinate Conversion: WGS84 -> UTM (NAD83) ==="
puts ""
puts "Updated (#{updated_ids.size}):"
updated_ids.each { |id| puts "  [OK]     #{id}" }
puts ""
puts "Skipped - nil coordinates (#{skipped_ids.size}):"
skipped_ids.each { |id| puts "  [SKIP]   #{id}" }
puts ""
puts "Complete. #{updated_ids.size} updated, #{skipped_ids.size} skipped."
