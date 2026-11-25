require_relative "test_helper"

class TestStation < Minitest::Test
  def test_keyword_init
    s = SmoSepaKiwis::Station.new(
      no: "14964", name: "Auchinner", lat: 56.36, lon: -4.05,
      catchment: "Earn", river: "Allt Srath a Ghlinne"
    )
    assert_equal "14964", s.no
    assert_equal "Auchinner", s.name
    assert_in_delta 56.36, s.lat
    assert_in_delta(-4.05, s.lon)
    assert_equal "Earn", s.catchment
    assert_equal "Allt Srath a Ghlinne", s.river
  end

  def test_nil_fields_allowed
    s = SmoSepaKiwis::Station.new(
      no: "14933", name: "Killin", lat: nil, lon: nil,
      catchment: nil, river: nil
    )
    assert_nil s.lat
    assert_nil s.catchment
  end

  def test_equality
    s1 = SmoSepaKiwis::Station.new(no: "1", name: "A", lat: 1.0, lon: 2.0, catchment: nil, river: nil)
    s2 = SmoSepaKiwis::Station.new(no: "1", name: "A", lat: 1.0, lon: 2.0, catchment: nil, river: nil)
    assert_equal s1, s2
  end

  def test_inequality
    s1 = SmoSepaKiwis::Station.new(no: "1", name: "A", lat: 1.0, lon: 2.0, catchment: nil, river: nil)
    s2 = SmoSepaKiwis::Station.new(no: "2", name: "B", lat: 1.0, lon: 2.0, catchment: nil, river: nil)
    refute_equal s1, s2
  end
end
