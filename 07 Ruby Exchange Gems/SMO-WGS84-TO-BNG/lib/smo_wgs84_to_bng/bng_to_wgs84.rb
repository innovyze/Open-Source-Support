module SmoWgs84ToBng
  module BngToWgs84
    include Constants

    module_function

    # Convert BNG easting/northing (metres) to WGS84 lat/lon (degrees).
    # Returns [lat, lon] rounded to 7 decimal places.
    def convert(easting, northing)
      # Step 1: National Grid -> OSGB36 lat/lon
      lat2, lon2 = ng_to_latlon(easting, northing)

      # Step 2: OSGB36 lat/lon -> OSGB36 cartesian
      x, y, z = Wgs84ToBng.latlon_to_cartesian(lat2, lon2, AIRY_A, AIRY_E2)

      # Step 3: Inverse Helmert OSGB36 -> WGS84 (negate all params)
      xw, yw, zw = Wgs84ToBng.helmert(x, y, z,
                                       -TX, -TY, -TZ,
                                       -RX, -RY, -RZ,
                                       -S)

      # Step 4: WGS84 cartesian -> WGS84 lat/lon
      lat, lon = Wgs84ToBng.cartesian_to_latlon(xw, yw, zw, WGS84_A, WGS84_B, WGS84_E2)

      lat_deg = (lat * 180.0 / Math::PI).round(7)
      lon_deg = (lon * 180.0 / Math::PI).round(7)

      [lat_deg, lon_deg]
    end

    def ng_to_latlon(easting, northing)
      a    = AIRY_A
      b    = AIRY_B
      f0   = NG_F0
      lat0 = NG_LAT0
      lon0 = NG_LON0
      e0   = NG_E0
      n0   = NG_N0
      e2   = AIRY_E2

      n  = (a - b) / (a + b)

      # Iterative solution for latitude from northing
      lat = lat0
      m   = 0.0

      10.times do
        lat = (northing - n0 - m) / (a * f0) + lat
        m   = Wgs84ToBng.meridional_arc(b, f0, n, lat0, lat)
        break if (northing - n0 - m).abs < 0.00001
      end

      sin_lat  = Math.sin(lat)
      cos_lat  = Math.cos(lat)
      tan_lat  = Math.tan(lat)

      nu   = a * f0 / Math.sqrt(1 - e2 * sin_lat**2)
      rho  = a * f0 * (1 - e2) / (1 - e2 * sin_lat**2)**1.5
      eta2 = nu / rho - 1

      tan2 = tan_lat**2
      tan4 = tan_lat**4

      sec_lat = 1.0 / cos_lat

      vii  = tan_lat / (2  * rho * nu)
      viii = tan_lat / (24 * rho * nu**3) * (5 + 3 * tan2 + eta2 - 9 * tan2 * eta2)
      ix   = tan_lat / (720 * rho * nu**5) * (61 + 90 * tan2 + 45 * tan4)
      x_c  = sec_lat / nu
      xi   = sec_lat / (6   * nu**3) * (nu / rho + 2 * tan2)
      xii  = sec_lat / (120 * nu**5) * (5 + 28 * tan2 + 24 * tan4)
      xiia = sec_lat / (5040 * nu**7) * (61 + 662 * tan2 + 1320 * tan4 + 720 * tan_lat**6)

      de = easting - e0
      lat_out = lat - vii * de**2 + viii * de**4 - ix   * de**6
      lon_out = lon0 + x_c * de   - xi   * de**3 + xii  * de**5 - xiia * de**7

      [lat_out, lon_out]
    end
  end
end
