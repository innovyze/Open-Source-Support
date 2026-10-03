# smo_sepa_kiwis

A pure-Ruby client for the [SEPA Time Series KiWIS API](https://timeseriesdoc.sepa.org.uk/api-documentation/).
Fetch rainfall stations, 15-minute timeseries metadata, and timeseries values.
Export everything to CSV.

Built specifically for use inside InfoWorks ICM 2027's embedded Ruby interpreter,
where no `gem install` step is possible.

## Support

This gem is free and open source. If it saves you time on a hydraulic
modelling project, you can support development here:

<p align="center">
  <a href="https://buymeacoffee.com/smadrid">
    <img src="https://github.com/Sebasmadridmx/SMO-WGS84-TO-BNG/raw/main/temp_png/buymecoffeeqr.png" width="180" alt="Buy Me a Coffee QR code">
  </a>
  <br>
  <a href="https://buymeacoffee.com/smadrid">buymeacoffee.com/smadrid</a>
</p>

## Why this gem

Hydraulic modellers working in InfoWorks ICM often need rainfall observations
from SEPA gauges to drive 1D-2D simulations or validate model performance.
Pulling that data manually through the SEPA web portal does not scale beyond
a handful of stations.

This gem makes the SEPA KiWIS API directly callable from any Ruby environment,
including ICM's embedded interpreter. It uses stdlib only (`net/http`, `uri`,
`json`, `csv`, `date`, `time`), has no native extensions, and no Bundler
runtime dependencies.

## Installation

```sh
gem install smo_sepa_kiwis
```

```ruby
require "smo_sepa_kiwis"
```

## Quick start

```ruby
require "smo_sepa_kiwis"

client = SmoSepaKiwis::Client.new
# Optional kwargs: base_url:, timeout: (default 60), user_agent:
```

### 1. List all rainfall stations

```ruby
stations = client.rainfall_stations
# => Array<SmoSepaKiwis::Station>
# Station fields: no, name, lat, lon, catchment, river
```

### 2. Find 15-minute timeseries for a specific station

```ruby
series = client.rainfall_15min_timeseries(station_no: "14964")
# => Array<SmoSepaKiwis::Timeseries>
# Timeseries fields: ts_id, ts_path, ts_name, station_no, coverage_from, coverage_to
```

### 3. Network-wide inventory in one call

```ruby
inventory = client.rainfall_15min_inventory
# => Array<Hash> with keys:
#    :station_no, :station_name, :lat, :lon, :catchment, :river,
#    :ts_id, :ts_path, :coverage_from, :coverage_to
```

### 4. Download timeseries values

```ruby
values = client.timeseries_values(
  ts_id: 55570010,
  from:  "2021-10-22",
  to:    "2021-10-25"
)
# => Array<SmoSepaKiwis::Value>
# Value fields: timestamp (Time UTC), value (Float or nil), quality_code (Integer or nil)
```

`from` and `to` accept `String`, `Date`, `Time`, or `DateTime`.

For long date ranges, use `chunk_days` to split the request into smaller
windows and avoid server timeouts:

```ruby
values = client.timeseries_values(
  ts_id:      55570010,
  from:       "2020-01-01",
  to:         "2021-01-01",
  chunk_days: 30
)
```

### 5. Export the full network inventory to CSV

```ruby
client.rainfall_15min_inventory_to_csv("inventory.csv")
```

### 6. Export timeseries values to CSV

```ruby
client.timeseries_values_to_csv(
  ts_id: 55570010,
  from:  "2021-10-22",
  to:    "2021-10-25",
  path:  "rainfall.csv"
)
```

## Data fidelity

This gem returns SEPA fields verbatim. String fields that are blank in the
API response are set to `nil`. Numeric fields (`lat`, `lon`, `ts_id`) are
coerced from the string representation SEPA provides. Timestamps are parsed
as ISO 8601 and converted to UTC. No values are derived, interpolated, or
synthesised.

If you need British National Grid coordinates, the companion gem
[`smo_wgs84_to_bng`](https://github.com/Sebasmadridmx) converts WGS84
lat/lon to BNG easting/northing.

## Examples

The `examples/` directory contains runnable scripts:

- `01_list_rainfall_stations.rb`: fetch all rainfall stations and save to CSV
- `02_find_15min_timeseries.rb`: list 15-min series for a given station
- `03_download_rainfall_event.rb`: download a storm event window
- `04_bulk_export_csv.rb`: full inventory plus the last 7 days of values for every station

Run any of them with:

```sh
ruby -Ilib examples/01_list_rainfall_stations.rb
```

## Compatibility

- Ruby 3.2 and above
- Tested with InfoWorks ICM 2027 embedded Ruby (3.4.6)
- No external runtime dependencies

## Author

Sebastian Madrid Ontiveros, Senior Hydraulic Modeller (Edinburgh, UK).
GitHub: [Sebasmadridmx](https://github.com/Sebasmadridmx)

## Support this work

If this gem saves you time on a hydraulic modelling project, consider
buying me a coffee:

<p align="center">
  <a href="https://buymeacoffee.com/smadrid">
    <img src="https://github.com/Sebasmadridmx/SMO-WGS84-TO-BNG/raw/main/temp_png/buymecoffeeqr.png" width="140" alt="Buy Me a Coffee QR code">
  </a>
  <br>
  <a href="https://buymeacoffee.com/smadrid">buymeacoffee.com/smadrid</a>
</p>

## License

MIT. Copyright (c) 2026 Sebastian Madrid Ontiveros.
