# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-01

### Added
- `SmoFlow::RationalMethod` class for calculating surface runoff flow
- `flow_from_intensity` — calculates flow in m³/s from rainfall intensity (mm/hr), area (ha), and runoff coefficient
- `flow_from_depth` — calculates flow in m³/s from rainfall depth (mm) and timestep duration (s)
- `depth_to_intensity` — converts rainfall depth and timestep to intensity in mm/hr
- `volume` — calculates runoff volume in m³ for a given rainfall depth
- `flow_ls_from_intensity` — returns flow in L/s from rainfall intensity
- `SmoFlow::InvalidInput` error class for input validation
- Input validation for coefficient (0..1), area, intensity, depth, and timestep
- RSpec test suite with 13 examples covering all methods and edge cases
- RuboCop linting configuration
- GitHub Actions CI workflow