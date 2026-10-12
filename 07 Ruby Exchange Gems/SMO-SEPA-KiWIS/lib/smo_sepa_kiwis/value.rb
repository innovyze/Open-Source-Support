module SmoSepaKiwis
  Value = Struct.new(
    :timestamp, :value, :quality_code,
    keyword_init: true
  )
end
