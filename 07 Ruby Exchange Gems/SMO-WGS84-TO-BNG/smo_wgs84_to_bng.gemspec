require_relative "lib/smo_wgs84_to_bng/version"

Gem::Specification.new do |spec|
  spec.name          = "smo_wgs84_to_bng"
  spec.version       = SmoWgs84ToBng::VERSION
  spec.authors       = ["Sebastian Madrid Ontiveros"]
  spec.email         = ["sebasmadrid20@hotmail.com"]
  spec.summary       = "Convert between WGS84 lat/lon and OSGB36 British National Grid using Helmert transformation"
  spec.description   = "Developed by Sebastian Madrid Ontiveros with a focus on compatibility with " \
                       "InfoWorks ICM 2027, to streamline automation processes in the UK water industry. " \
                       "A pure Ruby gem for converting coordinates between WGS84 (GPS latitude/longitude) " \
                       "and OSGB36 British National Grid (easting/northing). Uses a 7-parameter Helmert " \
                       "transformation with approximately 3-5 metre accuracy across Great Britain. " \
                       "No external dependencies. " \
                       "If you find this gem useful and would like to support its development, " \
                       "please consider donating at https://buymeacoffee.com/smadrid"
  spec.homepage      = "https://github.com/Sebasmadridmx/SMO-WGS84-TO-BNG"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "rake",     "~> 13.0"
end
