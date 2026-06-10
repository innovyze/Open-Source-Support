require_relative "../lib/smo_sepa_kiwis"

# Change this to a valid SEPA station number for your area.
station_no = ARGV[0] || "14964"

client = SmoSepaKiwis::Client.new
series = client.rainfall_15min_timeseries(station_no: station_no)

puts "15-minute timeseries for station #{station_no}: #{series.size} found"
puts
puts "%-12s %-30s %-12s %-12s" % ["ts_id", "ts_path", "from", "to"]
puts "-" * 70

series.each do |ts|
  from_s = ts.coverage_from ? ts.coverage_from.strftime("%Y-%m-%d") : "n/a"
  to_s   = ts.coverage_to   ? ts.coverage_to.strftime("%Y-%m-%d")   : "n/a"
  puts "%-12s %-30s %-12s %-12s" % [ts.ts_id.to_s, ts.ts_path.to_s, from_s, to_s]
end
