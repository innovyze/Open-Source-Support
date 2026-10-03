require "smo_scottish_lidar"

# outer-hebrides DTM - Digital Terrain Model
# Grid square filter: set to nil for all, or e.g. "NS", "NT", "NO"
# resolution: "25cm", "50cm" for dsm/dtm. "4ppm", "16ppm" for laz.
GRID_SQUARE = nil

lister = SmoScottishLidar::Lister.new
lister.summary("outer-hebrides", "dtm", grid_square: GRID_SQUARE, resolution: "25cm")

# Uncomment to download:
# downloader = SmoScottishLidar::Downloader.new
# downloader.download("outer-hebrides", "dtm",
#   destination: "/tmp/lidar/outer-hebrides/dtm",
#   resolution: "25cm",
#   grid_square: GRID_SQUARE,
#   dry_run: false
# )
