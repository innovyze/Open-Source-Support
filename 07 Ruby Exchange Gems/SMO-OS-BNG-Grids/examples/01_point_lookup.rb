# frozen_string_literal: true
#
# Example 01 — Point lookup
#
# Given an easting and northing (OSGB36 / EPSG:27700), find the BNG grid
# reference at every resolution, plus the bounds and corner points.
#
# Usage:
#   ruby examples/01_point_lookup.rb

require "smo_os_bng_grids"

# Edinburgh city centre
easting  = 325000
northing = 673000

puts "=== Point lookup: E=#{easting} N=#{northing} ==="
puts

# --- ref_at: single resolution ---
%w[100km 50km 10km 5km 1km].each do |res|
  ref = SmoOsBngGrids::Grid.ref_at(easting, northing, resolution: res)
  puts "#{res.rjust(5)} -> #{ref}"
end

puts

# --- find: all resolutions at once ---
result = SmoOsBngGrids::Lister.new.find(easting, northing)
puts "find() all resolutions:"
result.each { |res, ref| puts "  #{res.rjust(5)}: #{ref}" }

puts

# --- bounds of the tile at any resolution ---
resolution = "100km"
ref        = SmoOsBngGrids::Grid.ref_at(easting, northing, resolution: resolution)
bounds     = SmoOsBngGrids::Grid.bounds(ref)
puts "Bounds of #{ref} (#{resolution}):"
puts "  min_e=#{bounds[:min_e]}  min_n=#{bounds[:min_n]}"
puts "  max_e=#{bounds[:max_e]}  max_n=#{bounds[:max_n]}"

puts

# --- Corner points from list ---
parent = ref[0, 2]  # 100km parent letter e.g. "NT"
entry  = SmoOsBngGrids::Lister.new
           .list(resolution, within: parent)
           .find { |e| e[:ref] == ref }

puts "Corner points of #{ref} (NW -> NE -> SE -> SW -> NW):"
entry[:points].each_with_index do |(x, y), i|
  label = %w[NW NE SE SW NW][i]
  puts "  #{label}: [#{x}, #{y}]"
end
