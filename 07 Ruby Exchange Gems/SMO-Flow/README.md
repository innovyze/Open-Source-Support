# SMO Flow

[![Gem Version](https://badge.fury.io/rb/smo_flow.svg)](https://badge.fury.io/rb/smo_flow)

SMO Flow is a Ruby library created by Sebastian Madrid Ontiveros to help support hydraulic modelling in the UK and around the world.

It was developed in response to the lack of hydraulic modelling libraries available for Ruby, with the aim of making subcatchment runoff and flow calculations simpler, clearer, and more accessible.

If you find this project useful and would like to support its development, please consider donating:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support%20this%20project-yellow?style=flat&logo=buy-me-a-coffee)](https://buymeacoffee.com/smadrid)

## Overview

The library provides a developer-friendly way to estimate flow from roads, roofs, permeable areas, foul flow, and trade flow, using the Rational Method and timestep-based calculations.

## Installation

Add this line to your application's Gemfile:

````gem 'smo_flow'```

Or install it directly:

```bash
gem install smo_flow
```

## Usage

### Rational Method — Flow from Rainfall Intensity

```ruby
require "smo_flow"

calc = SmoFlow::RationalMethod.new(coefficient: 0.9, area: 2.5)

# Flow in m³/s
calc.flow_from_intensity(50.0)   # => 0.3125

# Flow in L/s
calc.flow_ls_from_intensity(50.0)  # => 312.5
```

### Flow from Rainfall Depth and Timestep

```ruby
calc = SmoFlow::RationalMethod.new(coefficient: 0.9, area: 2.5)

# Flow in m³/s from 5mm of rain over 1 hour
calc.flow_from_depth(depth: 5.0, timestep: 3600.0)  # => 0.03125
```

### Multiple Subcatchments

```ruby
road  = SmoFlow::RationalMethod.new(coefficient: 0.9, area: 1.5)
roof  = SmoFlow::RationalMethod.new(coefficient: 0.95, area: 0.8)
grass = SmoFlow::RationalMethod.new(coefficient: 0.3, area: 2.0)

intensity = 50.0  # mm/hr

total = road.flow_from_intensity(intensity) +
        roof.flow_from_intensity(intensity) +
        grass.flow_from_intensity(intensity)
```

### Convert Depth to Intensity

```ruby
calc.depth_to_intensity(depth: 5.0, timestep: 3600.0)  # => 5.0 mm/hr
```

### Runoff Volume

```ruby
calc.volume(depth: 5.0)  # => 112.5 m³
```

## Formulas

### Flow from Intensity
````
Q = C × i × A / 360
