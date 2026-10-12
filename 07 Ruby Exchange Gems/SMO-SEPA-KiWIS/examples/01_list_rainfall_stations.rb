require_relative "../lib/smo_sepa_kiwis"

client   = SmoSepaKiwis::Client.new
stations = client.rainfall_stations

puts "Total stations: #{stations.size}"
puts
puts "%-10s %-30s %10s %10s" % ["No", "Name", "Lat", "Lon"]
puts "-" * 64
stations.each do |s|
  puts "%-10s %-30s %10s %10s" % [s.no.to_s, s.name.to_s, s.lat.to_s, s.lon.to_s]
end
