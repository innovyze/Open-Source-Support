# smo_ea_hydrology

**Pure Ruby client for the Environment Agency Hydrology API.**

Fetch active 15-minute rainfall stations, coverage dates, and timestamped readings over any date range.

No external dependencies. Uses only Ruby stdlib (`net/http`, `uri`, `json`, `date`, `time`).
Compatible with InfoWorks ICM 2027 embedded Ruby.

<br>

[![Gem Version](https://badge.fury.io/rb/smo_ea_hydrology.svg)](https://rubygems.org/gems/smo_ea_hydrology)
[![License: MIT](https://img.shields.io/badge/License-MIT-22863a?style=flat&logo=open-source-initiative&logoColor=white)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/Ruby-stdlib%20only-CC342D?style=flat&logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![ICM](https://img.shields.io/badge/InfoWorks%20ICM-2027%20compatible-005F73?style=flat)](https://www.autodesk.com/products/infoworks-icm)
[![EA API](https://img.shields.io/badge/EA%20Hydrology%20API-live-0076D6?style=flat)](https://environment.data.gov.uk/hydrology/doc/reference)

<br>

<div align="center">

<a href="https://buymeacoffee.com/smadrid">
<img src="https://raw.githubusercontent.com/Sebasmadridmx/SMO-WGS84-TO-BNG/main/temp_png/buymecoffeeqr.png" width="250" alt="QR code — buymeacoffee.com/smadrid"/>
</a>

[buymeacoffee.com/smadrid](https://buymeacoffee.com/smadrid)

</div>

---

## Overview

`smo_ea_hydrology` wraps the [Environment Agency Hydrology API](https://environment.data.gov.uk/hydrology/doc/reference), giving you clean Ruby objects for stations, measures, and readings with no setup beyond a `gem install`. It is designed for use in hydraulic modelling workflows — including inside InfoWorks ICM 2027's embedded Ruby environment — where pulling rainfall data programmatically saves significant manual effort.

---

## Installation

```bash
gem install smo_ea_hydrology
```

Or add to your `Gemfile`:

```ruby
gem "smo_ea_hydrology"
```

---

## Quick start

```ruby
require "smo_ea_hydrology"

client = SmoEaHydrology::Client.new

# List active 15-minute rainfall stations
stations = client.rainfall_15min_stations
puts stations.first.label             # "Ulpha  Duddo"
puts stations.first.station_reference # "589359"
puts stations.first.measure_label     # "Rainfall 15min Total (mm)"

# Find a station by name or reference
station = client.find_stations("Cosford").first

# Fetch readings for a date range
measure  = client.measures(station.station_reference).first
readings = client.readings(measure.id, from: "2024-06-01", to: "2024-06-07")
puts readings.size        # 672
puts readings.first.value # 0.0
```

---

## Features

### Stations

```ruby
# Fast — no coverage dates
stations = client.rainfall_15min_stations

# Slower — populates coverage_from / coverage_to (2 API calls per station)
stations = client.rainfall_15min_stations_with_coverage

# Search by partial name or exact reference
client.find_stations("Dartmoor")  # partial name match
client.find_stations("589359")    # exact reference match
```

Each `Station` object exposes:

| Field | Description |
|---|---|
| `label` | Station name |
| `station_reference` | Unique reference, e.g. `"589359"` |
| `lat` / `long` | WGS84 coordinates |
| `easting` / `northing` | OSGB36 coordinates |
| `date_opened` | e.g. `"1990-10-04"` |
| `measure_label` | `"Rainfall 15min Total (mm)"` |
| `measure_id` | Full URI of the 15-minute measure |
| `coverage_from` | `Time` of earliest reading (nil unless fetched) |
| `coverage_to` | `Time` of latest reading (nil unless fetched) |

### Readings

```ruby
measures = client.measures("589359")
readings = client.readings(measures.first.id, from: "2024-06-01", to: "2024-06-07")

# Time-of-day filtering (UTC)
readings = client.readings(measures.first.id,
  from: "2024-06-01 09:00",
  to:   "2024-06-01 17:00")

# Date / Time objects also accepted
readings = client.readings(measures.first.id,
  from: Date.new(2024, 6, 1),
  to:   Time.utc(2024, 6, 7, 23, 45))
```

Each `Reading` has: `datetime` (Time), `value` (Float, mm), `quality` (String), `completeness` (String).

### CSV export

```ruby
# Single station
client.readings_to_csv(
  station_reference: "589359",
  from: "2024-06-01",
  to:   "2024-06-07",
  path: "ulpha_june2024.csv"
)

# Batch — multiple stations to individual files
client.batch_download(
  from:       "2024-06-01",
  to:         "2024-06-07",
  output_dir: "rainfall_data",
  refs:       %w[589359 1712 603111]  # nil = all stations
)

# Full inventory with coverage dates
client.rainfall_15min_inventory_to_csv("inventory.csv")
```

### Inventory

```ruby
entries = client.rainfall_15min_inventory
# Returns Array<InventoryEntry> — station + measure + coverage_from + coverage_to
# Note: makes 2 API calls per station. Use rainfall_15min_inventory_to_csv for bulk export.
```

---

## Examples

| Script | Description |
|---|---|
| `examples/01_stations.rb` | List stations with coverage dates |
| `examples/02_readings.rb` | Fetch readings and show daily totals |
| `examples/03_inventory.rb` | Full inventory export to CSV |
| `examples/04_single_download.rb` | Download one station to CSV |
| `examples/05_batch_download.rb` | Batch download multiple stations |

Run any example directly:

```bash
ruby examples/01_stations.rb

# Edit STATION / FROM / TO at the top first, then:
ruby examples/04_single_download.rb
```

---

## API coverage

| EA API endpoint | Gem method |
|---|---|
| `/id/stations?observedProperty=rainfall` | `rainfall_15min_stations` |
| `/id/measures?periodName=15min` | `measures(station_reference)` |
| `/id/measures/{id}/readings` | `readings(measure_id, from:, to:)` |
| Flood Monitoring `latestReading` | `rainfall_15min_stations_with_coverage` |

Full API reference: [environment.data.gov.uk/hydrology/doc/reference](https://environment.data.gov.uk/hydrology/doc/reference)

---

## License

MIT. See [LICENSE](LICENSE).

---

<div align="center">

### ☕ &nbsp;Support this project

This gem is free and open source, built for the hydraulic modelling and flood risk community across the UK.<br/>
If it saves you time on a project, a coffee goes a long way.

<br/>

<a href="https://buymeacoffee.com/smadrid">
  <img src="https://raw.githubusercontent.com/Sebasmadridmx/SMO-WGS84-TO-BNG/main/temp_png/buymecoffeeqr.png" width="250" alt="Scan to buy Sebastian a coffee"/>
</a>

[buymeacoffee.com/smadrid](https://buymeacoffee.com/smadrid)

<br/>

*Built by **Sebastian Madrid Ontiveros** &nbsp;·&nbsp; Edinburgh &nbsp;·&nbsp; Hydraulic Modeller*

</div>
