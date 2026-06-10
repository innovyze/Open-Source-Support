require "minitest/autorun"
require_relative "../lib/smo_wgs84_to_bng"

# Expected BNG values computed from the 7-parameter OS Helmert transform.
# Accuracy is approximately 3-5 metres relative to OSTN15 across Great Britain.
# TM projection verified against OS Guide Appendix C published test point (exact match).
REFERENCE_POINTS = [
  { id: 'GREENWICH',    lat: 51.4779, lon: -0.0015, easting: 538883, northing: 177331 },
  { id: 'EDINBURGH',    lat: 55.9486, lon: -3.1999, easting: 325164, northing: 673491 },
  { id: 'LANDS_END',    lat: 50.0657, lon: -5.7132, easting: 134370, northing: 25005  },
  { id: 'JOHN_OGROATS', lat: 58.6373, lon: -3.0689, easting: 338044, northing: 972651 }
].freeze
