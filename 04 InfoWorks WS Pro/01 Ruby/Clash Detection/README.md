# 3D Clash Detection

Detects vertical clearance violations between pipes that cross in plan view. The script checks if pipes physically clash in 3D space by calculating the clearance at intersection points.

## Features

- **Full polyline geometry support** - Uses the `bends` array to account for all pipe vertices, not just endpoints
- **Z-coordinate interpolation** - Calculates elevation at any point along the pipe by interpolating between upstream and downstream levels
- **Works on selection or entire network** - Process only selected pipes or analyze the whole network
- **Configurable clearance threshold** - Set a minimum clearance buffer to detect near-misses
- **Multiple output options** - Console output, CSV export, and automatic selection of clashing pipes

## How It Works

1. **Geometry Processing**: For each pipe, the script builds a polyline from the `bends` array (which contains all vertices including intermediate points)

2. **Intersection Detection**: Checks every segment of each pipe against every segment of other pipes for 2D intersections

3. **Elevation Calculation**: At each intersection point, interpolates the pipe invert level based on the distance along the pipe:
   ```
   level = US_level + (distance_ratio) × (DS_level - US_level)
   ```

4. **Clearance Calculation**: 
   ```
   clearance = IL_upper - (IL_lower + Diameter_lower)
   ```
   Where:
   - `IL_upper` = invert level of the higher pipe at the crossing
   - `IL_lower` = invert level of the lower pipe at the crossing
   - `Diameter_lower` = diameter of the lower pipe

5. **Clash Detection**: A clash is reported when:
   ```
   clearance <= minimum_clearance + tolerance
   ```

## User Options

When the script runs, a dialog prompts for the following options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Include shared nodes? | Boolean | false | Whether to check pipes that share a common node (connected pipes) |
| Output results to console? | Boolean | true | Print a formatted table of results to the console |
| Export results to CSV? | Boolean | true | Save results to a CSV file in the system temp folder |
| Minimum clearance (m) | Number | 0 | Buffer distance for clash detection. Use 0 to only detect touching/overlapping pipes |

## Output

### Console Output
When enabled, displays a formatted table:
```
=== CLASH DETECTION RESULTS ===
Minimum clearance threshold: 0.0 m
Clashes found: 3

#     Link 1                    Link 2                    Clearance(m)               X               Y
------------------------------------------------------------------------------------------------------
1     PIPE001                   PIPE045                       -0.0821      123456.78      654321.12
2     PIPE002                   PIPE046                       -0.0512      123457.89      654322.23
3     PIPE003                   PIPE047                        0.0034      123458.90      654323.34
```

### CSV Export
Creates a file in the system temp folder (`clash_detection_<timestamp>.csv`) with columns:
- `link1` - First pipe ID
- `link2` - Second pipe ID  
- `clearance_m` - Clearance in meters (negative = overlap)
- `x` - X coordinate of intersection
- `y` - Y coordinate of intersection

### Selection
All pipes involved in clashes are automatically selected in the GeoPlan for easy visualization.

## Requirements

- InfoWorks WS Pro (also compatible with InfoWorks ICM)
- Network must be open in the UI
- Pipes must have:
  - Elevation data (node Z values or pipe invert levels)
  - Diameter or height data

## Understanding the Results

- **Negative clearance**: Pipes are physically overlapping in 3D space
- **Zero clearance**: Pipes are touching
- **Positive clearance (below threshold)**: Pipes are close but not touching - potential concern depending on your clearance requirements

## Notes

- The script automatically skips pipes that share a node (connected pipes) by default, as these aren't true crossings
- Bounding box optimization is used to quickly skip pipe pairs that can't possibly intersect
- A small numerical tolerance (0.005m) is applied to handle floating-point precision issues

