# frozen_string_literal: true
#
# Example 04 — Download readings for a single station to CSV
#
# HOW TO USE:
#   1. Edit the variables below (station name or reference, date range)
#   2. Run:  ruby examples/04_single_download.rb

require "smo_ea_hydrology"

# ── Edit these ────────────────────────────────────────────────────────────────
STATION = "Cosford"       # station name (partial match) OR exact reference e.g. "589359"
FROM    = "2024-06-01"    # start date — "YYYY-MM-DD" or "YYYY-MM-DD HH:MM" (times are UTC)
TO      = "2024-06-07"    # end date   — "YYYY-MM-DD" or "YYYY-MM-DD HH:MM" (times are UTC)
# ─────────────────────────────────────────────────────────────────────────────

client = SmoEaHydrology::Client.new

# Find the station by name or reference
puts "Searching for station: #{STATION.inspect}"
matches = client.find_stations(STATION)

if matches.empty?
  puts "No station found matching #{STATION.inspect}"
  puts "Tip: run example 01 to browse all available stations."
  exit 1
end

# Show all matches if more than one found
if matches.size > 1
  puts "Found #{matches.size} matches:"
  matches.each { |s| puts "  #{s.station_reference.to_s.ljust(15)} #{s.label}" }
  puts "Using the first match."
  puts
end

station = matches.first
puts "Station : #{station.label}"
puts "Ref     : #{station.station_reference}"
puts "Dataset : #{station.measure_label}"
puts "Lat/Long: #{station.lat}, #{station.long}"
puts

# Download readings to CSV
out = "#{station.station_reference}_#{FROM.gsub(/[: ]/, "-")}_#{TO.gsub(/[: ]/, "-")}.csv"
puts "Fetching #{FROM} to #{TO}..."
count = client.readings_to_csv(
  station_reference: station.station_reference,
  from: FROM,
  to:   TO,
  path: out
)

puts "#{count} readings written to #{out}"

# Quick preview
require "csv"
rows = CSV.read(out, headers: true)
puts
puts format("%-22s %8s %-12s %-12s", "DateTime (local)", "mm", "Quality", "Completeness")
puts "-" * 58
rows.first(10).each do |r|
  puts format("%-22s %8s %-12s %-12s", r["datetime"], r["value_mm"], r["quality"], r["completeness"])
end
puts "... (showing first 10 of #{rows.size})"
