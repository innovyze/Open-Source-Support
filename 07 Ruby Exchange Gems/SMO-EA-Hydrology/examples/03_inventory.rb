# frozen_string_literal: true
#
# Example 03 — Fetch the full 15-min rainfall inventory and export to CSV
#
# Usage:
#   ruby examples/03_inventory.rb
#   ruby examples/03_inventory.rb inventory.csv
#
# This makes two API calls per station (earliest reading + latest reading via
# flood-monitoring API), so expect it to take a few minutes for all stations.

require "csv"
require "smo_ea_hydrology"

csv_path = ARGV[0] || "ea_rainfall_15min_inventory.csv"

client = SmoEaHydrology::Client.new

puts "Fetching inventory (this may take several minutes)..."
entries = client.rainfall_15min_inventory

puts "#{entries.size} stations in inventory"
puts

# Print a sample table
puts format("%-15s %-35s %10s %10s %-22s %-22s",
            "Ref", "Station", "Lat", "Long", "Coverage From", "Coverage To")
puts "-" * 120
entries.first(10).each do |e|
  puts format("%-15s %-35s %10.5f %10.5f %-22s %-22s",
              e.station_reference.to_s,
              e.station_label.to_s[0, 34],
              e.lat.to_f,
              e.long.to_f,
              e.coverage_from_s,
              e.coverage_to_s)
end
puts "... (showing first 10 of #{entries.size})"
puts

# Export to CSV
CSV.open(csv_path, "w") do |csv|
  csv << %w[station_reference station_label lat long easting northing
            date_opened measure_id period_name unit_name value_type
            coverage_from coverage_to]

  entries.each do |e|
    csv << [
      e.station_reference,
      e.station_label,
      e.lat,
      e.long,
      e.easting,
      e.northing,
      e.date_opened,
      e.measure_id,
      e.period_name,
      e.unit_name,
      e.value_type,
      e.coverage_from_s,
      e.coverage_to_s
    ]
  end
end

puts "Exported #{entries.size} rows to #{csv_path}"
