# Multi-Simulation Report

A Ruby UI script for InfoWorks WS Pro that analyzes simulation results to identify pressure and velocity violations across multiple runs and simulations.

## Overview

This script automates the process of reviewing simulation results to find:
- **Pressure violations**: Customer points (or nodes) where the minimum pressure falls below a specified threshold
- **Velocity violations**: Pipes where the maximum velocity exceeds a specified threshold

Results are grouped by Run and presented in a formatted table report.

## Features

- Automatically discovers all Runs in the parent model group of the current network
- Multi-select interface: choose which Runs to analyze using checkboxes
- Configurable thresholds for pressure and velocity
- Iterates through all simulations under each selected Run
- Calculates velocity from flow and diameter when direct velocity results are unavailable
- Generates a formatted console report with per-run and grand totals
- Option to save the report to a text file

## Requirements

- InfoWorks WS Pro 2026 or later
- A network must be open in the UI
- Run objects with completed simulations must exist in the same model group as the network

## Usage

1. Open a network in InfoWorks WS Pro
2. Run the script from the Network menu (Network > Run Ruby Script...)
3. Select which Runs to analyze using the checkboxes
4. Set the minimum pressure threshold (default: 10 m)
5. Set the maximum velocity threshold (default: 3 m/s)
6. Click OK to run the analysis
7. Review the results in the console output
8. Optionally save the report to a text file when prompted

## Configuration

Set `ENABLE_LOGGING = true` at the top of the script to see detailed progress output during execution.

```ruby
ENABLE_LOGGING = true  # Set to true to see detailed progress output
```

## Report Format

The report displays results grouped by Run:

```
================================================================================
MULTI-SIMULATION REPORT
================================================================================

Generated: 2025-12-11 14:30:00
Min Pressure Threshold: 10.0 m
Max Velocity Threshold: 3.0 m/s

--------------------------------------------------------------------------------
RUN: Base Case Run
--------------------------------------------------------------------------------
Simulation            Pressure Violations   Velocity Violations
------------------------------------------------------------------
Control                                 5                     2
Peak Demand                            12                     8
------------------------------------------------------------------
Run Total                              17                    10

--------------------------------------------------------------------------------
RUN: Future Scenario Run
--------------------------------------------------------------------------------
Simulation            Pressure Violations   Velocity Violations
------------------------------------------------------------------
2030 Growth                            23                    15
------------------------------------------------------------------
Run Total                              23                    15

================================================================================
GRAND TOTALS
================================================================================
Runs analyzed: 2
Total simulations: 3
Total pressure violations: 40
Total velocity violations: 25
```

## Technical Notes

### Pressure Analysis
The script first attempts to analyze customer points (`wn_address_point`). If none are found or if no violations are detected at customer points, it falls back to analyzing nodes (`wn_node`).

### Velocity Calculation
The script attempts to read velocity results directly from pipes. If the `velocity` result field is not available, it calculates velocity from:
- Flow results (assuming l/s)
- Pipe diameter (assuming mm, converted to m)

Formula: `velocity = (flow / 1000) / (π × (diameter/2000)²)`

### Simulation Status
Only simulations with a "Success" status are analyzed. Failed or incomplete simulations are skipped and marked as "N/A" in the report.

## Error Handling

- The script handles cases where a simulation is already open on the network
- Graceful handling of missing tables or result fields
- Clear error messages for common issues (no network open, no runs found, etc.)

## Related Documentation

- [WSApplication Class](https://help.autodesk.com/view/IWWSPRO/ENU/?guid=GUID-WSApplication)
- [WSOpenNetwork Class](https://help.autodesk.com/view/IWWSPRO/ENU/?guid=GUID-WSOpenNetwork)
- [WSRowObject Class](https://help.autodesk.com/view/IWWSPRO/ENU/?guid=GUID-WSRowObject)

## License

This script is provided as-is under the MIT License. See the repository root for full license terms.

