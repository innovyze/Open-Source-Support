require_relative "test_helper"

class TestValidator < Minitest::Test
  # -- Forward validation --

  def test_missing_id_raises
    err = assert_raises(SmoWgs84ToBng::MissingIdError) do
      SmoWgs84ToBng.convert_to_hash(id: nil, lat: 51.5, lon: -0.1)
    end
    assert_match(/id is required/, err.message)
  end

  def test_missing_lat_raises
    err = assert_raises(SmoWgs84ToBng::MissingCoordinateError) do
      SmoWgs84ToBng.convert_to_hash(id: 'X', lat: nil, lon: -0.1)
    end
    assert_match(/lat is required/, err.message)
  end

  def test_missing_lon_raises
    err = assert_raises(SmoWgs84ToBng::MissingCoordinateError) do
      SmoWgs84ToBng.convert_to_hash(id: 'X', lat: 51.5, lon: nil)
    end
    assert_match(/lon is required/, err.message)
  end

  def test_non_numeric_lat_raises
    err = assert_raises(SmoWgs84ToBng::InvalidCoordinateError) do
      SmoWgs84ToBng.convert_to_hash(id: 'X', lat: "fifty-one", lon: -0.1)
    end
    assert_match(/lat must be numeric/, err.message)
  end

  def test_non_numeric_lon_raises
    err = assert_raises(SmoWgs84ToBng::InvalidCoordinateError) do
      SmoWgs84ToBng.convert_to_hash(id: 'X', lat: 51.5, lon: "zero")
    end
    assert_match(/lon must be numeric/, err.message)
  end

  def test_lat_out_of_bounds_raises
    err = assert_raises(SmoWgs84ToBng::OutOfBoundsError) do
      SmoWgs84ToBng.convert_to_hash(id: 'X', lat: 48.0, lon: -0.1)
    end
    assert_match(/lat.*outside GB bounds/, err.message)
  end

  def test_lon_out_of_bounds_raises
    err = assert_raises(SmoWgs84ToBng::OutOfBoundsError) do
      SmoWgs84ToBng.convert_to_hash(id: 'X', lat: 51.5, lon: 5.0)
    end
    assert_match(/lon.*outside GB bounds/, err.message)
  end

  # -- Reverse validation --

  def test_reverse_missing_id_raises
    err = assert_raises(SmoWgs84ToBng::MissingIdError) do
      SmoWgs84ToBng.reverse_to_hash(id: nil, easting: 538885, northing: 177322)
    end
    assert_match(/id is required/, err.message)
  end

  def test_reverse_missing_easting_raises
    err = assert_raises(SmoWgs84ToBng::MissingCoordinateError) do
      SmoWgs84ToBng.reverse_to_hash(id: 'X', easting: nil, northing: 177322)
    end
    assert_match(/easting is required/, err.message)
  end

  def test_reverse_missing_northing_raises
    err = assert_raises(SmoWgs84ToBng::MissingCoordinateError) do
      SmoWgs84ToBng.reverse_to_hash(id: 'X', easting: 538885, northing: nil)
    end
    assert_match(/northing is required/, err.message)
  end

  def test_easting_out_of_bounds_raises
    err = assert_raises(SmoWgs84ToBng::OutOfBoundsError) do
      SmoWgs84ToBng.reverse_to_hash(id: 'X', easting: 800000, northing: 177322)
    end
    assert_match(/easting.*outside GB bounds/, err.message)
  end

  def test_northing_out_of_bounds_raises
    err = assert_raises(SmoWgs84ToBng::OutOfBoundsError) do
      SmoWgs84ToBng.reverse_to_hash(id: 'X', easting: 538885, northing: 1400000)
    end
    assert_match(/northing.*outside GB bounds/, err.message)
  end

  # -- Batch error index reporting --

  def test_batch_missing_id_reports_index
    pts = [
      { id: 'GOOD', lat: 51.5, lon: -0.1 },
      { id: 'GOOD2', lat: 51.5, lon: -0.1 },
      { id: nil,    lat: 51.5, lon: -0.1 }
    ]
    err = assert_raises(SmoWgs84ToBng::MissingIdError) do
      SmoWgs84ToBng.convert_many_to_hash(pts)
    end
    assert_match(/index 2/, err.message)
  end

  def test_batch_out_of_bounds_reports_index
    pts = [
      { id: 'A', lat: 51.5, lon: -0.1 },
      { id: 'B', lat: 20.0, lon: -0.1 }
    ]
    err = assert_raises(SmoWgs84ToBng::OutOfBoundsError) do
      SmoWgs84ToBng.convert_many_to_hash(pts)
    end
    assert_match(/index 1/, err.message)
  end
end
