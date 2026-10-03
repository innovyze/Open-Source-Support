require "smo_scottish_lidar"

# Phase 1 DSM - Digital Surface Model
# Grid square filter: change to nil to list all, or e.g. "NS", "NT", "NO"
GRID_SQUARE = nil

lister = SmoScottishLidar::Lister.new
lister.summary("phase-1", "dsm", grid_square: GRID_SQUARE)

# Uncomment to download:
# downloader = SmoScottishLidar::Downloader.new
# downloader.download("phase-1", "dsm",
#   destination: "/tmp/lidar/phase-1/dsm",
#   grid_square: GRID_SQUARE,
#   dry_run: false
# )
