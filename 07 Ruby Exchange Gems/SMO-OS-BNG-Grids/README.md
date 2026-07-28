# smo_os_bng_grids

**Pure Ruby library for Ordnance Survey British National Grid (BNG) squares.**

Point lookup · Spatial search · Bounds · Corner coordinates · Shapefile export

No external dependencies. Works in InfoWorks ICM 2027 embedded Ruby.

<br>

[![Gem Version](https://badge.fury.io/rb/smo_os_bng_grids.svg)](https://badge.fury.io/rb/smo_os_bng_grids)
[![License: OGL v3](https://img.shields.io/badge/License-OGL%20v3-0076D6?style=flat&logo=gov.uk&logoColor=white)](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
[![Ruby](https://img.shields.io/badge/Ruby-stdlib%20only-CC342D?style=flat&logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![ICM](https://img.shields.io/badge/InfoWorks%20ICM-2027%20compatible-005F73?style=flat)](https://www.autodesk.com/products/infoworks-icm)
[![OS Data](https://img.shields.io/badge/OS%20Data-Crown%20copyright%202025-003087?style=flat)](https://www.ordnancesurvey.co.uk)

<br>

<div align="center">

<a href="https://buymeacoffee.com/smadrid">
<img src="https://raw.githubusercontent.com/Sebasmadridmx/SMO-WGS84-TO-BNG/main/temp_png/buymecoffeeqr.png" width="250" alt="QR code — buymeacoffee.com/smadrid"/>
</a>

[buymeacoffee.com/smadrid](https://buymeacoffee.com/smadrid)

</div>

---

## Overview

`smo_os_bng_grids` provides hardcoded geometry sourced directly from the **OS BNG Grids GeoPackage** (EPSG:27700), covering all five standard resolutions from 100 km down to 1 km — 910,091 grid squares in total. The library uses pure Ruby standard library with no runtime downloads, making it fully compatible with InfoWorks ICM 2027's embedded Ruby environment.

> Contains OS data. Crown copyright and database right 2025.
> Licensed under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

---

## Features

| Feature | Description |
|---|---|
| **Point lookup** | Find the grid reference containing any easting/northing at any resolution |
| **Spatial search** | All tiles intersecting a radius or bounding box, with distance in metres |
| **Bounds** | Min/max easting and northing for any grid reference string |
| **Corner points** | NW → NE → SE → SW → NW, ready for ICM `boundary_array` |
| **Shapefile export** | Pure Ruby SHP/SHX/DBF/PRJ writer. No GDAL required |
| **Grid validation** | Check whether any grid reference string is valid |
| **Pure stdlib** | No gems, no GDAL, no external dependencies |

---

## Grid resolutions

| Resolution | Count | Example | Square size |
|---|---|---|---|
| 100 km | 91 | `NT` | 100 km × 100 km |
| 50 km | 364 | `NTNW` | 50 km × 50 km |
| 10 km | 9,100 | `NT27` | 10 km × 10 km |
| 5 km | 36,400 | `NT27SE` | 5 km × 5 km |
| 1 km | 910,000 | `NT2573` | 1 km × 1 km |

---

## Installation

Add to your `Gemfile`:

```ruby
gem "smo_os_bng_grids"
```

Or install directly:

```bash
gem install smo_os_bng_grids
```

---

## Quick start

```ruby
require "smo_os_bng_grids"

lister = SmoOsBngGrids::Lister.new

# Point lookup — what grid square is Edinburgh city centre in?
easting  = 325000
northing = 673000

SmoOsBngGrids::Grid.ref_at(easting, northing, resolution: "10km")  # => "NT27"
SmoOsBngGrids::Grid.ref_at(easting, northing, resolution: "1km")   # => "NT2573"

# All resolutions at once
lister.find(easting, northing)
# => {"100km"=>"NT", "50km"=>"NTNW", "10km"=>"NT27", "5km"=>"NT27SE", "1km"=>"NT2573"}

# Bounds of a grid square
SmoOsBngGrids::Grid.bounds("NT27")
# => {min_e: 320000, min_n: 670000, max_e: 330000, max_n: 680000}
```

---

## Listing grid squares

```ruby
lister = SmoOsBngGrids::Lister.new

# All 100 km squares
lister.list("100km")

# All 10 km squares within NT
lister.list("10km", within: "NT")

# All 1 km squares within NT27
lister.list("1km", within: "NT27")
```

Each entry is a Hash:

```ruby
{
  ref:    "NT27",
  min_e:  320000, min_n: 670000,
  max_e:  330000, max_n: 680000,
  points: [
    [320000, 680000],  # NW
    [330000, 680000],  # NE
    [330000, 670000],  # SE
    [320000, 670000],  # SW
    [320000, 680000]   # NW (closed)
  ]
}
```

---

## Spatial search

Find all tiles intersecting a radius or bounding box around a point:

```ruby
lister = SmoOsBngGrids::Lister.new

# All 10 km tiles within 12 km of Edinburgh
tiles = lister.search(325000, 673000, resolution: "10km", radius: 12000)
tiles.each { |t| puts "#{t[:ref]}  #{t[:distance_m]} m" }

# All 1 km tiles within 1.5 km of Edinburgh
lister.search(325000, 673000, resolution: "1km", radius: 1500)

# All 5 km tiles within a 15 km box around Edinburgh
lister.search(325000, 673000, resolution: "5km", box: 15000)
```

Radius search returns `:distance_m` for each entry. Returns `0.0` when the point falls inside the tile.

---

## Corner points — InfoWorks ICM

Every entry returned by `list`, `search`, and `entry_for` includes a `:points` array in **NW → NE → SE → SW → NW** order, matching the InfoWorks ICM `boundary_array` convention:

```ruby
lister = SmoOsBngGrids::Lister.new

# Single tile containing a point
tile = lister.search(325000, 673000, resolution: "10km", radius: 1).first
boundary_array = tile[:points]
# => [[320000, 680000], [330000, 680000], [330000, 670000], [320000, 670000], [320000, 680000]]

# Flat XY array if needed
flat_xy = tile[:points].flatten
# => [320000, 680000, 330000, 680000, 330000, 670000, 320000, 670000, 320000, 680000]

# Convert a ref string to a full entry
entry = lister.entry_for("NT27SE")
entry[:points]
# => [[325000, 675000], [330000, 675000], [330000, 670000], [325000, 670000], [325000, 675000]]
```

---

## Shapefile export

Export any set of entries to ESRI Shapefile format (OSGB36 / EPSG:27700). Pure Ruby — no GDAL, no external gems. Produces `.shp`, `.shx`, `.dbf`, and `.prj` files, ready to open directly in QGIS or ArcGIS.

```ruby
lister = SmoOsBngGrids::Lister.new
writer = SmoOsBngGrids::ShapefileWriter.new

# From list()
writer.write(lister.list("10km", within: "NT"), "/tmp/nt_10km")

# From search()
entries = lister.search(325000, 673000, resolution: "10km", radius: 20000)
writer.write(entries, "/tmp/edinburgh_10km_20km")

# From find() — one tile per resolution
found = lister.find(325000, 673000)
found.each do |res, ref|
  writer.write([lister.entry_for(ref)], "/tmp/edinburgh_#{res}")
end
```

---

## Grid reference validation

```ruby
SmoOsBngGrids::Grid.valid?("NT")      # => true
SmoOsBngGrids::Grid.valid?("NT27")    # => true
SmoOsBngGrids::Grid.valid?("NT2573")  # => true
SmoOsBngGrids::Grid.valid?("ZZ")      # => false
```

---

## Data

All geometry is hardcoded from the **OS BNG Grids GeoPackage** published by Ordnance Survey.

Source: [github.com/OrdnanceSurvey/osbng-grids](https://github.com/OrdnanceSurvey/osbng-grids)

Contains OS data. Crown copyright and database right 2025. Licensed under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

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
