# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-04

### Added
- `SmoOsBngGrids::Grid` for point-to-grid-ref lookup, bounds retrieval, and validation
- `SmoOsBngGrids::Lister` for listing, filtering, and spatial search of grid squares
- `SmoOsBngGrids::ShapefileWriter` for ESRI Shapefile export
- Support for 100km, 50km, 10km, 5km, and 1km resolutions
- Hardcoded geometry sourced from OS BNG Grids GeoPackage
- Circular radius and bounding box spatial search
- Test suite covering data loading, geometry, and bounds
