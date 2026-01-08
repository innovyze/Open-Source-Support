# Tank and Pump Graph

Interactive Python script for visualizing tank levels and pump flows from InfoWater Pro simulation results.

## Description

This script provides an interactive GUI for selecting tanks and pumps from an InfoWater Pro model and displaying their simulation results on a time-series graph. It features:

- **Dual Y-axis plotting**: Tank data on the left axis (blue), pump data on the right axis (red)
- **Interactive element selection**: Choose which tanks and pumps to include via a dialog
- **Output type options**: 
  - Tanks: Level (ft) or % Volume
  - Pumps: Flow or Status (0/1)
- **Flow unit conversion**: CFS, GPM, MGD, or GPD
- **Interactive legend table**: Toggle visibility of individual lines with checkboxes
- **Summary statistics**: Min, Max, Average, and Range values displayed in the legend table
- **Zoom/pan toolbar**: Standard matplotlib navigation tools

## Requirements

### Environment
- **ArcGIS Pro** with Python environment (runs from Python window or Notebook)
- **InfoWater Pro** installed with Standard EPS simulation results available

### Python Packages (included with ArcGIS Pro)
- `matplotlib` - Plotting library
- `arcpy` - ArcGIS Python library
- `tkinter` - GUI framework
- `numpy` - Numerical operations

### InfoWater Pro Package
- `infowater.output.manager` - InfoWater Pro output manager API

## Usage

1. Open your InfoWater Pro project in ArcGIS Pro
2. Ensure you have run a simulation with results saved
3. Open the Python window or a new Notebook in ArcGIS Pro
4. Run the script:
   ```python
   exec(open(r"path\to\Tank_Pump_Graph.py").read())
   ```

5. In the selection dialog:
   - Select one or more tanks from the left list
   - Select one or more pumps from the right list
   - Choose output types (Level/% Volume for tanks, Flow/Status for pumps)
   - Select flow units if using pump flow
   - Choose which summary statistics to display
   - Click "Generate Plot"

6. In the plot window:
   - Use checkboxes to show/hide individual lines
   - Use "Show All" / "Hide All" buttons for bulk visibility changes
   - Use the matplotlib toolbar to zoom, pan, and save the figure
   - Click "Close" when finished

## Output

The script produces an interactive plot window with:
- Time series graph with tank and pump data
- Interactive legend table with visibility toggles
- Summary statistics for each element

## Notes

- The script auto-detects the current ArcGIS Pro project and available scenarios
- If multiple scenarios exist, the first one is used by default
- Elements with no available data are automatically skipped with a warning message
