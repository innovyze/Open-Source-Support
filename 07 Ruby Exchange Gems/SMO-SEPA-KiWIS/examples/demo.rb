require_relative "../lib/smo_sepa_kiwis"

client = SmoSepaKiwis::Client.new

# -----------------------------------------------------------------------------
# 1. List all rainfall stations
# -----------------------------------------------------------------------------
puts "=" * 60
puts "1. RAINFALL STATIONS"
puts "=" * 60

stations = client.rainfall_stations
puts "Total stations: #{stations.size}"
puts
puts "%-10s %-28s %9s %9s" % ["No", "Name", "Lat", "Lon"]
puts "-" * 60
stations.first(5).each do |s|
  puts "%-10s %-28s %9s %9s" % [s.no, s.name, s.lat, s.lon]
end
puts "  ... (#{stations.size - 5} more)"
puts

# -----------------------------------------------------------------------------
# 2. Find 15-min timeseries for a specific station
# -----------------------------------------------------------------------------
puts "=" * 60
puts "2. 15-MIN TIMESERIES FOR A STATION"
puts "=" * 60

station = stations.first
puts "Station: #{station.no} - #{station.name}"
puts

series = client.rainfall_15min_timeseries(station_no: station.no)
puts "#{series.size} timeseries found."
series.each do |ts|
  from = ts.coverage_from&.strftime("%Y-%m-%d %H:%M:%S UTC") || "n/a"
  to   = ts.coverage_to&.strftime("%Y-%m-%d %H:%M:%S UTC")   || "n/a"
  puts "  ts_id: #{ts.ts_id}"
  puts "  path:  #{ts.ts_path}"
  puts "  from:  #{from}"
  puts "  to:    #{to}"
  puts
end

# -----------------------------------------------------------------------------
# 3. Full inventory (all stations + all 15-min series combined)
# -----------------------------------------------------------------------------
puts "=" * 60
puts "3. FULL 15-MIN INVENTORY"
puts "=" * 60

inventory = client.rainfall_15min_inventory
puts "Total timeseries across all stations: #{inventory.size}"
puts
puts "%-10s %-22s %12s %12s %10s" % ["Station", "Name", "Coverage from", "Coverage to", "ts_id"]
puts "-" * 70
inventory.first(5).each do |r|
  from = r[:coverage_from]&.strftime("%Y-%m-%d") || "n/a"
  to   = r[:coverage_to]&.strftime("%Y-%m-%d")   || "n/a"
  puts "%-10s %-22s %12s %12s %10s" % [r[:station_no], r[:station_name].to_s[0, 21], from, to, r[:ts_id]]
end
puts "  ... (#{inventory.size - 5} more)"
puts

# -----------------------------------------------------------------------------
# 4. Download timeseries values for a specific ts_id and date range
# -----------------------------------------------------------------------------
puts "=" * 60
puts "4. TIMESERIES VALUES"
puts "=" * 60

ts    = series.first
from  = "2024-01-01"
to    = "2024-01-08"

puts "ts_id: #{ts.ts_id} (#{ts.ts_path})"
puts "Period: #{from} to #{to}"
puts

values = client.timeseries_values(ts_id: ts.ts_id, from: from, to: to)
non_nil = values.reject { |v| v.value.nil? }

puts "Values fetched: #{values.size}"
puts "Non-nil values: #{non_nil.size}"
puts "Total rainfall: #{"%.2f" % non_nil.sum(&:value)} mm"

if (peak = non_nil.max_by(&:value))
  puts "Peak intensity: #{"%.2f" % peak.value} mm at #{peak.timestamp.strftime("%Y-%m-%d %H:%M:%S UTC")}"
end
puts
puts "First 5 values:"
puts "  %-28s %8s" % ["Timestamp", "Value (mm)"]
puts "  " + "-" * 38
values.first(5).each do |v|
  puts "  %-28s %8s" % [v.timestamp.strftime("%Y-%m-%d %H:%M:%S UTC"), v.value.nil? ? "nil" : "%.2f" % v.value]
end
puts

# -----------------------------------------------------------------------------
# 5. Chunked download over a long range
# -----------------------------------------------------------------------------
puts "=" * 60
puts "5. CHUNKED DOWNLOAD (30-day chunks over 1 year)"
puts "=" * 60

values_chunked = client.timeseries_values(
  ts_id:      ts.ts_id,
  from:       "2023-01-01",
  to:         "2024-01-01",
  chunk_days: 30
)
puts "ts_id: #{ts.ts_id}"
puts "Period: 2023-01-01 to 2024-01-01 in 30-day chunks"
puts "Total values: #{values_chunked.size}"
total = values_chunked.reject { |v| v.value.nil? }.sum(&:value)
puts "Total rainfall: #{"%.2f" % total} mm"
puts

# -----------------------------------------------------------------------------
# 6. Write values to CSV
# -----------------------------------------------------------------------------
puts "=" * 60
puts "6. EXPORT VALUES TO CSV"
puts "=" * 60

csv_path = File.join(Dir.pwd, "#{ts.ts_id}_2024_jan.csv")
client.timeseries_values_to_csv(
  ts_id: ts.ts_id,
  from:  "2024-01-01",
  to:    "2024-01-08",
  path:  csv_path
)
lines = File.readlines(csv_path)
puts "Saved #{lines.size - 1} rows to #{csv_path}"
puts "Header: #{lines.first.chomp}"
puts "Row 1:  #{lines[1]&.chomp}"
puts

puts "=" * 60
puts "All done."
puts "=" * 60
