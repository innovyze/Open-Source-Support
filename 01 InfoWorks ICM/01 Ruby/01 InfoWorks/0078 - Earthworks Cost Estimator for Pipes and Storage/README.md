# Earthworks Cost Estimator for Pipes and Storage

This script calculates high-level earthworks cost estimates for selected network objects in InfoWorks ICM. It provides volume and cost calculations for both pipe trenches and storage structures (storage nodes and ponds) based on excavation requirements below ground level.

## Overview

The script processes two types of network objects:

1. **Pipes (hw_conduit)**: Calculates trench excavation volume based on pipe length, burial depth, and user-specified trench width
2. **Storage Nodes and Ponds**: Calculates excavation volume from storage array data for all storage below ground level

Results are displayed in the output window and optionally exported to a timestamped CSV file for further analysis.

## How It Works

### Pipe Excavation Calculation

For each selected pipe:

1. Retrieves pipe length and upstream/downstream invert levels
2. Gets ground levels from connected nodes
3. Calculates burial depth at each end: `depth = ground_level - invert_level`
4. Computes average depth: `avg_depth = (us_depth + ds_depth) / 2`
5. Calculates trench volume: `volume = length × width × avg_depth`
6. Applies cost per cubic meter to determine total cost

**Formula:**
```
Trench Volume = Pipe Length × Trench Width × Average Burial Depth
```

### Storage Node/Pond Excavation Calculation

For each selected storage node or pond:

1. Retrieves the storage array (level-area pairs) from the node
2. Identifies the node's ground level
3. Calculates volume below ground using the **trapezoidal rule**:
   - For segments entirely below ground: adds full segment volume
   - For segments crossing ground level: interpolates area at ground level and adds partial volume
   - Skips segments entirely above ground level

**Formula (Trapezoidal Rule):**
```
Volume between levels = (h₂ - h₁) × (A₁ + A₂) / 2

Where:
  h₁, h₂ = elevation levels (m)
  A₁, A₂ = surface areas at those levels (m²)
```

The script handles cases where storage arrays extend above ground level by interpolating the area at ground level and only calculating volume for the portion below ground.

### Volume Calculation Example

**Storage Array Data:**
- Level 95m, Area 100 m²
- Level 98m, Area 150 m²
- Level 102m, Area 200 m²

**Ground Level: 100m**

**Calculation:**
1. Segment 1 (95m → 98m): Both below ground
   - Volume = 3m × (100 + 150) / 2 = 375 m³

2. Segment 2 (98m → 102m): Crosses ground level at 100m
   - Interpolate area at 100m: 150 + (200-150) × (100-98)/(102-98) = 175 m²
   - Volume = 2m × (150 + 175) / 2 = 325 m³

**Total Excavation Volume: 700 m³**

## User Inputs

The script prompts for three parameters:

1. **Standard Trench Width (m)**: Default 1.5m - used for pipe trench calculations
2. **Cost per Cubic Meter ($/m³)**: Default $50/m³ - applied to all excavation volumes
3. **Export Results to CSV**: Default true - creates timestamped CSV file with detailed results

## Output

### Console Output

The script provides detailed output for each object:

**Pipe Example:**
```
Pipe: PIPE_001
  Length: 125.50 m
  US Depth: 2.30 m | DS Depth: 2.80 m | Avg: 2.55 m
  Volume: 479.57 m³
  Cost: $23,978.50
```

**Storage Node Example:**
```
Storage: TANK_001
  Ground Level: 100.00 m
  Storage Array: 5 points (95.00 to 102.00 m)
  Excavation Volume: 700.00 m³
  Cost: $35,000.00
```

**Summary:**
```
================================================================================
SUMMARY
================================================================================
Pipes processed: 15
Storage nodes/ponds processed: 3
Total objects processed: 18
Total excavation volume: 8,432.75 m³
Total estimated cost: $421,637.50
```

### CSV Export

The CSV file contains three sections:

1. **PIPES**: Detailed data for each pipe including:
   - Pipe ID, US/DS Node IDs
   - Length, depths (US/DS/Average)
   - Trench width, volume, cost

