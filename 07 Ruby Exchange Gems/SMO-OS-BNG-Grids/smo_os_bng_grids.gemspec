# frozen_string_literal: true

require_relative "lib/smo_os_bng_grids/version"

Gem::Specification.new do |spec|
  spec.name          = "smo_os_bng_grids"
  spec.version       = SmoOsBngGrids::VERSION
  spec.authors       = ["Sebastian Madrid Ontiveros"]
  spec.email         = ["sebasmadrid20@hotmail.com"]

  spec.summary       = "OS BNG grid squares for Ruby. Point lookup, bounds, and Shapefile export."
  spec.description   = <<~DESC
    Developed by Sebastian Madrid Ontiveros. Pure Ruby gem providing all Ordnance Survey
    British National Grid squares (100km, 50km, 10km, 5km, 1km) with hardcoded geometry
    sourced directly from the OS BNG Grids GeoPackage. Supports point-to-grid-ref lookup
    by easting/northing, bounds retrieval, grid square validation, listing with filters,
    and export to ESRI Shapefile format. No external dependencies. Uses only Ruby stdlib.
    Contains OS data. Crown copyright and database right 2025.
    Licensed under the Open Government Licence v3.0.
    Built to support hydraulic modelling and flood risk workflows in the UK.
    If this gem saves you time, consider buying Sebastian a coffee at
    https://buymeacoffee.com/smadrid
  DESC

  spec.homepage      = "https://github.com/Sebasmadridmx/smo_os_bng_grids"
  spec.license       = "OGL-UK-3.0"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
