require "smo_scottish_lidar"

# phase-5 DTM - Digital Terrain Model
# Grid square filter: set to nil for all, or e.g. "NS", "NT", "NO"
GRID_SQUARE = nil

lister = SmoScottishLidar::Lister.new
lister.summary("phase-5", "dtm", grid_square: GRID_SQUARE)

# Uncomment to download:
# downloader = SmoScottishLidar::Downloader.new
# downloader.download("phase-5", "dtm",
#   destination: "/tmp/lidar/phase-5/dtm",
#   grid_square: GRID_SQUARE,
#   dry_run: false
# )