2. **STORAGE NODES AND PONDS**: Detailed data including:
   - Type (Storage/Pond), Node ID
   - Ground level, storage array details (points, min/max levels)
   - Volume, cost

3. **SUMMARY**: Aggregate statistics
   - Total counts by type
   - Total volume and cost
   - Input parameters used

**File naming:** `earthworks_estimate_YYYYMMDD_HHMMSS.csv`

## Usage Instructions

1. Open your network in InfoWorks ICM
2. Select the objects you want to estimate:
   - Select pipes using standard selection tools
   - Select storage nodes and/or ponds
   - You can select any combination of these objects
3. Run the script from the Ruby script menu
4. Enter your parameters in the prompt:
   - Trench width (for pipes)
   - Cost per cubic meter
   - Choose whether to export CSV
5. Review results in the output window
6. If CSV export was selected, find the file in the same directory as the script

## Error Handling

The script includes comprehensive validation and error reporting:

**Validation Checks:**
- Network is open
- Objects are selected
- Required data fields exist (ground levels, invert levels, storage arrays)
- Numeric values are valid and positive

**Warnings:**
- Pipes with inverts above ground level (depth set to 0)
- Storage nodes without storage array data
- Storage arrays entirely above ground level

All errors and warnings are reported in both the console output and included in the summary.

## Data Requirements

### For Pipes:
- `conduit_length`: Pipe length (m)
- `us_invert`, `ds_invert`: Invert elevations (m)
- Connected nodes must have `ground_level` defined

### For Storage Nodes/Ponds:
- `node_type`: Must be 'Storage' or 'Pond'
- `ground_level`: Ground elevation at node (m)
- `storage_array`: Level-area pairs defining storage volume
  - `level`: Elevation (m)
  - `area`: Surface area at that elevation (m²)

## Limitations and Assumptions

1. **Pipe Trenches:**
   - Assumes rectangular trench cross-section
   - Uses constant trench width along entire pipe length
   - Does not account for:
     - Pipe diameter
     - Bedding material
     - Trench side slopes
     - Over-excavation requirements

2. **Storage Structures:**
   - Assumes storage array accurately represents excavation geometry
   - Uses linear interpolation between storage array points
   - Does not account for:
     - Wall thickness
     - Base slab thickness
     - Construction access requirements

3. **General:**
   - Provides preliminary cost estimates only
   - Does not include:
     - Soil disposal costs
     - Dewatering requirements
     - Rock excavation premiums
     - Site access constraints
     - Mobilization costs

## Use Cases

- **Preliminary Cost Estimation**: Quick assessment of earthworks costs for capital planning
- **Scenario Comparison**: Compare excavation costs between different pipe routes or storage locations
- **Budget Development**: Generate volume estimates for detailed cost estimating
- **Construction Planning**: Identify high-cost excavation areas requiring special attention

## Technical Notes

### Storage Volume Algorithm

The script uses a robust algorithm to handle storage arrays that extend above ground level:

```ruby
# Handles three cases:
# 1. Both levels below ground → full segment volume
# 2. Lower below, upper above → partial volume with interpolation
# 3. Both levels above ground → skip segment
```

This ensures accurate volume calculations regardless of how the storage array is defined relative to ground level.

### Performance

The script processes objects sequentially and is suitable for:
- Small to medium networks (< 10,000 pipes)
- Any number of storage nodes/ponds

For very large networks, consider selecting specific areas of interest.

## Related Scripts

- **0073 - Populate storage array data**: Create or modify storage arrays
- **0062 - Export simulation results to CSV**: Export other types of data to CSV
- **0022 - Output CSV of calcs based on Subcatchment Data**: Similar CSV export patterns

## Naming Convention

This script uses InfoWorks ICM naming conventions:
- Tables: `hw_conduit`, `hw_node` (hw = HydroWorks, the original name of InfoWorks ICM)
- This script is specific to InfoWorks ICM networks and uses InfoWorks field names

## Version History

- **v1.0**: Initial release with pipe and storage node support
- Includes trapezoidal volume calculation for storage arrays
- CSV export with separate sections for pipes and storage
- Comprehensive error handling and validation

## Support and Contributions

For issues, improvements, or questions about this script, please refer to the main repository documentation or submit an issue on GitHub.

