require "smo_scottish_lidar"

# Download a single specific tile by filename.
# Change these three values to what you need.
PHASE       = "phase-1"
TYPE        = "dsm"
FILENAME    = "NS56_1M_DSM_PHASE1.tif"
DESTINATION = "/tmp/lidar/single"

downloader = SmoScottishLidar::Downloader.new(verbose: true)
downloader.download_file(PHASE, TYPE, FILENAME, destination: DESTINATION)
