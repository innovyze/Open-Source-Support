require_relative "test_helper"

class TestBngToWgs84 < Minitest::Test
  # Reference point accuracy: within 0.0001 degrees (~11 m, generous for Helmert)
  REFERENCE_POINTS.each do |pt|
    define_method("test_reverse_#{pt[:id].downcase}") do
      result = SmoWgs84ToBng.reverse_to_hash(id: pt[:id], easting: pt[:easting], northing: pt[:northing])
      assert_in_delta pt[:lat], result[:lat], 0.0001,
        "#{pt[:id]} lat: expected ~#{pt[:lat]}, got #{result[:lat]}"
      assert_in_delta pt[:lon], result[:lon], 0.0001,
        "#{pt[:id]} lon: expected ~#{pt[:lon]}, got #{result[:lon]}"
    end
  end

  # hash output format
  def test_reverse_to_hash_keys
    result = SmoWgs84ToBng.reverse_to_hash(id: 'TEST', easting: 538885, northing: 177322)
    assert_equal [:id, :lat, :lon], result.keys
  end

  # extra keys preserved in hash
  def test_reverse_to_hash_preserves_extra_keys
    result = SmoWgs84ToBng.reverse_to_hash(id: 'T', easting: 538885, northing: 177322, note: 'x')
    assert_equal 'x', result[:note]
  end

  # array output
  def test_reverse_to_array
    result = SmoWgs84ToBng.reverse_to_array(id: 'T', easting: 538885, northing: 177322)
    assert_equal 3, result.length
    assert_equal 'T', result[0]
  end

  # json output
  def test_reverse_to_json
    json = SmoWgs84ToBng.reverse_to_json(id: 'T', easting: 538885, northing: 177322)
    parsed = JSON.parse(json)
    assert parsed.key?('lat')
    assert parsed.key?('lon')
  end

  # batch hash
  def test_reverse_many_to_hash
    pts = REFERENCE_POINTS.map { |p| { id: p[:id], easting: p[:easting], northing: p[:northing] } }
    results = SmoWgs84ToBng.reverse_many_to_hash(pts)
    assert_equal 4, results.length
    results.each { |r| assert r.key?(:lat) }
  end

  # batch array
  def test_reverse_many_to_array
    pts = REFERENCE_POINTS.map { |p| { id: p[:id], easting: p[:easting], northing: p[:northing] } }
    results = SmoWgs84ToBng.reverse_many_to_array(pts)
    assert_equal 4, results.length
    results.each { |r| assert_equal 3, r.length }
  end

  # batch json
  def test_reverse_many_to_json
    pts = REFERENCE_POINTS.map { |p| { id: p[:id], easting: p[:easting], northing: p[:northing] } }
    json = SmoWgs84ToBng.reverse_many_to_json(pts)
    parsed = JSON.parse(json)
    assert_equal 4, parsed.length
  end
end
