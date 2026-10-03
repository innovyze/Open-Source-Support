require "smo_scottish_lidar"

# phase-1 LAZ - LiDAR Point Cloud (LAZ)
# Grid square filter: set to nil for all, or e.g. "NS", "NT", "NO"
GRID_SQUARE = nil

lister = SmoScottishLidar::Lister.new
lister.summary("phase-1", "laz", grid_square: GRID_SQUARE)

# Uncomment to download:
# downloader = SmoScottishLidar::Downloader.new
# downloader.download("phase-1", "laz",
#   destination: "/tmp/lidar/phase-1/laz",
#   grid_square: GRID_SQUARE,
#   dry_run: false
# )
