module SmoWgs84ToBng
  module Validator
    LAT_MIN  =   49.0
    LAT_MAX  =   61.0
    LON_MIN  =   -8.5
    LON_MAX  =    2.0
    E_MIN    =    0.0
    E_MAX    = 700_000.0
    N_MIN    =    0.0
    N_MAX    = 1_300_000.0

    MSG_ID_REQUIRED      = "id is required"
    MSG_REQUIRED         = "%s is required"
    MSG_MUST_BE_NUMERIC  = "%s must be numeric"
    MSG_OUTSIDE_BOUNDS   = "%s %s is outside GB bounds (%s..%s)"

    module_function

    def validate_wgs84!(id:, lat:, lon:, index: nil)
      ctx = index ? " for point at index #{index}" : ""

      raise MissingIdError, "#{MSG_ID_REQUIRED}#{ctx}" if id.nil?

      raise MissingCoordinateError, "#{format(MSG_REQUIRED, 'lat')}#{ctx}" if lat.nil?
      raise MissingCoordinateError, "#{format(MSG_REQUIRED, 'lon')}#{ctx}" if lon.nil?

      unless numeric?(lat)
        raise InvalidCoordinateError, "#{format(MSG_MUST_BE_NUMERIC, 'lat')}#{ctx}"
      end
      unless numeric?(lon)
        raise InvalidCoordinateError, "#{format(MSG_MUST_BE_NUMERIC, 'lon')}#{ctx}"
      end

      lat_f = lat.to_f
      lon_f = lon.to_f

      unless lat_f.between?(LAT_MIN, LAT_MAX)
        raise OutOfBoundsError, "#{format(MSG_OUTSIDE_BOUNDS, 'lat', lat_f, LAT_MIN, LAT_MAX)}#{ctx}"
      end
      unless lon_f.between?(LON_MIN, LON_MAX)
        raise OutOfBoundsError, "#{format(MSG_OUTSIDE_BOUNDS, 'lon', lon_f, LON_MIN, LON_MAX)}#{ctx}"
      end
    end

    def validate_bng!(id:, easting:, northing:, index: nil)
      ctx = index ? " for point at index #{index}" : ""

      raise MissingIdError, "#{MSG_ID_REQUIRED}#{ctx}" if id.nil?

      raise MissingCoordinateError, "#{format(MSG_REQUIRED, 'easting')}#{ctx}" if easting.nil?
      raise MissingCoordinateError, "#{format(MSG_REQUIRED, 'northing')}#{ctx}" if northing.nil?

      unless numeric?(easting)
        raise InvalidCoordinateError, "#{format(MSG_MUST_BE_NUMERIC, 'easting')}#{ctx}"
      end
      unless numeric?(northing)
        raise InvalidCoordinateError, "#{format(MSG_MUST_BE_NUMERIC, 'northing')}#{ctx}"
      end

      e_f = easting.to_f
      n_f = northing.to_f

      unless e_f.between?(E_MIN, E_MAX)
        raise OutOfBoundsError, "#{format(MSG_OUTSIDE_BOUNDS, 'easting', e_f, E_MIN, E_MAX)}#{ctx}"
      end
      unless n_f.between?(N_MIN, N_MAX)
        raise OutOfBoundsError, "#{format(MSG_OUTSIDE_BOUNDS, 'northing', n_f, N_MIN, N_MAX)}#{ctx}"
      end
    end

    def numeric?(val)
      val.is_a?(Numeric)
    end
  end
end
