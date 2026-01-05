# Pressure Zone Water Balance

Interactive Python script for analyzing water balance across pressure zones in InfoWater Pro models.

## Description

This script provides a comprehensive water balance analysis for any pressure zone defined in the InfoWater Pro Pressure Zone Manager (PZM). It creates an interactive 2-panel visualization:

### Panel 1: Storage & Pressure
- **Tank Levels**: Water level (ft) or % Volume for all tanks in the zone
- **Zone Pressure Extremes**: Min/Max pressure from junctions within the zone (secondary Y-axis)

### Panel 2: Net Flow Balance
- **Inflows** (plotted positive): Reservoirs, Pumps, Valves, and Pipes flowing INTO the zone
- **Outflows** (plotted negative): Reservoirs, Pumps, Valves, and Pipes flowing OUT of the zone
- **Total Inflow**: Sum of all inflows (green line)
- **Total Outflow**: Sum of all outflows (red line, negative)
- **Total Demand**: Calculated as `Inflow - Outflow - Tank Flow` (black dashed line)

## Key Features

- **Auto-detection of pressure zones** from PZM data (reads PZMZONE.DBF, PZMTANK.DBF, PZMPUMP.DBF, etc.)
- **Junction zone assignment** via configurable field name (default: ZONEID)
- **Zero-flow filtering** option to hide closed/inactive boundary elements
- **Flow unit conversion**: CFS, GPM, MGD, or GPD
- **Interactive legend tables** with visibility toggles for each line
- **Export to CSV** with all time series data and summary statistics
- **Zoom/pan toolbar** for detailed analysis

## Requirements

### Configuration
Before running this script, you must complete the following steps in InfoWater Pro:

1. **Run the Pressure Zone Manager (PZM) module** to trace pressure zones and generate the prerequisite DBF files (PZMZONE.DBF, PZMTANK.DBF, PZMPUMP.DBF, PZMVALVE.DBF, PZMPIPE.DBF, PZMRES.DBF)
2. **Run a standard EPS (Extended Period Simulation)** and ensure it is set as the current active output

### Environment
- **InfoWater Pro 2026** or higher
- **ArcGIS Pro** with Python environment

### Python Packages (included with ArcGIS Pro)
- `matplotlib` - Plotting library
- `arcpy` - ArcGIS Python library (used for DBF file reading)
- `tkinter` - GUI framework
- `numpy` - Numerical operations

### InfoWater Pro Package
- `infowater.output.manager` - InfoWater Pro output manager API

## Configuration

At the top of the script, you can modify the zone field name if your model uses a different attribute:

```python
ZONE_FIELD_NAME = "ZONEID"  # Field in JUNCTION.DBF that contains zone assignment
```

## Usage

1. Open your InfoWater Pro project in ArcGIS Pro
2. Ensure you have:
   - Pressure Zone Manager data configured
   - Run a simulation with results saved
3. Open the Python window or a new Notebook in ArcGIS Pro
4. Run the script:
   ```python
   exec(open(r"path\to\PZ_Water_Balance.py").read())
   ```

5. In the selection dialog:
   - Select a pressure zone from the list (shows junction/element counts)
   - Select a scenario with available results
   - Configure output options (tank output type, flow units)
   - Enable/disable data filtering and panel visibility options
   - Click "Analyze"

6. In the plot window:
   - Toggle panel visibility using checkboxes
   - Show/hide individual lines via the legend tables
   - Use "Export to CSV" to save all data
   - Use the matplotlib toolbar to zoom, pan, and save figures

## Water Balance Calculation

The **Total Demand** is calculated as:

```
Total Demand = Total Inflow - Total Outflow - Tank Flow
```

Where:
- **Total Inflow**: Sum of all flows entering the zone (positive values)
- **Total Outflow**: Sum of all flows leaving the zone (positive values)
- **Tank Flow**: Flow into tanks (positive = filling = water leaving zone demand)

This represents the net consumption within the pressure zone at each timestep.

## Output

### Interactive Plot
- 2-panel time series graph with dual Y-axes on the storage panel
- Color-coded lines by element type (Tanks=blue, Reservoirs=red, Pumps=green, Valves=orange, Pipes=purple)
- Interactive legend tables with Min/Max/Avg statistics

### CSV Export
- Header information (zone, scenario, units)
- Time series data for all elements
- Summary statistics section

## Screenshots

### Options Dialog
Select a pressure zone from the list, configure output options, data filtering, and panel visibility settings.

![Options Dialog](PZ%20Water%20Balance%20Options.png)

### Main Display
Interactive 2-panel visualization with storage/pressure and net flow balance charts, legend tables with visibility toggles, and export functionality.

![Main Display](PZ%20Water%20Balance%20UI.png)

## Notes

- The script auto-detects the current ArcGIS Pro project and available scenarios
- Zones without data (no tanks, no boundary flows) will show a warning
- Zero-flow boundary elements can be optionally filtered out
- Pressure extremes are identified using `get_all_range_data` for efficient lookup

