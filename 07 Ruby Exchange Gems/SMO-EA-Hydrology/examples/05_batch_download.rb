# frozen_string_literal: true
#
# Example 05 — Batch download readings for multiple stations to individual CSVs
#
# HOW TO USE:
#   1. Edit the variables below (stations, date range, output folder)
#   2. Run:  ruby examples/05_batch_download.rb

require "smo_ea_hydrology"

# ── Edit these ────────────────────────────────────────────────────────────────

# Date range — "YYYY-MM-DD" or "YYYY-MM-DD HH:MM" (times are UTC)
FROM = "2024-06-01"
TO   = "2024-06-07"

# Folder where individual CSV files will be saved
OUTPUT_DIR = "batch_rainfall"

# Stations to download — use station names (partial match) or exact references.
# Set to nil to download ALL active 15-min stations (takes a long time).
STATIONS = [
  "Cosford",
  "Easby",
  "589359",   # Ulpha Duddo — reference works too
  "Colliford",
  "Coalburn Whitehill",
]

# ─────────────────────────────────────────────────────────────────────────────

client = SmoEaHydrology::Client.new

# Resolve station names/refs to station references
if STATIONS.nil?
  refs = nil
  puts "Downloading ALL active 15-min rainfall stations."
else
  puts "Resolving stations..."
  refs = []
  STATIONS.each do |query|
    matches = client.find_stations(query)
    if matches.empty?
      puts "  WARNING: no match for #{query.inspect} — skipped"
    else
      s = matches.first
      puts "  #{query.inspect.ljust(25)} → #{s.station_reference.to_s.ljust(12)} #{s.label}"
      refs << s.station_reference.to_s
    end
  end
  puts
end

puts "Date range : #{FROM} to #{TO}"
puts "Output dir : #{OUTPUT_DIR}"
puts

results = client.batch_download(
  from:       FROM,
  to:         TO,
  output_dir: OUTPUT_DIR,
  refs:       refs
)

puts
puts format("%-15s %-30s %8s  %s", "Ref", "File", "Readings", "Status")
puts "-" * 80
results.each do |ref, info|
  status = info[:error] ? "ERROR: #{info[:error]}" : "OK"
  puts format("%-15s %-30s %8s  %s", ref, File.basename(info[:path]), info[:count], status)
end

ok    = results.count { |_, v| !v[:error] }
total = results.values.sum { |v| v[:count] }
puts
puts "#{ok}/#{results.size} stations downloaded, #{total} total readings."
puts "Files saved to: #{File.expand_path(OUTPUT_DIR)}"
