# frozen_string_literal: true

require_relative "lib/smo_flow/version"

Gem::Specification.new do |spec|
  spec.name          = "smo_flow"
  spec.version       = SmoFlow::VERSION
  spec.authors       = ["Sebastian Madrid Ontiveros"]
  spec.email         = ["sebasmadrid20@hotmail.com"]

  spec.summary       = "SMO Flow — subcatchment runoff and flow calculations for Ruby"
  spec.description   = "SMO Flow is a Ruby library created by Sebastian Madrid Ontiveros " \
                       "to help support hydraulic modelling in the UK and around the world. " \
                       "It was developed in response to the lack of hydraulic modelling " \
                       "libraries available for Ruby, with the aim of making subcatchment " \
                       "runoff and flow calculations simpler, clearer, and more accessible. " \
                       "The library provides a developer-friendly way to estimate flow from " \
                       "roads, roofs, permeable areas, foul flow, and trade flow, using the " \
                       "Rational Method and timestep-based calculations. " \
                       "If you find this project useful and would like to support its development, " \
                       "please consider donating: https://buymeacoffee.com/smadrid"

  spec.homepage      = "https://github.com/Sebasmadridmx/SMO-Flow"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Sebasmadridmx/SMO-Flow/tree/main"
  spec.metadata["changelog_uri"]   = "https://github.com/Sebasmadridmx/SMO-Flow/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/Sebasmadridmx/SMO-Flow/issues"

  spec.files         = Dir["lib/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
