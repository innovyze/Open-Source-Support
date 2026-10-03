module SmoWgs84ToBng
  module Constants
    # WGS84 ellipsoid (GRS80, used by GPS)
    WGS84_A = 6378137.000
    WGS84_B = 6356752.3142
    WGS84_E2 = 1 - (WGS84_B**2 / WGS84_A**2)

    # Airy 1830 ellipsoid (used by OSGB36)
    AIRY_A = 6377563.396
    AIRY_B = 6356256.909
    AIRY_E2 = 1 - (AIRY_B**2 / AIRY_A**2)

    # Helmert transformation parameters: WGS84 -> OSGB36
    # Translation in metres, rotations in radians, scale in ppm
    TX = -446.448
    TY =  125.157
    TZ = -542.060
    RX = (-0.1502 / 3600) * Math::PI / 180
    RY = (-0.2470 / 3600) * Math::PI / 180
    RZ = (-0.8421 / 3600) * Math::PI / 180
    S  =  20.4894 / 1_000_000

    # National Grid Transverse Mercator projection parameters
    NG_F0   = 0.9996012717
    NG_LAT0 = 49.0 * Math::PI / 180
    NG_LON0 = -2.0 * Math::PI / 180
    NG_E0   = 400_000.0
    NG_N0   = -100_000.0
  end
end
