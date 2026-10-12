require_relative "test_helper"

class TestResponseParser < Minitest::Test
  def test_headers_and_rows
    body = fixture("station_list.json")
    result = SmoSepaKiwis::ResponseParser.parse(body)
    assert_equal 3, result.size
    assert_equal "14964", result[0][:station_no]
    assert_equal "Auchinner", result[0][:station_name]
  end

  def test_empty_array_returns_empty
    result = SmoSepaKiwis::ResponseParser.parse("[]")
    assert_equal [], result
  end

  def test_headers_only_returns_empty
    body = '[["station_no","station_name"]]'
    result = SmoSepaKiwis::ResponseParser.parse(body)
    assert_equal [], result
  end

  def test_malformed_json_raises_parse_error
    assert_raises(SmoSepaKiwis::ParseError) do
      SmoSepaKiwis::ResponseParser.parse("not json {{{")
    end
  end

  def test_unexpected_shape_raises_parse_error
    assert_raises(SmoSepaKiwis::ParseError) do
      SmoSepaKiwis::ResponseParser.parse('{"error":"no data"}')
    end
  end

  def test_null_in_list_fixture_preserved
    # station_list has no nulls, but confirm the parser passes nil JSON values through.
    body = '[["station_no","river_name"],["14964",null]]'
    result = SmoSepaKiwis::ResponseParser.parse(body)
    assert_nil result[0][:river_name]
  end

  def test_empty_string_fields_preserved_as_empty_string
    body = fixture("station_list.json")
    result = SmoSepaKiwis::ResponseParser.parse(body)
    # Killin has empty river_name.
    assert_equal "", result[1][:river_name]
  end

  def test_symbol_keys
    body = fixture("station_list.json")
    result = SmoSepaKiwis::ResponseParser.parse(body)
    assert result[0].key?(:station_no)
  end
end
