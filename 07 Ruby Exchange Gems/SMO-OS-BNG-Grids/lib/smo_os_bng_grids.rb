# frozen_string_literal: true

require_relative "smo_os_bng_grids/version"
require_relative "smo_os_bng_grids/constants"
require_relative "smo_os_bng_grids/data/grid_100km"
require_relative "smo_os_bng_grids/data/grid_50km"
require_relative "smo_os_bng_grids/data/grid_10km"
require_relative "smo_os_bng_grids/data/grid_5km"
require_relative "smo_os_bng_grids/grid"
require_relative "smo_os_bng_grids/lister"
require_relative "smo_os_bng_grids/shapefile_writer"

module SmoOsBngGrids
  # Convenience shortcuts.
  def self.ref_at(easting, northing, resolution: "10km")
    Grid.ref_at(easting, northing, resolution: resolution)
  end

  def self.bounds(bng_ref)
    Grid.bounds(bng_ref)
  end

  def self.valid?(bng_ref)
    Grid.valid?(bng_ref)
  end

  def self.find(easting, northing)
    Lister.new.find(easting, northing)
  end
end
