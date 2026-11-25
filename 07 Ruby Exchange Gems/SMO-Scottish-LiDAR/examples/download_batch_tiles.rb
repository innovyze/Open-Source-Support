require "smo_scottish_lidar"

# Batch download tiles with flexible filtering.
# Adjust the options below to match what you need.

# --- Options ---
PHASE        = "phase-1"
TYPE         = "dsm"
DESTINATION  = "/tmp/lidar/batch"

# Filter by OS grid square prefix. Set to nil to download everything.
# Examples: "NS" (all NS tiles), "NT", "NO", nil (all tiles in phase)
GRID_SQUARE  = "NS"

# Set to true to see what would be downloaded without actually downloading.
DRY_RUN      = false

# Set to false to re-download files that already exist locally.
SKIP_EXISTING = true
# ---------------

downloader = SmoScottishLidar::Downloader.new(verbose: false)
results = downloader.download(
  PHASE, TYPE,
  destination:   DESTINATION,
  grid_square:   GRID_SQUARE,
  skip_existing: SKIP_EXISTING,
  dry_run:       DRY_RUN
)

puts
puts "Downloaded : #{results[:downloaded].size} file(s)"
puts "Skipped    : #{results[:skipped].size} file(s)"
puts "Failed     : #{results[:failed].size} file(s)"

# ---- Batch download multiple specific filenames ----
# If you already know the exact tiles you want, list them here:

TILES = %w[
  NS56_1M_DSM_PHASE1.tif
  NS57_1M_DSM_PHASE1.tif
  NS58_1M_DSM_PHASE1.tif
]

# Uncomment the block below to download only those specific tiles:
# puts
# puts "Downloading specific tiles..."
# TILES.each do |filename|
#   downloader.download_file(PHASE, TYPE, filename, destination: DESTINATION)
# end
