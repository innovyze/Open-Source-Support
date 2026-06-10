# frozen_string_literal: true
#
# Example 01 — List active 15-min rainfall stations with coverage dates
#
# Usage:
#   ruby examples/01_stations.rb

require "smo_ea_hydrology"

client = SmoEaHydrology::Client.new

puts "Fetching active 15-min rainfall stations..."
stations = client.rainfall_15min_stations
puts "Found #{stations.size} stations"
puts

# Fetch coverage dates only for the stations we will display
display = stations.first(2)
display.each_with_index do |s, i|
  print "\r  Fetching coverage #{i + 1}/#{display.size}..."
  $stdout.flush
  s.coverage_from = client.send(:fetch_earliest, s.measure_id)
  s.coverage_to   = client.send(:fetch_latest_fm, s.station_reference)
end
puts "\r" + " " * 40 + "\r"

puts format("%-35s %-15s %10s %10s   %-17s %-17s",
            "Name", "Reference", "Lat", "Long", "Data From", "Data To")
puts "-" * 115
display.each do |s|
  puts format("%-35s %-15s %10.5f %10.5f   %-17s %-17s",
              s.label[0, 34],
              s.station_reference.to_s,
              s.lat,
              s.long,
              s.coverage_from_s,
              s.coverage_to_s)
end
puts "... (showing first 20 of #{stations.size})"
