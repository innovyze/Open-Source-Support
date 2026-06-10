module SmoWgs84ToBng
  module Wgs84ToBng
    include Constants

    module_function

    # Convert WGS84 lat/lon (degrees) to BNG easting/northing (metres).
    # Returns [easting, northing] rounded to 1 decimal place.
    def convert(lat_deg, lon_deg)
      lat = lat_deg * Math::PI / 180.0
      lon = lon_deg * Math::PI / 180.0

      # Step 1: WGS84 lat/lon to WGS84 cartesian
      x, y, z = latlon_to_cartesian(lat, lon, WGS84_A, WGS84_E2)

      # Step 2: Helmert transform WGS84 -> OSGB36
      xo, yo, zo = helmert(x, y, z,
                            TX, TY, TZ,
                            RX, RY, RZ,
                            S)

      # Step 3: OSGB36 cartesian -> OSGB36 lat/lon
      lat2, lon2 = cartesian_to_latlon(xo, yo, zo, AIRY_A, AIRY_B, AIRY_E2)

      # Step 4: OSGB36 lat/lon -> National Grid easting/northing
      easting, northing = latlon_to_ng(lat2, lon2)

      [easting.round(1), northing.round(1)]
    end

    # -- helpers (available as module functions) --

    def latlon_to_cartesian(lat, lon, a, e2)
      sin_lat = Math.sin(lat)
      cos_lat = Math.cos(lat)
      cos_lon = Math.cos(lon)
      sin_lon = Math.sin(lon)

      nu = a / Math.sqrt(1 - e2 * sin_lat**2)

      x = nu * cos_lat * cos_lon
      y = nu * cos_lat * sin_lon
      z = (nu * (1 - e2)) * sin_lat

      [x, y, z]
    end

    def helmert(x, y, z, tx, ty, tz, rx, ry, rz, s)
      # Small-angle approximation (linearised Helmert)
      xo = tx + (1 + s) * x  - rz * y  + ry * z
      yo = ty + rz * x        + (1 + s) * y - rx * z
      zo = tz - ry * x        + rx * y  + (1 + s) * z
      [xo, yo, zo]
    end

    def cartesian_to_latlon(x, y, z, a, b, e2)
      lon  = Math.atan2(y, x)
      p    = Math.sqrt(x**2 + y**2)
      lat  = Math.atan2(z, p * (1 - e2))  # initial estimate

      5.times do
        sin_lat = Math.sin(lat)
        nu = a / Math.sqrt(1 - e2 * sin_lat**2)
        lat_new = Math.atan2(z + e2 * nu * sin_lat, p)
        break if (lat_new - lat).abs < 1e-12
        lat = lat_new
      end

      [lat, lon]
    end

    def latlon_to_ng(lat, lon)
      a   = AIRY_A
      b   = AIRY_B
      f0  = NG_F0
      lat0 = NG_LAT0
      lon0 = NG_LON0
      e0  = NG_E0
      n0  = NG_N0
      e2  = AIRY_E2

      n    = (a - b) / (a + b)
      nu   = a * f0 / Math.sqrt(1 - e2 * Math.sin(lat)**2)
      rho  = a * f0 * (1 - e2) / (1 - e2 * Math.sin(lat)**2)**1.5
      eta2 = nu / rho - 1

      m    = meridional_arc(b, f0, n, lat0, lat)

      cos_lat  = Math.cos(lat)
      sin_lat  = Math.sin(lat)
      tan_lat  = Math.tan(lat)

      i    = m + n0
      ii   = (nu / 2.0)  * sin_lat * cos_lat
      iii  = (nu / 24.0) * sin_lat * cos_lat**3  * (5 - tan_lat**2 + 9 * eta2)
      iiia = (nu / 720.0)* sin_lat * cos_lat**5  * (61 - 58 * tan_lat**2 + tan_lat**4)
      iv   = nu * cos_lat
      v    = (nu / 6.0)  * cos_lat**3 * (nu / rho - tan_lat**2)
      vi   = (nu / 120.0)* cos_lat**5 * (5 - 18 * tan_lat**2 + tan_lat**4 + 14 * eta2 - 58 * tan_lat**2 * eta2)

      dl = lon - lon0
      northing = i  + ii * dl**2 + iii * dl**4 + iiia * dl**6
      easting  = e0 + iv * dl    + v   * dl**3  + vi   * dl**5

      [easting, northing]
    end

    def meridional_arc(b, f0, n, lat0, lat)
      n2 = n**2
      n3 = n**3
      b * f0 * (
        (1 + n + (5.0/4) * n2 + (5.0/4) * n3) * (lat - lat0) -
        (3 * n + 3 * n2 + (21.0/8) * n3) * Math.sin(lat - lat0) * Math.cos(lat + lat0) +
        ((15.0/8) * n2 + (15.0/8) * n3) * Math.sin(2 * (lat - lat0)) * Math.cos(2 * (lat + lat0)) -
        (35.0/24) * n3 * Math.sin(3 * (lat - lat0)) * Math.cos(3 * (lat + lat0))
      )
    end
  end
end
