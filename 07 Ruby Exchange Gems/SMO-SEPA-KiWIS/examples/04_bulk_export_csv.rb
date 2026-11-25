require_relative "../lib/smo_sepa_kiwis"
require "fileutils"
require "csv"

# Usage: ruby examples/04_bulk_export_csv.rb [output_dir]
# Defaults to ./bulk_export in the current working directory.
output_dir = ARGV[0] || File.join(Dir.pwd, "bulk_export")
data_dir   = File.join(output_dir, "data")
FileUtils.mkdir_p(data_dir)

client = SmoSepaKiwis::Client.new

puts "Fetching 15-minute inventory..."
inventory = client.rainfall_15min_inventory
puts "#{inventory.size} timeseries found."

cutoff    = Time.now.utc - (30 * 86400)
active    = inventory.select { |r| r[:coverage_to] && r[:coverage_to] >= cutoff }
puts "Active (coverage_to within 30 days): #{active.size}"
puts

to_time   = Time.now.utc
from_time = to_time - (7 * 86400)

active.each_with_index do |row, idx|
  sno   = row[:station_no]
  ts_id = row[:ts_id]
  path  = File.join(data_dir, "#{sno}_#{ts_id}.csv")

  values = client.timeseries_values(ts_id: ts_id, from: from_time, to: to_time)

  CSV.open(path, "w") do |csv|
    csv << %w[timestamp value quality_code]
    values.each { |v| csv << [v.timestamp.strftime("%Y-%m-%dT%H:%M:%SZ"), v.value, v.quality_code] }
  end

  puts "[#{idx + 1}/#{active.size}] ts #{ts_id} station #{sno}: #{values.size} values -> #{path}"
  sleep 0.5
end

puts
puts "Done. Files written to #{output_dir}."
