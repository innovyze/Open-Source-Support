require_relative "lib/smo_sepa_kiwis/version"

Gem::Specification.new do |spec|
  spec.name    = "smo_sepa_kiwis"
  spec.version = SmoSepaKiwis::VERSION
  spec.authors = ["Sebastian Madrid Ontiveros"]
  spec.summary     = "Pure-Ruby client for the SEPA Time Series KiWIS API, " \
                     "developed to save time in hydraulic modelling workflows " \
                     "and interact directly with InfoWorks ICM 2027."
  spec.description = "Developed by Sebastian Madrid Ontiveros. Fetch rainfall " \
                     "stations, 15-minute timeseries, and values from the SEPA " \
                     "KiWIS API. Pure Ruby, stdlib only, no native extensions or " \
                     "external gem dependencies. Compatible with InfoWorks ICM " \
                     "2027 embedded Ruby. Built by a hydraulic modeller to support " \
                     "rainfall data ingestion, 1D-2D model build workflows, and " \
                     "flood risk assessment in the UK. If this gem saves you time, " \
                     "you can support development at https://buymeacoffee.com/smadrid."
  spec.license     = "MIT"
  spec.homepage    = "https://github.com/Sebasmadridmx/smo_sepa_kiwis"

  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]

  # No runtime dependencies. Stdlib only.
end
