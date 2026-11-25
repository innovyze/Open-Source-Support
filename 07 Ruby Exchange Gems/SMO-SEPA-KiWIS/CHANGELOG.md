# Changelog

All notable changes to this project will be documented in this file.

## [0.1.1] - 2025-05-03

### Changed

- Updated gem description and author attribution.

## [0.1.0] - 2024-01-01

### Added

- Initial release.
- `Client` with six public methods: `rainfall_stations`, `rainfall_15min_timeseries`,
  `rainfall_15min_inventory`, `timeseries_values`, `rainfall_15min_inventory_to_csv`,
  `timeseries_values_to_csv`.
- `Station`, `Timeseries`, and `Value` structs.
- `ResponseParser` for KiWIS column-array JSON format.
- `ApiError` and `ParseError` error classes.
- Chunked fetching via `chunk_days` parameter.
- Four runnable example scripts.
- Minitest test suite with recorded fixtures (no network access).
