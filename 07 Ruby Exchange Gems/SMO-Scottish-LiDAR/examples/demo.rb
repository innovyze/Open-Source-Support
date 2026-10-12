require "smo_scottish_lidar"

# -----------------------------------------------------------------------------
# 1. List Phase 1 DSM files for grid square NS
# -----------------------------------------------------------------------------
puts "=" * 60
puts "1. PHASE 1 DSM - GRID SQUARE NS"
puts "=" * 60

lister = SmoScottishLidar::Lister.new
lister.summary("phase-5", "dsm", grid_square: "NS")
puts

# -----------------------------------------------------------------------------
# 2. List Phase 1 DTM files for grid square NT
# -----------------------------------------------------------------------------
puts "=" * 60
puts "2. PHASE 1 DTM - GRID SQUARE NT"
puts "=" * 60

lister.summary("phase-5", "dtm", grid_square: "NT")
puts

# -----------------------------------------------------------------------------
# 3. List all LAZ files for Phase 2
# -----------------------------------------------------------------------------
puts "=" * 60
puts "3. PHASE 2 LAZ - ALL GRID SQUARES"
puts "=" * 60

files = lister.list("phase-5", "laz")
puts "Total LAZ files in Phase 2: #{files.size}"
puts "First 5:"
files.first(5).each { |f| puts "  #{f[:filename]}  (#{f[:size]} bytes)" }
puts

# -----------------------------------------------------------------------------
# 4. Outer Hebrides DSM - default resolution (25cm)
# -----------------------------------------------------------------------------
puts "=" * 60
puts "4. OUTER HEBRIDES DSM - 25cm (default)"
puts "=" * 60

lister.summary("outer-hebrides", "dsm")
puts

# -----------------------------------------------------------------------------
# 5. Outer Hebrides DTM - 50cm resolution
# -----------------------------------------------------------------------------
puts "=" * 60
puts "5. OUTER HEBRIDES DTM - 50cm"
puts "=" * 60

lister.summary("outer-hebrides", "dtm", resolution: "50cm")
puts

# -----------------------------------------------------------------------------
# 6. Dry run download - Phase 1 DSM for NS56
# -----------------------------------------------------------------------------
puts "=" * 60
puts "6. DRY RUN DOWNLOAD - PHASE 5 DSM NS56"
puts "=" * 60

downloader = SmoScottishLidar::Downloader.new
downloader.download(
  "phase-5", "dsm",
  destination: "/tmp/lidar_test",
  grid_square: "NS96",
  dry_run: true
)
puts

# -----------------------------------------------------------------------------
# 7. Prefix builder - all phases and types
# -----------------------------------------------------------------------------
puts "=" * 60
puts "7. PREFIX BUILDER"
puts "=" * 60

%w[phase-1 phase-2 phase-3 phase-4 phase-5].each do |phase|
  %w[dsm dtm laz].each do |type|
    puts "  #{phase} / #{type}: #{SmoScottishLidar.prefix_for(phase, type)}"
  end
end
puts
puts "  outer-hebrides / dsm (25cm): #{SmoScottishLidar.prefix_for('outer-hebrides', 'dsm', resolution: '25cm')}"
puts "  outer-hebrides / dsm (50cm): #{SmoScottishLidar.prefix_for('outer-hebrides', 'dsm', resolution: '50cm')}"
puts "  outer-hebrides / laz (4ppm): #{SmoScottishLidar.prefix_for('outer-hebrides', 'laz', resolution: '4ppm')}"
puts "  outer-hebrides / laz (16ppm): #{SmoScottishLidar.prefix_for('outer-hebrides', 'laz', resolution: '16ppm')}"
puts

puts "=" * 60
puts "All done."
puts "=" * 60
