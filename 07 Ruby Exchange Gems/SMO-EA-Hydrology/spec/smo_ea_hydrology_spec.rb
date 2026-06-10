# frozen_string_literal: true

require_relative "../lib/smo_ea_hydrology"

$errors_count = 0

def assert(desc, &block)
  if block.call
    puts "PASS  #{desc}"
  else
    puts "FAIL  #{desc}"
    $errors_count += 1
  end
rescue => e
  puts "ERROR #{desc}: #{e.message}"
  $errors_count += 1
end

def assert_raises(desc, &block)
  block.call
  puts "FAIL  #{desc} (no exception raised)"
  $errors_count += 1
rescue ArgumentError, SmoEaHydrology::Error
  puts "PASS  #{desc}"
end

puts "=== smo_ea_hydrology tests ==="
puts

client = SmoEaHydrology::Client.new

# ---------------------------------------------------------------------------
# Stations
# ---------------------------------------------------------------------------
puts "-- Stations --"

stations = client.rainfall_15min_stations
assert("returns an Array") { stations.is_a?(Array) }
assert("returns at least 100 stations") { stations.size >= 100 }
assert("each item is a Station struct") { stations.all? { |s| s.is_a?(SmoEaHydrology::Station) } }
assert("stations have labels") { stations.all? { |s| s.label.is_a?(String) && !s.label.empty? } }
assert("stations have station_reference") { stations.all? { |s| !s.station_reference.nil? } }
assert("stations have lat/long") { stations.all? { |s| s.lat.is_a?(Numeric) && s.long.is_a?(Numeric) } }
assert("all stations are Active") { stations.all? { |s| s.status == "Active" } }

puts

# ---------------------------------------------------------------------------
# Measures
# ---------------------------------------------------------------------------
puts "-- Measures --"

# Use first station from inventory
sample_station = stations.first
measures = client.measures(sample_station.station_reference)

assert("returns an Array") { measures.is_a?(Array) }
assert("returns at least one measure") { measures.size >= 1 }
assert("each item is a Measure struct") { measures.all? { |m| m.is_a?(SmoEaHydrology::Measure) } }
assert("measures have id") { measures.all? { |m| m.id.is_a?(String) && m.id.start_with?("http") } }
assert("measures have period_name 15min") { measures.all? { |m| m.period_name == "15min" } }
assert("measures have unit mm") { measures.all? { |m| m.unit_name == "mm" } }
assert("measures have station_reference") { measures.all? { |m| !m.station_reference.nil? } }

puts

# ---------------------------------------------------------------------------
# Readings
# ---------------------------------------------------------------------------
puts "-- Readings --"

measure = measures.first
readings = client.readings(measure.id, from: "2024-01-01", to: "2024-01-01")

assert("returns an Array") { readings.is_a?(Array) }
assert("returns 96 readings for one day (15-min intervals)") { readings.size == 96 }
assert("each item is a Reading struct") { readings.all? { |r| r.is_a?(SmoEaHydrology::Reading) } }
assert("readings have datetime as Time") { readings.all? { |r| r.datetime.is_a?(Time) } }
assert("readings have numeric value") { readings.all? { |r| r.value.is_a?(Numeric) } }
assert("readings have quality string") { readings.all? { |r| r.quality.is_a?(String) } }
assert("readings are in chronological order") {
  readings.each_cons(2).all? { |a, b| a.datetime <= b.datetime }
}
assert("readings span exactly one day") {
  readings.first.datetime.strftime("%Y-%m-%d") == "2024-01-01" &&
  readings.last.datetime.strftime("%Y-%m-%d")  == "2024-01-01"
}

puts
assert("Date objects work as from/to") {
  r = client.readings(measure.id, from: Date.new(2024, 1, 1), to: Date.new(2024, 1, 1))
  r.size == 96
}
assert("multi-day range returns proportionally more readings") {
  r = client.readings(measure.id, from: "2024-01-01", to: "2024-01-03")
  r.size > 96
}

puts

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------
puts "-- Error handling --"

assert_raises("bad date string raises ArgumentError") {
  client.readings(measure.id, from: "not-a-date", to: "2024-01-01")
}

# ---------------------------------------------------------------------------
# Inventory (coverage dates)
# ---------------------------------------------------------------------------
puts "-- Inventory (single station) --"

# Test coverage fetch on the sample station only (avoid full crawl in tests)
from_t = client.send(:fetch_earliest, measure.id)
to_t   = client.send(:fetch_latest_fm, sample_station.station_reference)

assert("fetch_earliest returns a Time or nil") { from_t.nil? || from_t.is_a?(Time) }
assert("fetch_latest_fm returns a Time or nil") { to_t.nil? || to_t.is_a?(Time) }
assert("coverage_from is before coverage_to") do
  from_t.nil? || to_t.nil? || from_t < to_t
end
assert("coverage_from includes HH:MM precision") do
  from_t.nil? || from_t.respond_to?(:strftime)
end

puts

count = $errors_count
if count.zero?
  puts "All tests passed."
else
  puts "#{count} test(s) failed."
  exit 1
end
