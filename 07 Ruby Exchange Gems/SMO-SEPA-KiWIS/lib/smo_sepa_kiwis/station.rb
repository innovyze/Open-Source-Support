module SmoSepaKiwis
  Station = Struct.new(
    :no, :name, :lat, :lon, :catchment, :river,
    keyword_init: true
  )
end
