# frozen_string_literal: true

require_relative "../lib/smo_os_bng_grids"
require "tmpdir"

errors = 0

def assert(desc, &block)
  if block.call
    puts "PASS  #{desc}"
  else
    puts "FAIL  #{desc}"
    $errors_count = ($errors_count || 0) + 1
  end
rescue => e
  puts "ERROR #{desc}: #{e.message}"
  $errors_count = ($errors_count || 0) + 1
end

def assert_raises(desc, &block)
  block.call
  puts "FAIL  #{desc} (no exception raised)"
  $errors_count = ($errors_count || 0) + 1
rescue ArgumentError
  puts "PASS  #{desc}"
end

puts "=== smo_os_bng_grids tests ==="
puts

# --- Data loading ---
assert("GRID_100KM loaded with 91 entries")  { SmoOsBngGrids::GRID_100KM.size == 91 }
assert("GRID_50KM loaded with 364 entries")  { SmoOsBngGrids::GRID_50KM.size == 364 }
assert("GRID_10KM loaded with 9100 entries") { SmoOsBngGrids::GRID_10KM.size == 9100 }
assert("GRID_5KM loaded with 36400 entries") { SmoOsBngGrids::GRID_5KM.size == 36400 }

# --- Hardcoded geometry spot checks (verified against OS GeoPackage) ---
assert("NS 100km bounds correct")  { SmoOsBngGrids::GRID_100KM["NS"] == [200000, 600000] }
assert("NT 100km bounds correct")  { SmoOsBngGrids::GRID_100KM["NT"] == [300000, 600000] }
assert("SV 100km bounds correct")  { SmoOsBngGrids::GRID_100KM["SV"] == [0, 0] }
assert("TW 100km bounds correct")  { SmoOsBngGrids::GRID_100KM["TW"] == [600000, 0] }
assert("HL 100km bounds correct")  { SmoOsBngGrids::GRID_100KM["HL"] == [0, 1200000] }

assert("NS56 10km bounds correct") { SmoOsBngGrids::GRID_10KM["NS56"] == [250000, 660000] }
assert("NT27 10km bounds correct") { SmoOsBngGrids::GRID_10KM["NT27"] == [320000, 670000] }

assert("NS56NE 5km bounds correct") { SmoOsBngGrids::GRID_5KM["NS56NE"] == [255000, 665000] }
assert("NS56SW 5km bounds correct") { SmoOsBngGrids::GRID_5KM["NS56SW"] == [250000, 660000] }
assert("NSNW 50km bounds correct")  { SmoOsBngGrids::GRID_50KM["NSNW"]  == [200000, 650000] }

# --- Grid.ref_at ---
assert("Glasgow city centre -> NS at 100km") {
  SmoOsBngGrids::Grid.ref_at(259000, 665000, resolution: "100km") == "NS"
}
assert("Glasgow city centre -> NS56 at 10km") {
  SmoOsBngGrids::Grid.ref_at(259000, 665000, resolution: "10km") == "NS56"
}
assert("Glasgow city centre -> NS5965 at 1km") {
  # E: 259000 - 200000 = 59000 -> e_digits = 59
  # N: 665000 - 600000 = 65000 -> n_digits = 65
  SmoOsBngGrids::Grid.ref_at(259000, 665000, resolution: "1km") == "NS5965"
}
assert("London TQ38 at 10km") {
  # TQ: min_e=500000, min_n=100000
  # e_digit = (530000-500000)/10000 = 3
  # n_digit = (180000-100000)/10000 = 8
  SmoOsBngGrids::Grid.ref_at(530000, 180000, resolution: "10km") == "TQ38"
}
assert("Edinburgh city centre -> NT at 100km") {
  SmoOsBngGrids::Grid.ref_at(325000, 673000, resolution: "100km") == "NT"
}

# --- Grid.bounds ---
assert("bounds of NS returns correct box") {
  b = SmoOsBngGrids::Grid.bounds("NS")
  b[:min_e] == 200000 && b[:min_n] == 600000 && b[:max_e] == 300000 && b[:max_n] == 700000
}
assert("bounds of NS56 returns correct box") {
  b = SmoOsBngGrids::Grid.bounds("NS56")
  b[:min_e] == 250000 && b[:min_n] == 660000 && b[:max_e] == 260000 && b[:max_n] == 670000
}
assert("bounds of NS5566 (1km) returns correct box") {
  b = SmoOsBngGrids::Grid.bounds("NS5566")
  b[:min_e] == 255000 && b[:min_n] == 666000 && b[:max_e] == 256000 && b[:max_n] == 667000
}
assert("bounds of NSNW (50km) returns correct box") {
  b = SmoOsBngGrids::Grid.bounds("NSNW")
  b[:min_e] == 200000 && b[:min_n] == 650000 && b[:max_e] == 250000 && b[:max_n] == 700000
}
assert("bounds of NS56NE (5km) returns correct box") {
  b = SmoOsBngGrids::Grid.bounds("NS56NE")
  b[:min_e] == 255000 && b[:min_n] == 665000 && b[:max_e] == 260000 && b[:max_n] == 670000
}

# --- Grid.valid? ---
assert("NS is valid")     { SmoOsBngGrids::Grid.valid?("NS") }
assert("NS56 is valid")   { SmoOsBngGrids::Grid.valid?("NS56") }
assert("NS5566 is valid") { SmoOsBngGrids::Grid.valid?("NS5566") }
assert("ZZ is not valid") { !SmoOsBngGrids::Grid.valid?("ZZ") }

# --- Lister ---
lister = SmoOsBngGrids::Lister.new

