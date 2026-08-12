# frozen_string_literal: true
#
# Example 03 — Spatial search (radius and box)
#
# Find all BNG grid tiles that intersect a given search area centred on an
# easting/northing. Useful for building InfoWorks ICM catchment boundaries or
# any workflow that needs "all tiles near this point".
#
# Radius search  -> also returns :distance_m (0.0 if the point is inside the tile)
# Box search     -> returns all tiles intersecting a square of side 2*box metres
#
# Usage:
#   ruby examples/03_spatial_search.rb

require "smo_os_bng_grids"

lister = SmoOsBngGrids::Lister.new

# Edinburgh city centre
easting  = 325000
northing = 673000

# ---------------------------------------------------------------------------
# 1. Circular search — 10km tiles within 12 km of Edinburgh
# ---------------------------------------------------------------------------
puts "=== Circular search: 10km tiles within 12 000 m of Edinburgh ==="
results = lister.search(easting, northing, resolution: "10km", radius: 12000)
results.sort_by { |e| e[:distance_m] }.each do |e|
  puts "  #{e[:ref].ljust(8)} dist=#{e[:distance_m].to_s.rjust(7)} m   NW=#{e[:points][0].inspect}"
end
puts "  #{results.size} tile(s) found"
puts

# ---------------------------------------------------------------------------
# 2. Circular search — 1km tiles within 1 500 m of Edinburgh
# ---------------------------------------------------------------------------
puts "=== Circular search: 1km tiles within 1 500 m of Edinburgh ==="
results_1km = lister.search(easting, northing, resolution: "1km", radius: 1500)
results_1km.sort_by { |e| e[:distance_m] }.each do |e|
  puts "  #{e[:ref].ljust(8)} dist=#{e[:distance_m].to_s.rjust(6)} m"
end
puts "  #{results_1km.size} tile(s) found"
puts

# ---------------------------------------------------------------------------
# 3. Box search — 5km tiles within a 10 000 m x 10 000 m box around Edinburgh
# ---------------------------------------------------------------------------
puts "=== Box search: 5km tiles within 10 000 m half-width box around Edinburgh ==="
box_results = lister.search(easting, northing, resolution: "5km", box: 10000)
box_results.each do |e|
  puts "  #{e[:ref].ljust(8)} min_e=#{e[:min_e]}  min_n=#{e[:min_n]}"
end
puts "  #{box_results.size} tile(s) found"
puts

# ---------------------------------------------------------------------------
# 4. Extracting corner points for InfoWorks ICM boundary_array
#    boundary_array expects an array of [x, y] pairs
# ---------------------------------------------------------------------------
puts "=== InfoWorks ICM boundary_array for each tile (radius 5 000 m, 10km) ==="
icm_tiles = lister.search(easting, northing, resolution: "10km", radius: 5000)
icm_tiles.each do |tile|
  boundary_array = tile[:points]   # [[x,y], [x,y], [x,y], [x,y], [x,y]]
  puts "  #{tile[:ref]}  dist=#{tile[:distance_m]} m"
  puts "    boundary_array = #{boundary_array.inspect}"
end
