require "smo_scottish_lidar"

# phase-4 DSM - Digital Surface Model
# Grid square filter: set to nil for all, or e.g. "NS", "NT", "NO"
GRID_SQUARE = nil

lister = SmoScottishLidar::Lister.new
lister.summary("phase-4", "dsm", grid_square: GRID_SQUARE)

# Uncomment to download:
# downloader = SmoScottishLidar::Downloader.new
# downloader.download("phase-4", "dsm",
#   destination: "/tmp/lidar/phase-4/dsm",
#   grid_square: GRID_SQUARE,
#   dry_run: false
# )
