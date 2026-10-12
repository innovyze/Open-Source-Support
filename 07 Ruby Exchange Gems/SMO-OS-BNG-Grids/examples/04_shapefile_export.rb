# frozen_string_literal: true
#
# Example 04 — Shapefile export
#
# Export BNG grid squares to ESRI Shapefile format (.shp/.shx/.dbf/.prj).
# Output CRS is OSGB36 British National Grid (EPSG:27700).
#
# There are three ways to build the entries to export:
#   1. list()       — all tiles at a resolution, optionally filtered to a parent tile
#   2. search()     — tiles intersecting a radius or box around a point
#   3. find()       — the single tile at each resolution that contains a point
#                     (convert refs to entries with entry_for())
#
# Usage:
#   ruby examples/04_shapefile_export.rb

require "smo_os_bng_grids"
require "tmpdir"

lister = SmoOsBngGrids::Lister.new
writer = SmoOsBngGrids::ShapefileWriter.new

output_dir = File.join(Dir.tmpdir, "bng_shapefiles")
FileUtils.mkdir_p(output_dir)
puts "Writing shapefiles to: #{output_dir}"
puts

# Edinburgh city centre
easting  = 325000
northing = 673000

# ---------------------------------------------------------------------------
# 1. Export from list()
# ---------------------------------------------------------------------------
puts "--- From list() ---"

# All 100km squares
writer.write(lister.list("100km"), File.join(output_dir, "bng_100km"))
puts

# All 10km squares within NT
writer.write(lister.list("10km", within: "NT"), File.join(output_dir, "nt_10km"))
puts

# All 5km squares within NT27
writer.write(lister.list("5km", within: "NT27"), File.join(output_dir, "nt27_5km"))
puts

# All 1km squares within NT27
writer.write(lister.list("1km", within: "NT27"), File.join(output_dir, "nt27_1km"))
puts

# ---------------------------------------------------------------------------
# 2. Export from search()
# ---------------------------------------------------------------------------
puts "--- From search() ---"

# All 10km tiles within 20km radius of Edinburgh
entries = lister.search(easting, northing, resolution: "10km", radius: 20000)
writer.write(entries, File.join(output_dir, "edinburgh_10km_radius20km"))
puts

# All 1km tiles within 2km radius of Edinburgh
entries = lister.search(easting, northing, resolution: "1km", radius: 2000)
writer.write(entries, File.join(output_dir, "edinburgh_1km_radius2km"))
puts

# All 5km tiles within a 15km box around Edinburgh
entries = lister.search(easting, northing, resolution: "5km", box: 15000)
writer.write(entries, File.join(output_dir, "edinburgh_5km_box15km"))
puts

# ---------------------------------------------------------------------------
# 3. Export from find() — one tile per resolution containing the point
# ---------------------------------------------------------------------------
puts "--- From find() ---"

found = lister.find(easting, northing)
# found => {"100km"=>"NT", "50km"=>"NTNW", "10km"=>"NT27", "5km"=>"NT27SE", "1km"=>"NT2573"}

# Export all containing tiles as a single shapefile (one feature per resolution)
entries = found.map { |_res, ref| lister.entry_for(ref) }
writer.write(entries, File.join(output_dir, "edinburgh_containing_tiles"))
puts

# Or export each resolution separately
found.each do |res, ref|
  entry = lister.entry_for(ref)
  writer.write([entry], File.join(output_dir, "edinburgh_#{res}"))
  puts
end

puts "Done. Open #{output_dir} in QGIS or ArcGIS to inspect."
