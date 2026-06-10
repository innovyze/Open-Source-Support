# frozen_string_literal: true

module SmoEaHydrology
  InventoryEntry = Struct.new(
    :station_reference, # e.g. "589359"
    :station_label,     # station name
    :lat,               # WGS84 latitude
    :long,              # WGS84 longitude
    :easting,           # OSGB36 easting
    :northing,          # OSGB36 northing
    :date_opened,       # e.g. "1990-10-04"
    :measure_id,        # full measure URI
    :period_name,       # "15min"
    :unit_name,         # "mm"
    :value_type,        # "total"
    :coverage_from,     # Time of earliest available reading (nil if unknown)
    :coverage_to,       # Time of latest available reading (nil if unknown)
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
