# frozen_string_literal: true
#
# Example 02 — Fetch 15-min rainfall readings for a station
#
# Usage:
#   ruby examples/02_readings.rb

require "smo_ea_hydrology"

client = SmoEaHydrology::Client.new

# Step 1: pick a station
stations = client.rainfall_15min_stations
station  = stations.first
puts "Station : #{station.label}"
puts "Ref     : #{station.station_reference}"
puts "Location: lat=#{station.lat}  long=#{station.long}"
puts

# Step 2: get its 15-min measure
measures = client.measures(station.station_reference)
measure  = measures.first
puts "Measure : #{measure.label}"
puts "ID      : #{measure.id}"
puts

# Step 3: fetch readings for a date range
from = "2024-06-01"
to   = "2024-06-07"
puts "Fetching readings #{from} to #{to}..."
readings = client.readings(measure.id, from: from, to: to)

puts "#{readings.size} readings returned (expected #{7 * 96} for 7 days)"
puts
puts format("%-25s %8s %-12s %-12s", "DateTime", "mm", "Quality", "Completeness")
puts "-" * 62
readings.first(10).each do |r|
  puts format("%-25s %8.2f %-12s %-12s", r.datetime, r.value, r.quality, r.completeness)
end
puts "... (showing first 10 of #{readings.size})"
puts

# Daily totals
puts "Daily totals:"
by_day = readings.group_by { |r| r.datetime.strftime("%Y-%m-%d") }
by_day.each do |date, rr|
  total = rr.sum(&:value).round(2)
  puts "  #{date}: #{total} mm (#{rr.size} readings)"
end
