# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-02

### Added
- `SmoWgs84ToBng.wgs84_to_bng` — converts WGS84 lat/lon to OSGB36 easting/northing
- `SmoWgs84ToBng.bng_to_wgs84` — converts OSGB36 easting/northing to WGS84 lat/lon
- 7-parameter Helmert transformation with ~3–5 m accuracy across Great Britain
- Input validation for coordinates, bounds checking, and error classes
- Batch conversion support for arrays of points
- Minitest test suite
