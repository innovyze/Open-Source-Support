# frozen_string_literal: true

require_relative "../lib/smo_scottish_lidar"

# Minimal inline tests - no test framework dependency.
# Run with: ruby spec/smo_scottish_lidar_spec.rb

errors = []

def assert(description, &block)
  condition = block.call
  if condition
    puts "PASS  #{description}"
  else
    puts "FAIL  #{description}"
    $errors_count = ($errors_count || 0) + 1
  end
end

def assert_raises(description, &block)
  block.call
  puts "FAIL  #{description} (no exception raised)"
  $errors_count = ($errors_count || 0) + 1
rescue ArgumentError
  puts "PASS  #{description}"
end

puts "=== smo_scottish_lidar unit tests ==="
puts

# --- Constants / prefix builder ---

assert "phase-1 DSM prefix" do
  SmoScottishLidar.prefix_for("phase-1", "dsm") == "lidar/phase-1/dsm/27700/gridded/"
end

assert "phase-5 LAZ prefix" do
  SmoScottishLidar.prefix_for("phase-5", "laz") == "lidar/phase-5/laz/27700/gridded/"
end

assert "outer-hebrides DTM 50cm prefix" do
  SmoScottishLidar.prefix_for("outer-hebrides", "dtm", resolution: "50cm") ==
    "lidar/outer-hebrides/2019/dtm/50cm/27700/gridded/"
end

assert "outer-hebrides DSM defaults to 25cm" do
  SmoScottishLidar.prefix_for("outer-hebrides", "dsm") ==
    "lidar/outer-hebrides/2019/dsm/25cm/27700/gridded/"
end

assert "outer-hebrides LAZ defaults to 4ppm" do
  SmoScottishLidar.prefix_for("outer-hebrides", "laz") ==
    "lidar/outer-hebrides/2019/laz/4ppm/27700/gridded/"
end

assert_raises "invalid phase raises ArgumentError" do
  SmoScottishLidar.prefix_for("phase-99", "dsm")
end

assert_raises "invalid type raises ArgumentError" do
  SmoScottishLidar.prefix_for("phase-1", "xyz")
end

assert_raises "invalid outer-hebrides resolution raises ArgumentError" do
  SmoScottishLidar.prefix_for("outer-hebrides", "dtm", resolution: "1m")
end

# --- Version ---
assert "version is a string" do
  SmoScottishLidar::VERSION.is_a?(String)
end

assert "version format x.y.z" do
  SmoScottishLidar::VERSION.match?(/\A\d+\.\d+\.\d+\z/)
end

# --- Client instantiation ---
assert "Client instantiates without error" do
  SmoScottishLidar::Client.new
  true
end

assert "Lister instantiates without error" do
  SmoScottishLidar::Lister.new
  true
end

assert "Downloader instantiates without error" do
  SmoScottishLidar::Downloader.new
  true
end

puts
errors_count = $errors_count || 0
if errors_count.zero?
  puts "All tests passed."
else
  puts "#{errors_count} test(s) failed."
  exit 1
end
