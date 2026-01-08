# Zonal Outflow Analysis

Analyze junction-level outflow components for a selected pressure zone in InfoWater Pro, including demand, leakage, and unsatisfied demand breakdowns.

![Zonal Outflow Summary](Zonal%20Outflow%20Summary.png)

## Overview

This script aggregates and visualizes outflow data across all junctions within a pressure zone, providing insight into:

- **Total Zone Outflow** - Sum of all junction outflows
- **Required Demand** - The requested/base demand from demand patterns
- **Actual Demand** - The demand actually satisfied during simulation
- **Adjacent Pipe Leakage** - Leakage outflow from pipes connected to junctions (requires leakage simulation)
- **Unsatisfied Demand** - Demand that could not be satisfied due to low pressure (calculated as Required - Actual)

## Requirements

- **InfoWater Pro 2024** or later with Python API
- **ArcGIS Pro** with an active project containing the InfoWater Pro model
- **Pressure Zone Manager (PZM)** data configured in the model
- **Simulation results** (HYDQUA.OUT) for at least one scenario
- **Zone assignment field** in JUNCTION.DBF (default: `ZONEID`)

### Optional Simulation Settings

For full analysis capabilities, enable these simulation options:
- **Emitter/Leakage** - Required for Adjacent Pipe Leakage data
- **Pressure-Dependent Demand (PDD)** - Required for meaningful Unsatisfied Demand analysis

## Features

### Interactive Selection Dialog
- Select from available pressure zones with junction counts
- Choose scenario with existing simulation results
- Select flow units (CFS, GPM, MGD, GPD)
- Toggle optional analysis fields (Leakage, Unsatisfied Demand)

### Progress Tracking
- Real-time progress bar during data collection
- Displays percentage complete and junction count

### Interactive Time Series Plot
- Multi-line graph showing all outflow components
- Toggle individual line visibility via checkboxes
- Matplotlib navigation toolbar (zoom, pan, save image)
- Automatic legend with line style previews

### Statistics Table
- Min, Max, and Average flow rates for each component
- Total integrated volume over simulation period
- Junction ID with highest contribution for each metric
- Proper volume units (ft³, gallons, MG) based on flow unit selection

### CSV Export
- Export summary metrics and full time series data
- Includes header information (zone, scenario, units)
- Compatible with Excel and other analysis tools

## Usage

### Running the Script

1. Open your InfoWater Pro model in ArcGIS Pro
2. Run a simulation to generate results
3. Open the Python window in ArcGIS Pro
4. Load and execute `Zonal_Outflow_Analysis.py`:

```python
exec(open(r'path\to\Zonal_Outflow_Analysis.py').read())
```

Or copy/paste the script content directly into the Python window.

### Configuration

The default zone field name is `ZONEID`. If your model uses a different field:

```python
# Modify this line at the top of the script
ZONE_FIELD_NAME = "YOUR_ZONE_FIELD"
```

## Output Interpretation

### Flow Components

| Component | Description |
|-----------|-------------|
| **Outflow** | Total water leaving each junction (= Actual Demand + Leakage) |
| **Required Demand** | Base demand from patterns (what was requested) |
| **Actual Demand** | Demand actually satisfied (may be less than required under low pressure) |
| **Adjacent Pipe Leakage** | Leakage from pipes connected to the junction |
| **Unsatisfied Demand** | Required - Actual (only non-zero with PDD and low pressure) |

### Volume Calculations

Volumes are calculated by integrating flow over time using the trapezoidal rule:

| Flow Unit | Volume Unit | Conversion |
|-----------|-------------|------------|
| CFS | ft³ | × 3600 s/hr |
| GPM | gallons | × 60 min/hr |
| MGD | MG | ÷ 24 hr/day |
| GPD | gallons | ÷ 24 hr/day |

### Understanding the Graph

- **Navy solid line**: Total Outflow (sum of all outflow from zone junctions)
- **Purple dashed line**: Required Demand (what the zone requested)
- **Green solid line**: Actual Demand (what was delivered)
- **Red dashed line**: Adjacent Pipe Leakage (water lost to leaks)
- **Orange solid line**: Unsatisfied Demand (gap between required and actual)

When the system operates normally at adequate pressure:
- Actual Demand ≈ Required Demand
- Unsatisfied Demand ≈ 0
- Outflow = Actual Demand + Leakage

Under low pressure conditions:
- Actual Demand < Required Demand
- Unsatisfied Demand > 0
- The graph reveals pressure-deficient periods

## File Structure

```
Zonal_Ouflow_Summary/
├── Zonal_Outflow_Analysis.py    # Main analysis script
├── Zonal Outflow Summary.png    # Example output screenshot
└── README.md                    # This file
```

## Troubleshooting

### "Pressure Zone Manager data not found"
Ensure PZM is configured in your model. Create pressure zones using the Pressure Zone Manager in InfoWater Pro.

### "No scenarios with HYDQUA.OUT results found"
Run a hydraulic simulation first. The script requires existing output files.

### Missing Leakage or Unsatisfied Demand data
- **Leakage**: Enable Emitter/Leakage in simulation options
- **Unsatisfied Demand**: Enable Pressure-Dependent Demand (PDD) in simulation options

### Wrong zone assignments
Verify the `ZONE_FIELD_NAME` matches your junction zone field in JUNCTION.DBF.

## Related Scripts

- [Pressure Zone Water Balance](../Pressure%20Zone%20Water%20Balance/) - Comprehensive water balance analysis with inflows, outflows, and storage
- [Tank and Pump Graph](../Tank%20and%20Pump%20Graph/) - Simple tank level and pump flow visualization

## License

This script is provided as-is for use with InfoWater Pro. See the main repository license for terms.

