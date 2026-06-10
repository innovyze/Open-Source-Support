# frozen_string_literal: true

require_relative "lib/smo_ea_hydrology/version"

Gem::Specification.new do |spec|
  spec.name          = "smo_ea_hydrology"
  spec.version       = SmoEaHydrology::VERSION
  spec.authors       = ["Sebastian Madrid Ontiveros"]
  spec.email         = ["sebasmadrid20@hotmail.com"]

  spec.summary       = "Environment Agency Hydrology API client for 15-min rainfall data."
  spec.description   = <<~DESC
    Developed by Sebastian Madrid Ontiveros. Pure Ruby client for the Environment Agency
    Hydrology API (environment.data.gov.uk/hydrology). Fetches active rainfall stations,
    15-minute rainfall measures, and timestamped readings over any date range.
    No external dependencies. Uses only Ruby stdlib (net/http, uri, json, date).
    Built to support hydraulic modelling and flood risk workflows in the UK.
    Compatible with InfoWorks ICM 2027 embedded Ruby.
    If this gem saves you time, consider buying Sebastian a coffee at
    https://buymeacoffee.com/smadrid
  DESC

  spec.homepage      = "https://github.com/Sebasmadridmx/smo_ea_hydrology"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