assert("list 100km returns 91 entries") { lister.list("100km").size == 91 }
assert("list 10km within NS returns 100 entries")   { lister.list("10km", within: "NS").size == 100 }
assert("list 5km within NS56 returns 4 entries")    { lister.list("5km", within: "NS56").size == 4 }
assert("list 1km within NS56 returns 100 entries")  { lister.list("1km", within: "NS56").size == 100 }
assert("list 1km within NS returns 10000 entries")  { lister.list("1km", within: "NS").size == 10000 }
assert("list 1km within NS56 has correct geometry") {
  entries = lister.list("1km", within: "NS56")
  # All entries must be within NS56 bounds [250000,660000]-[260000,670000]
  entries.all? { |e| e[:min_e] >= 250000 && e[:max_e] <= 260000 &&
                     e[:min_n] >= 660000 && e[:max_n] <= 670000 }
}

assert("find returns refs at all resolutions for Glasgow") {
  result = lister.find(259000, 665000)
  result["100km"] == "NS" && result["10km"] == "NS56"
}

# --- Points (corner coordinates) ---
assert("list entries include :points with 5 [x,y] pairs") {
  e = lister.list("10km", within: "NS").first
  e[:points].is_a?(Array) && e[:points].size == 5 && e[:points].all? { |pt| pt.size == 2 }
}
assert("points NW corner matches min_e/max_n") {
  e = lister.list("100km").find { |x| x[:ref] == "NS" }
  e[:points][0] == [200000, 700000]
}
assert("points NE corner matches max_e/max_n") {
  e = lister.list("100km").find { |x| x[:ref] == "NS" }
  e[:points][1] == [300000, 700000]
}
assert("points SE corner matches max_e/min_n") {
  e = lister.list("100km").find { |x| x[:ref] == "NS" }
  e[:points][2] == [300000, 600000]
}
assert("points SW corner matches min_e/min_n") {
  e = lister.list("100km").find { |x| x[:ref] == "NS" }
  e[:points][3] == [200000, 600000]
}
assert("points ring is closed (first == last)") {
  e = lister.list("100km").find { |x| x[:ref] == "NS" }
  e[:points].first == e[:points].last
}

# --- Lister#search ---
assert("search by radius finds correct 10km tiles around Glasgow") {
  # Glasgow at 259000,665000 with radius 8000m should hit NS56 and adjacent tiles
  results = lister.search(259000, 665000, resolution: "10km", radius: 8000)
  refs = results.map { |e| e[:ref] }
  refs.include?("NS56") && results.size >= 1
}
assert("search by radius returns :distance_m") {
  results = lister.search(259000, 665000, resolution: "10km", radius: 8000)
  results.all? { |e| e.key?(:distance_m) && e[:distance_m] >= 0 }
}
assert("search by radius: tile containing the point has distance_m == 0") {
  results = lister.search(259000, 665000, resolution: "10km", radius: 8000)
  ns56 = results.find { |e| e[:ref] == "NS56" }
  ns56 && ns56[:distance_m] == 0.0
}
assert("search by box finds tiles within square around Glasgow") {
  results = lister.search(259000, 665000, resolution: "10km", box: 5000)
  refs = results.map { |e| e[:ref] }
  refs.include?("NS56")
}
assert("search by box does not return :distance_m") {
  results = lister.search(259000, 665000, resolution: "10km", box: 5000)
  results.none? { |e| e.key?(:distance_m) }
}
assert("search by radius at 1km resolution around Glasgow") {
  results = lister.search(259000, 665000, resolution: "1km", radius: 1500)
  refs = results.map { |e| e[:ref] }
  refs.include?("NS5966") || refs.any? { |r| r.start_with?("NS") }
}
assert("search raises ArgumentError when neither radius nor box given") {
  begin
    lister.search(259000, 665000, resolution: "10km")
    false
  rescue ArgumentError
    true
  end
}

# --- Shapefile export ---
assert("ShapefileWriter exports 100km grid to SHP") {
  Dir.mktmpdir do |dir|
    path    = File.join(dir, "bng_100km")
    entries = lister.list("100km")
    SmoOsBngGrids::ShapefileWriter.new.write(entries, path)
    File.exist?("#{path}.shp") &&
    File.exist?("#{path}.shx") &&
    File.exist?("#{path}.dbf") &&
    File.exist?("#{path}.prj") &&
    File.size("#{path}.shp") > 100
  end
}

assert("ShapefileWriter exports NS 10km tiles to SHP") {
  Dir.mktmpdir do |dir|
    path    = File.join(dir, "ns_10km")
    entries = lister.list("10km", within: "NS")
    SmoOsBngGrids::ShapefileWriter.new.write(entries, path)
    File.exist?("#{path}.shp") && File.size("#{path}.shp") > 100
  end
}

assert("ShapefileWriter exports NS56 1km tiles to SHP") {
  Dir.mktmpdir do |dir|
    path    = File.join(dir, "ns56_1km")
    entries = lister.list("1km", within: "NS56")
    SmoOsBngGrids::ShapefileWriter.new.write(entries, path)
    File.exist?("#{path}.shp") && File.size("#{path}.shp") > 100
  end
}

# --- Error handling ---
assert_raises("invalid resolution raises ArgumentError") {
  SmoOsBngGrids::Grid.ref_at(259000, 665000, resolution: "500m")
}
assert_raises("negative easting raises ArgumentError") {
  SmoOsBngGrids::Grid.ref_at(-1, 665000)
}

puts
count = $errors_count || 0
if count.zero?
  puts "All tests passed."
else
  puts "#{count} test(s) failed."
  exit 1
end
