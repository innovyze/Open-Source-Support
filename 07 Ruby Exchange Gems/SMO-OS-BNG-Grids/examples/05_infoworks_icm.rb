# frozen_string_literal: true
#
# Example 05 — InfoWorks ICM integration
#
# Demonstrates how to use smo_os_bng_grids inside InfoWorks ICM's embedded
# Ruby environment to assign BNG grid references and polygon boundaries to
# model objects such as subcatchments.
#
# In ICM the boundary_array field expects an array of [x, y] pairs that define
# the polygon vertices. The gem's :points key returns exactly that — a closed
# ring (SW -> SE -> NE -> NW -> SW).
#
# This script can be run standalone (pure Ruby) or pasted into the ICM
# Ruby scripting window.
#
# Usage (standalone):
#   ruby examples/05_infoworks_icm.rb

require "smo_os_bng_grids"

lister = SmoOsBngGrids::Lister.new

# ---------------------------------------------------------------------------
# Scenario A: Single point — find the tile that contains it and get its polygon
# ---------------------------------------------------------------------------
puts "=== Scenario A: tile containing a point ==="

easting  = 325000
northing = 673000

ref_10km = SmoOsBngGrids::Grid.ref_at(easting, northing, resolution: "10km")
ref_1km  = SmoOsBngGrids::Grid.ref_at(easting, northing, resolution: "1km")

puts "Point E=#{easting} N=#{northing}"
puts "  10km tile : #{ref_10km}"
puts "  1km  tile : #{ref_1km}"

# Get the full entry (includes :points) by searching with a tiny radius
entry = lister.search(easting, northing, resolution: "10km", radius: 1).first

puts "  boundary_array (10km tile corners):"
entry[:points].each { |pt| puts "    #{pt.inspect}" }
puts

# ---------------------------------------------------------------------------
# Scenario B: All 1km tiles within a radius — one subcatchment per tile
# ---------------------------------------------------------------------------
puts "=== Scenario B: 1km tiles within 1 500 m — ICM boundary_array per tile ==="

tiles = lister.search(easting, northing, resolution: "1km", radius: 1500)
           .sort_by { |e| e[:distance_m] }

tiles.each do |tile|
  # In a real ICM script you would assign these to a WSSubcatchment object:
  #   sc = WSApplication.current_network.row_object("hw_subcatchment", tile[:ref])
  #   sc.boundary_array = tile[:points]
  #   sc.write
  puts "  #{tile[:ref].ljust(8)} dist=#{tile[:distance_m].to_s.rjust(6)} m"
  puts "    boundary_array = #{tile[:points].inspect}"
end
puts "  #{tiles.size} tile(s)"
puts

# ---------------------------------------------------------------------------
# Scenario C: Box search — define a study area and get all 5km tiles in it
# ---------------------------------------------------------------------------
puts "=== Scenario C: 5km tiles within 15 000 m box around Edinburgh ==="

tiles_box = lister.search(easting, northing, resolution: "5km", box: 15000)

puts "Ref        min_e    min_n    max_e    max_n"
puts "-" * 52
tiles_box.each do |t|
  puts format("%-10s %8d %8d %8d %8d", t[:ref], t[:min_e], t[:min_n], t[:max_e], t[:max_n])
end
puts "  #{tiles_box.size} tile(s)"
puts

# ---------------------------------------------------------------------------
# Scenario D: Flat XY array (some APIs want a single flat array x,y,x,y,...)
# ---------------------------------------------------------------------------
puts "=== Scenario D: flat XY array for ICM APIs that need [x,y,x,y,...] ==="

tile    = lister.search(easting, northing, resolution: "10km", radius: 1).first
flat_xy = tile[:points].flatten
puts "#{tile[:ref]}: #{flat_xy.inspect}"
