require_relative "test_helper"

class TestWgs84ToBng < Minitest::Test
  # Reference point accuracy: within 5 metres
  REFERENCE_POINTS.each do |pt|
    define_method("test_forward_#{pt[:id].downcase}") do
      result = SmoWgs84ToBng.convert_to_hash(id: pt[:id], lat: pt[:lat], lon: pt[:lon])
      assert_in_delta pt[:easting],  result[:easting],  5.0,
        "#{pt[:id]} easting: expected ~#{pt[:easting]}, got #{result[:easting]}"
      assert_in_delta pt[:northing], result[:northing], 5.0,
        "#{pt[:id]} northing: expected ~#{pt[:northing]}, got #{result[:northing]}"
    end
  end

  # hash output format
  def test_convert_to_hash_keys
    result = SmoWgs84ToBng.convert_to_hash(id: 'TEST', lat: 51.4779, lon: -0.0015)
    assert_equal [:id, :easting, :northing], result.keys
  end

  # extra keys preserved in hash
  def test_convert_to_hash_preserves_extra_keys
    result = SmoWgs84ToBng.convert_to_hash(id: 'GULLY', lat: 51.4779, lon: -0.0015, material: 'concrete')
    assert_equal 'concrete', result[:material]
    assert_equal [:id, :easting, :northing, :material], result.keys
  end

  # array output format
  def test_convert_to_array
    result = SmoWgs84ToBng.convert_to_array(id: 'GULLY', lat: 51.4779, lon: -0.0015)
    assert_instance_of Array, result
    assert_equal 3, result.length
    assert_equal 'GULLY', result[0]
    assert_instance_of Float, result[1]
    assert_instance_of Float, result[2]
  end

  # extra keys dropped from array
  def test_convert_to_array_drops_extra_keys
    result = SmoWgs84ToBng.convert_to_array(id: 'GULLY', lat: 51.4779, lon: -0.0015, material: 'concrete')
    assert_equal 3, result.length
  end

  # json output
  def test_convert_to_json
    json = SmoWgs84ToBng.convert_to_json(id: 'GULLY', lat: 51.4779, lon: -0.0015)
    assert_instance_of String, json
    parsed = JSON.parse(json)
    assert parsed.key?('id')
    assert parsed.key?('easting')
    assert parsed.key?('northing')
  end

  # batch hash
  def test_convert_many_to_hash
    pts = REFERENCE_POINTS.map { |p| { id: p[:id], lat: p[:lat], lon: p[:lon] } }
    results = SmoWgs84ToBng.convert_many_to_hash(pts)
    assert_equal 4, results.length
    results.each { |r| assert r.key?(:easting) }
  end

  # batch array
  def test_convert_many_to_array
    pts = REFERENCE_POINTS.map { |p| { id: p[:id], lat: p[:lat], lon: p[:lon] } }
    results = SmoWgs84ToBng.convert_many_to_array(pts)
    assert_equal 4, results.length
    results.each { |r| assert_equal 3, r.length }
  end

  # batch json
  def test_convert_many_to_json
    pts = REFERENCE_POINTS.map { |p| { id: p[:id], lat: p[:lat], lon: p[:lon] } }
    json = SmoWgs84ToBng.convert_many_to_json(pts)
    parsed = JSON.parse(json)
    assert_equal 4, parsed.length
  end

  # batch extra keys preserved
  def test_convert_many_to_hash_preserves_extra_keys
    pts = [{ id: 'P1', lat: 51.4779, lon: -0.0015, material: 'iron' }]
    results = SmoWgs84ToBng.convert_many_to_hash(pts)
    assert_equal 'iron', results[0][:material]
  end

  # batch extra keys dropped from array
  def test_convert_many_to_array_drops_extra_keys
    pts = [{ id: 'P1', lat: 51.4779, lon: -0.0015, material: 'iron' }]
    results = SmoWgs84ToBng.convert_many_to_array(pts)
    assert_equal 3, results[0].length
  end

  # round-trip within 0.5 m
  def test_round_trip_accuracy
    REFERENCE_POINTS.each do |pt|
      e, n = SmoWgs84ToBng::Wgs84ToBng.convert(pt[:lat], pt[:lon])
      lat2, lon2 = SmoWgs84ToBng::BngToWgs84.convert(e, n)
      e2, n2 = SmoWgs84ToBng::Wgs84ToBng.convert(lat2, lon2)
      assert_in_delta e, e2, 0.5, "#{pt[:id]} round-trip easting drift"
      assert_in_delta n, n2, 0.5, "#{pt[:id]} round-trip northing drift"
    end
  end
end
