# frozen_string_literal: true

require_relative "lib/smo_scottish_lidar/version"

Gem::Specification.new do |spec|
  spec.name          = "smo_scottish_lidar"
  spec.version       = SmoScottishLidar::VERSION
  spec.authors       = ["Sebastian Madrid Ontiveros"]
  spec.email         = ["sebasmadrid20@hotmail.com"]

  spec.summary       = "Download Scottish Public Sector LiDAR data from the Registry of Open Data on AWS."
  spec.description   = <<~DESC
    Developed by Sebastian Madrid Ontiveros to support hydraulic modellers in Scotland
    building 1D-2D hydraulic models and flood risk assessments. Provides a pure Ruby
    interface for listing and downloading Scottish Public Sector LiDAR datasets (DSM,
    DTM, LAZ) from the Registry of Open Data on AWS. Supports all survey phases (1-5)
    and Outer Hebrides, OS National Grid square filtering, paginated S3 listing, streamed
    downloads with resume support, and dry-run mode. No external dependencies. Uses only
    Ruby stdlib (net/http, uri, fileutils). If this gem saves you time, consider buying
    Sebastian a coffee at https://buymeacoffee.com/smadrid
  DESC
  spec.homepage      = "https://github.com/Sebasmadridmx/smo_scottish_lidar"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # No runtime dependencies. Uses only Ruby stdlib: net/http, uri, fileutils.
end
