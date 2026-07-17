# frozen_string_literal: true

module SmoEaHydrology
  Station = Struct.new(
    :id,                # full URI @id
    :label,             # station name
    :station_reference, # e.g. "589359"
    :wiski_id,          # WISKI system ID
    :easting,           # OSGB36 easting
    :northing,          # OSGB36 northing
    :lat,               # WGS84 latitude
    :long,              # WGS84 longitude
    :date_opened,       # e.g. "1990-10-04"
    :status,            # "Active" / "Closed"
    :measure_id,        # full URI of the 15-min rainfall measure
    :measure_label,     # human-readable measure description
    :coverage_from,     # Time of earliest available reading (nil if not fetched)
    :coverage_to,       # Time of latest available reading (nil if not fetched)
    keyword_init: true
  ) do
    def coverage_from_s
      coverage_from&.strftime("%Y-%m-%d %H:%M") || "unknown"
    end

    def coverage_to_s
      coverage_to&.strftime("%Y-%m-%d %H:%M") || "unknown"
    end
  end
end
