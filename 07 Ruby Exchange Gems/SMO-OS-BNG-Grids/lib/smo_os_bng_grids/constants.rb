# frozen_string_literal: true

module SmoOsBngGrids
  # EPSG:27700 - British National Grid (OSGB36)
  CRS_WKT = 'PROJCS["British_National_Grid",' \
            'GEOGCS["GCS_OSGB_1936",' \
            'DATUM["D_OSGB_1936",' \
            'SPHEROID["Airy_1830",6377563.396,299.3249646]],' \
            'PRIMEM["Greenwich",0.0],' \
            'UNIT["Degree",0.0174532925199433]],' \
            'PROJECTION["Transverse_Mercator"],' \
            'PARAMETER["False_Easting",400000.0],' \
            'PARAMETER["False_Northing",-100000.0],' \
            'PARAMETER["Central_Meridian",-2.0],' \
            'PARAMETER["Scale_Factor",0.9996012717],' \
            'PARAMETER["Latitude_Of_Origin",49.0],' \
            'UNIT["Meter",1.0]]'

  OGL_ATTRIBUTION = "Contains OS data. Crown copyright and database right 2025. " \
                    "Licensed under the Open Government Licence v3.0. " \
                    "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"

  VALID_RESOLUTIONS = %w[100km 50km 10km 5km 1km].freeze

  RESOLUTION_SIZE = {
    "100km" => 100_000,
    "50km"  =>  50_000,
    "10km"  =>  10_000,
    "5km"   =>   5_000,
    "1km"   =>   1_000
  }.freeze

  QUADRANTS = %w[SW SE NW NE].freeze

  MSG_INVALID_RESOLUTION = "Unknown resolution %s. Valid: #{VALID_RESOLUTIONS.join(', ')}"
  MSG_PROVIDE_RADIUS_OR_BOX = "Provide radius: or box: (not both)"

  # Quadrant offsets [easting_offset, northing_offset] from parent SW corner.
  QUADRANT_OFFSETS = {
    "SW" => [0,      0],
    "SE" => [1,      0],
    "NW" => [0,      1],
    "NE" => [1,      1]
  }.freeze
end
