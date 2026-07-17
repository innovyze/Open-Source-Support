# frozen_string_literal: true

module SmoEaHydrology
  Measure = Struct.new(
    :id,                # full URI @id (use this to fetch readings)
    :label,             # human-readable description
    :station_reference, # parent station reference
    :station_label,     # parent station name
    :period_name,       # "15min"
    :unit_name,         # "mm"
    :value_type,        # "total"
    :timeseries_id,     # UUID
    :coverage_from,     # Time of earliest available reading (nil if unknown)
    :coverage_to,       # Time of latest available reading (nil if unknown)
    keyword_init: true
  )
end
