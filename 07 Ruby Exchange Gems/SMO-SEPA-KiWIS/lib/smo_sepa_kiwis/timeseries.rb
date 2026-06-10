module SmoSepaKiwis
  Timeseries = Struct.new(
    :ts_id, :ts_path, :ts_name, :station_no, :coverage_from, :coverage_to,
    keyword_init: true
  )
end
