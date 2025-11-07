# Logger Location Analysis Script

**Author:** Paolo Teixeira  
**Date:** November 7, 2024  
**Software:** InfoWorks WS Pro 2026+

## Overview

Analyzes hydrant elevations by area and recommends optimal locations for pressure logger placement. Uses spatial distribution algorithm to ensure loggers are evenly spread while prioritizing elevation extremes.

## Requirements

### Software
- InfoWorks WS Pro 2026+ (UI Script)
- Ruby 2.7+

### Network Data
- **`wn_hydrant`** table with: `node_id`, `area`, `ground_level`, `x`, `y`
- **`wn_address_point`** (optional): `allocated_pipe_id`, `no_of_properties`
- Hydrants must have both `area` and `ground_level` populated

## How It Works

### 1. Data Collection
- Groups hydrants by area
- Counts customer properties from address points
- Skips hydrants with missing area or elevation data

### 2. User Configuration
Single prompt dialog with:

**Logger to Property Ratio** (default: 250)
- Determines logger density: `Loggers = CEILING(Properties / Ratio)`
- Minimum 2 loggers per area (lowest + highest elevation)
- Examples: 700 properties ÷ 250 = 3 loggers

**Area Selection** (if multiple areas detected)
- Checkboxes showing: Area name, hydrant count, property count
- All areas checked by default
- Single area networks skip this step

### 3. Analysis
For each area:
- Identifies lowest and highest elevation hydrants (always selected)
- Calculates required loggers based on property count and ratio
- Selects additional hydrants using spatial distribution algorithm
- Algorithm: Each new logger is placed farthest from existing loggers

### 4. Confirmation
- Displays summary of recommended hydrants
- Prompts: "Select these hydrants on the map?"
- Yes = hydrants selected in network | No = selection cleared

## Running the Script

1. Open network in InfoWorks WS Pro
2. Network → Run Ruby Script → Select `loggers_location.rb`
3. Enter logger-to-property ratio (default: 250)
4. Select areas to analyze (if multiple areas)
5. Review console output and confirm selection

## Output

Console shows for each area:
- Total hydrants and customer properties
- Lowest/highest elevation hydrants (ID, elevation, location)
- All selected hydrants with spatial distribution
- Elevation range

Summary includes:
- Total areas analyzed
- Total hydrants selected
- Total customer properties

## Configuration Guide

| Scenario | Ratio | Result |
|----------|-------|--------|
| Budget-constrained | 400-500 | Fewer loggers, elevation focus |
| Standard monitoring | 200-300 | Balanced coverage |
| Detailed analysis | 100-150 | Dense logger network |
| Critical areas only | Uncheck areas | Focused monitoring |

## Troubleshooting

| Error | Solution |
|-------|----------|
| "No hydrants found" | Verify `wn_hydrant` table exists |
| "No hydrants with area and elevation" | Populate `area` and `ground_level` fields |
| "Could not count address points" | Optional - analysis continues with 0 properties |
| "Invalid ratio" | Enter positive number (typical: 50-500) |
| "No areas selected" | Check at least one area checkbox |

## Algorithm Details

**Spatial Distribution (Maximin Distance):**
1. Start with elevation extremes (min/max)
2. For each additional logger:
   - Calculate distance from each remaining hydrant to all selected hydrants
   - Select hydrant with maximum minimum distance
   - Ensures even geographic distribution

**Distance:** Euclidean distance using network coordinates

**Benefits:** Maximizes coverage, avoids clustering, works with irregular shapes

## Best Practices

**Before Running:**
- Verify hydrant data completeness (area, elevation)
- Use consistent area naming
- Check address point allocations

**Configuration:**
- Start with default ratio (250)
- Lower ratio (100-150) for critical areas
- Higher ratio (300-500) for preliminary assessment

**After Running:**
- Validate spatial distribution on map
- Verify elevation extremes captured
- Save selection with descriptive name and date
