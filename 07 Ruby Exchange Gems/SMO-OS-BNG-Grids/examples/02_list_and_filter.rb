# frozen_string_literal: true
#
# Example 02 — Listing grid squares with filters
#
# List BNG grid squares at any resolution, optionally filtered to those
# falling within a parent grid square. Every entry includes corner points.
#
# Usage:
#   ruby examples/02_list_and_filter.rb

require "smo_os_bng_grids"

lister = SmoOsBngGrids::Lister.new

# --- All 100km squares ---
all_100km = lister.list("100km")
puts "Total 100km squares: #{all_100km.size}"
puts "First entry: #{all_100km.first.inspect}"
puts

# --- 10km squares within NT ---
nt_10km = lister.list("10km", within: "NT")
puts "10km squares within NT: #{nt_10km.size}"
puts

# --- 5km squares within NT27 ---
nt27_5km = lister.list("5km", within: "NT27")
puts "5km squares within NT27:"
nt27_5km.each do |e|
  puts "  #{e[:ref]}  NW=#{e[:points][0].inspect}  SE=#{e[:points][2].inspect}"
end
puts

# --- 1km squares within NT27 ---
nt27_1km = lister.list("1km", within: "NT27")
puts "1km squares within NT27: #{nt27_1km.size}"
puts "Sample (first 5):"
nt27_1km.first(5).each do |e|
  puts "  #{e[:ref]}  min_e=#{e[:min_e]}  min_n=#{e[:min_n]}  points=#{e[:points].inspect}"
end
puts

# --- Summary table (prints to stdout) ---
puts "=== Summary: 50km within NT ==="
lister.summary("50km", within: "NT")
