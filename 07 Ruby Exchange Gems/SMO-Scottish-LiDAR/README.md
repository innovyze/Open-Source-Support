# smo_scottish_lidar

[![Gem Version](https://img.shields.io/badge/gem-v0.1.0-1D9E75)](https://rubygems.org/gems/smo_scottish_lidar)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7-CC342D)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-0F6E56)](LICENSE.txt)
[![Dependencies](https://img.shields.io/badge/dependencies-zero-085041)](smo_scottish_lidar.gemspec)

A pure Ruby gem for listing and downloading Scottish Public Sector LiDAR data from the [Registry of Open Data on AWS](https://registry.opendata.aws/scottish-lidar/).

Developed by **Sebastian Madrid Ontiveros** to support the hydraulic modelling community in Scotland. Whether you are building 1D-2D flood inundation models, defining subcatchments, or preparing terrain inputs for InfoWorks ICM, this gem takes the friction out of getting LiDAR data onto your machine.

No AWS CLI. No credentials. No dependencies. Uses only Ruby stdlib (`net/http`, `uri`, `fileutils`). Compatible with the InfoWorks ICM embedded Ruby environment.

<p align="center">
  <a href="https://buymeacoffee.com/smadrid">
    <img src="https://raw.githubusercontent.com/Sebasmadridmx/SMO-WGS84-TO-BNG/main/temp_png/buymecoffeeqr.png" width="130" alt="Buy Me a Coffee QR code">
  </a>
  <br/>
  <a href="https://buymeacoffee.com/smadrid">buymeacoffee.com/smadrid</a>
</p>

---

## What is this data?

The Scottish Government publishes LiDAR survey data as open data through an S3 bucket (`srsp-open-data`). Coverage spans most of Scotland across five survey phases, plus a dedicated Outer Hebrides survey. Each phase includes three dataset types:

| Type | Description |
|------|-------------|
| **DSM** | Digital Surface Model. Includes buildings, trees, and structures. Used for overland flow modelling. |
| **DTM** | Digital Terrain Model. Bare earth, vegetation removed. Ground surface for 2D mesh generation. |
| **LAZ** | Compressed LiDAR point cloud. Raw survey returns for processing in specialist software. |

Files are organised by OS National Grid square (e.g. `NS`, `NT`, `NO`, `NN`) and are free to access.

| Phase | Coverage |
|-------|----------|
| `phase-1` | Central Scotland |
| `phase-2` | South and East Scotland |
| `phase-3` | North and West Scotland |
| `phase-4` | Additional coverage |
| `phase-5` | Latest survey phase |
| `outer-hebrides` | Western Isles. Available at 25 cm and 50 cm resolution. |

---

## Installation

```sh
gem install smo_scottish_lidar
```

Or add to your Gemfile:

```ruby
gem "smo_scottish_lidar"
```

---

## Quick start

```ruby
require "smo_scottish_lidar"

# See what Phase 1 DSM tiles are available in the NS grid square
lister = SmoScottishLidar::Lister.new
lister.summary("phase-1", "dsm", grid_square: "NS")

# Download all Phase 1 DTM tiles for the NS grid square
downloader = SmoScottishLidar::Downloader.new
downloader.download("phase-1", "dtm",
  destination: "/projects/my_catchment/lidar/dtm",
  grid_square: "NS"
)

# Download a single known tile
downloader.download_file("phase-1", "dsm", "NS56_1M_DSM_PHASE1.tif",
  destination: "/tmp/lidar"
)
```

---

## Typical hydraulic modelling workflow

The pattern below covers the full cycle from discovery to download, including safe resume if the connection drops.

```ruby
require "smo_scottish_lidar"

lister     = SmoScottishLidar::Lister.new
downloader = SmoScottishLidar::Downloader.new(verbose: true)

# Step 1. Check what is available for your catchment
lister.summary("phase-1", "dtm", grid_square: "NS")

# Step 2. Dry run to confirm file count and total size before committing
downloader.download("phase-1", "dtm",
  destination: "/projects/my_catchment/lidar/dtm",
  grid_square: "NS",
  dry_run:     true
)

# Step 3. Download for real
downloader.download("phase-1", "dtm",
  destination: "/projects/my_catchment/lidar/dtm",
  grid_square: "NS"
)

# Step 4. If the download is interrupted, re-run step 3.
# Files already on disk at the correct size are skipped automatically.
```

---

## API reference

### `SmoScottishLidar::Lister`

Lists available files from the S3 bucket. Filtering by grid square is applied client-side after the full listing is fetched.

```ruby
lister = SmoScottishLidar::Lister.new(verbose: false)
```

#### `lister.list(phase, type, grid_square: nil, resolution: nil)`

Returns an `Array<Hash>` of matching files.

| Key | Type | Description |
|-----|------|-------------|
| `:key` | String | Full S3 object key |
| `:filename` | String | Bare filename, e.g. `NS56_1M_DSM_PHASE1.tif` |
| `:size` | Integer | File size in bytes |
| `:last_modified` | String | ISO 8601 timestamp |

```ruby
files = lister.list("phase-1", "dsm", grid_square: "NS")
files.each { |f| puts "#{f[:filename]}  (#{f[:size]} bytes)" }
```

#### `lister.summary(phase, type, grid_square: nil, resolution: nil)`

Prints a formatted table to stdout and returns the same `Array<Hash>`.

```ruby
lister.summary("phase-2", "dtm", grid_square: "NT")
lister.summary("outer-hebrides", "dsm", resolution: "50cm")
```

---

### `SmoScottishLidar::Downloader`

Downloads files from the S3 bucket. Responses are streamed in chunks so large files never load fully into memory.

```ruby
downloader = SmoScottishLidar::Downloader.new(verbose: false)
```

#### `downloader.download(phase, type, destination:, **options)`

Batch download with filtering. Returns `{ downloaded: [...], skipped: [...], failed: [...] }`.

```ruby
downloader.download(
  "phase-3", "dsm",
  destination:   "/data/lidar",
  grid_square:   "NO",
  skip_existing: true,
  dry_run:       false
)
```

| Option | Default | Description |
|--------|---------|-------------|
| `destination:` | required | Local directory to write files into |
| `grid_square:` | `nil` | OS National Grid square filter, e.g. `"NS"`. `nil` downloads everything. |
| `resolution:` | `nil` | Outer Hebrides only. `"25cm"`, `"50cm"`, `"4ppm"`, or `"16ppm"`. |
| `skip_existing:` | `true` | Skip any file already on disk whose size matches S3. |
| `dry_run:` | `false` | Print the download plan without transferring anything. |

#### `downloader.download_file(phase, type, filename, destination:, resolution: nil)`

Downloads a single tile by exact filename.

```ruby
downloader.download_file(
  "phase-1", "dsm", "NS56_1M_DSM_PHASE1.tif",
  destination: "/tmp/lidar"
)
```

---

### `SmoScottishLidar.prefix_for(phase, type, resolution: nil)`

Returns the S3 prefix string for a given phase and type. Useful for building custom queries against the bucket.

```ruby
SmoScottishLidar.prefix_for("phase-1", "dsm")
# => "lidar/phase-1/dsm/27700/gridded/"

SmoScottishLidar.prefix_for("outer-hebrides", "dtm", resolution: "50cm")
# => "lidar/outer-hebrides/2019/dtm/50cm/27700/gridded/"
```

---

## Valid parameters

```ruby
SmoScottishLidar::PHASES
# => ["phase-1", "phase-2", "phase-3", "phase-4", "phase-5", "outer-hebrides"]

SmoScottishLidar::DATASET_TYPES
# => ["dsm", "dtm", "laz"]
```

### Outer Hebrides resolutions

| Type | Available | Default |
|------|-----------|---------|
| `dsm` | `"25cm"`, `"50cm"` | `"25cm"` |
| `dtm` | `"25cm"`, `"50cm"` | `"25cm"` |
| `laz` | `"4ppm"`, `"16ppm"` | `"4ppm"` |

Phases 1-5 do not take a `resolution:` argument.

---

## Example scripts

The `examples/` directory contains ready-to-run scripts covering every phase, type, and common use case.

| Script | What it does |
|--------|-------------|
| `demo.rb` | Full walkthrough of all gem features |
| `phase_1_dsm.rb` | List Phase 1 DSM tiles |
| `phase_1_dtm.rb` | List Phase 1 DTM tiles |
| `phase_1_laz.rb` | List Phase 1 LAZ tiles |
| `phase_2_dsm.rb` ... | One script per phase and type |
| `outer_hebrides_dsm.rb` | Outer Hebrides DSM at both resolutions |
| `outer_hebrides_dtm.rb` | Outer Hebrides DTM at both resolutions |
| `outer_hebrides_laz.rb` | Outer Hebrides LAZ at both densities |
| `download_individual_tile.rb` | Download a single named tile |
| `download_batch_tiles.rb` | Batch download with grid square filter |

```sh
ruby examples/demo.rb
ruby examples/phase_1_dsm.rb
```

---

## Data source

Scottish Public Sector LiDAR Dataset, Scottish Government.
Available via [Registry of Open Data on AWS](https://registry.opendata.aws/scottish-lidar/) and the [Scottish Remote Sensing Portal](https://remotesensingdata.gov.scot).
S3 bucket: `s3://srsp-open-data/lidar/`
Access: public, no AWS account or credentials required.

---

## Support

If this gem saves you time on a project, consider buying me a coffee.

<p align="center">
  <a href="https://buymeacoffee.com/smadrid">
    <img src="https://raw.githubusercontent.com/Sebasmadridmx/SMO-WGS84-TO-BNG/main/temp_png/buymecoffeeqr.png" width="130" alt="Buy Me a Coffee QR code">
  </a>
  <br/>
  <a href="https://buymeacoffee.com/smadrid">buymeacoffee.com/smadrid</a>
</p>

---

## License

MIT. Copyright (c) 2025 Sebastian Madrid Ontiveros.
