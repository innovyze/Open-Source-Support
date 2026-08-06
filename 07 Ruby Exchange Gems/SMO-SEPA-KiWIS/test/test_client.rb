require_relative "test_helper"
require "tmpdir"

# Stub transport: intercepts request_body to serve fixture files without
# hitting the network. Accepts an ordered queue of fixture names consumed
# one per call; repeats the last name if the queue runs out.
module StubRequest
  def stub_next(*fixture_names)
    @_stub_queue   = fixture_names.dup
    @_stub_default = fixture_names.last
  end

  private

  def request_body(_uri)
    name = @_stub_queue.shift || @_stub_default
    File.read(File.join(FIXTURES_DIR, name))
  end
end

def make_client(*fixture_names)
  c = SmoSepaKiwis::Client.new
  c.extend(StubRequest)
  c.stub_next(*fixture_names)
  c
end

class TestClientRainfallStations < Minitest::Test
  def setup
    @client = make_client("station_list.json")
    @stations = @client.rainfall_stations
  end

  def test_returns_array_of_stations
    assert_instance_of Array, @stations
    assert @stations.all? { |s| s.is_a?(SmoSepaKiwis::Station) }
  end

  def test_station_count
    assert_equal 3, @stations.size
  end

  def test_lat_lon_parsed_to_float
    s = @stations[0]
    assert_instance_of Float, s.lat
    assert_instance_of Float, s.lon
    assert_in_delta 56.36, s.lat
    assert_in_delta(-4.05, s.lon)
  end

  def test_empty_catchment_river_become_nil
    killin = @stations[1]
    assert_nil killin.river
  end

  def test_station_no_is_string
    assert_equal "14964", @stations[0].no
  end

  def test_third_station_fields
    s = @stations[2]
    assert_equal "14901", s.no
    assert_equal "Eskdalemuir", s.name
    assert_equal "Esk", s.catchment
    assert_equal "White Esk", s.river
  end
end

class TestClientRainfall15minTimeseries < Minitest::Test
  def setup
    @client = make_client("timeseries_list.json")
    @series = @client.rainfall_15min_timeseries(station_no: "14964")
  end

  def test_returns_array_of_timeseries
    assert_instance_of Array, @series
    assert @series.all? { |t| t.is_a?(SmoSepaKiwis::Timeseries) }
  end

  def test_ts_id_is_integer
    assert_equal 55570010, @series[0].ts_id
    assert_instance_of Integer, @series[0].ts_id
  end

  def test_coverage_from_is_utc_time
    t = @series[0].coverage_from
    assert_instance_of Time, t
    assert_equal "UTC", t.zone
    assert_equal 2010, t.year
    assert_equal 1, t.month
    assert_equal 1, t.day
  end

  def test_coverage_to_is_utc_time
    t = @series[0].coverage_to
    assert_instance_of Time, t
    assert_equal "UTC", t.zone
    assert_equal 2026, t.year
  end

  def test_station_no_string
    assert_equal "14964", @series[0].station_no
  end

  def test_ts_path
    assert_equal "1/14964/RE/15m.Cmd", @series[0].ts_path
  end
end

class TestClientTimeseriesValues < Minitest::Test
  def setup
    @client = make_client("timeseries_values.json")
    @values = @client.timeseries_values(
      ts_id: 55570010,
      from: "2021-10-22T12:00:00Z",
      to: "2021-10-22T13:00:00Z"
    )
  end

  def test_returns_array_of_values
    assert_instance_of Array, @values
    assert @values.all? { |v| v.is_a?(SmoSepaKiwis::Value) }
  end

  def test_count
    assert_equal 4, @values.size
  end

  def test_timestamp_is_utc_time
    v = @values[0]
    assert_instance_of Time, v.timestamp
    assert_equal "UTC", v.timestamp.zone
    assert_equal 2021, v.timestamp.year
    assert_equal 10, v.timestamp.month
    assert_equal 22, v.timestamp.day
    assert_equal 12, v.timestamp.hour
  end

  def test_value_is_float
    assert_in_delta 0.2, @values[0].value
  end

  def test_null_value_becomes_nil
    assert_nil @values[2].value
  end

  def test_quality_code_nil_when_not_in_response
    assert_nil @values[0].quality_code
  end
end

class TestClientInventory < Minitest::Test
  def setup
    # rainfall_15min_inventory calls getTimeseriesList then getStationList.
    @client = make_client("timeseries_list.json", "station_list.json")
    @inv = @client.rainfall_15min_inventory
  end

  def test_returns_array_of_hashes
    assert_instance_of Array, @inv
    assert @inv.all? { |r| r.is_a?(Hash) }
  end

  def test_has_expected_keys
    expected = %i[station_no station_name lat lon catchment river ts_id ts_path coverage_from coverage_to]
    assert_equal expected.sort, @inv[0].keys.sort
  end

  def test_ts_id_integer
    assert_instance_of Integer, @inv[0][:ts_id]
  end

  def test_lat_float
    assert_instance_of Float, @inv[0][:lat]
  end
end

class TestClientCsvMethods < Minitest::Test
  def test_inventory_to_csv
    Dir.mktmpdir do |dir|
      path = File.join(dir, "inv.csv")
      client = make_client("timeseries_list.json", "station_list.json")
      client.rainfall_15min_inventory_to_csv(path)
      lines = File.readlines(path)
      assert lines.first.start_with?("station_no")
      assert_equal 3, lines.size  # header + 2 data rows
    end
  end

  def test_values_to_csv
    Dir.mktmpdir do |dir|
      path = File.join(dir, "vals.csv")
      client = make_client("timeseries_values.json")
      client.timeseries_values_to_csv(
        ts_id: 55570010,
        from: "2021-10-22T12:00:00Z",
        to: "2021-10-22T13:00:00Z",
        path: path
      )
      lines = File.readlines(path)
      assert lines.first.start_with?("timestamp")
      assert_equal 5, lines.size  # header + 4 data rows
      # Null value row: value field is empty (two consecutive commas after timestamp).
      null_row = lines[3]
      assert_match(/,,/, null_row)
    end
  end
end
