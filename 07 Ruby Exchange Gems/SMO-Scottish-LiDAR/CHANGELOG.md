# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-04

### Added
- `SmoScottishLidar::Client` for listing and downloading LiDAR data from AWS S3
- Support for all survey phases (1–5) and Outer Hebrides
- DSM, DTM, and LAZ dataset types
- OS National Grid square filtering
- Paginated S3 listing with continuation tokens
- Streamed downloads with redirect following and progress callback
- Dry-run mode via verbose option
- RSpec test suite
