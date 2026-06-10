# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-04

### Added
- `batch_download` for downloading readings from multiple stations to individual CSV files
- `rainfall_15min_inventory` and `rainfall_15min_inventory_to_csv` for full station inventory with coverage dates
- `find_stations` for searching stations by name or reference
- `rainfall_15min_stations_with_coverage` for stations with earliest/latest reading dates

## [0.1.0] - 2026-05-04

### Added
- `SmoEaHydrology::Client` for the Environment Agency Hydrology API
- `rainfall_15min_stations` — fetches all active 15-min rainfall stations
- `measures` — fetches 15-min rainfall measures for a station
- `readings` — fetches timestamped readings over a date range
- `readings_to_csv` — exports readings to CSV
- `Station`, `Measure`, `Reading`, and `InventoryEntry` data classes
- `ApiError` and `ParseError` error classes
- Test suite with comprehensive assertions
