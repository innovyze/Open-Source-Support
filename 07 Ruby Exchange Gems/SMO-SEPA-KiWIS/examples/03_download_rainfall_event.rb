require_relative "../lib/smo_sepa_kiwis"

# Change ts_id to a valid 15-minute rainfall timeseries ID for your station.
TS_ID = 55570010
FROM  = "2021-10-22"
TO    = "2021-10-25"

client = SmoSepaKiwis::Client.new
values = client.timeseries_values(ts_id: TS_ID, from: FROM, to: TO)

non_nil = values.reject { |v| v.value.nil? }
total   = non_nil.sum { |v| v.value }
peak    = non_nil.max_by { |v| v.value }

puts "ts_id: #{TS_ID}, period: #{FROM} to #{TO}"
puts "Values fetched: #{values.size}"
puts "Total rainfall: #{"%.2f" % total} mm"
if peak
  puts "Peak intensity: #{"%.2f" % peak.value} mm at #{peak.timestamp.strftime("%Y-%m-%dT%H:%M:%SZ")}"
end

out = "rainfall_event_#{TS_ID}.csv"
client.timeseries_values_to_csv(ts_id: TS_ID, from: FROM, to: TO, path: out)
puts "Saved to #{out}."
