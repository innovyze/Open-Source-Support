# Graph Subcatchment Results

## Overview

A UI script that graphs the total outflow breakdown of a selected subcatchment. It extracts simulation result fields (baseflow, trade flow, foul flow, RDII, surface runoff, LID flows, etc.) and produces two `WSApplication.graph()` windows:

1. **Overlay** - every flow component and `qcatch` as separate independent traces, useful for comparing magnitude and timing of individual flow sources.
2. **Cumulative over time** - each component is shown as its own running total through time (integrated by timestep), so lines remain individual rather than stacked on top of one another.

## Usage

1. Open a network in InfoWorks ICM with simulation results loaded.
2. Select **one** subcatchment.
3. Run `UI_Total_Outflow_Breakdown.rb` from the ICM UI.

Two graph windows will open showing the overlay and cumulative-over-time outflow breakdowns.

## Flow Components

The script attempts to retrieve the following result fields. Components that are absent or have no data are silently skipped.

| Field | Description |
|-------|-------------|
| `qcatch` | Total outflow |
| `qbase` | Baseflow |
| `qtrade` | Trade flow |
| `qfoul` | Foul flow |
| `qrdii` | RDII |
| `qground` | Ground store inflow |
| `qsoil` | Soil store inflow |
| `qsurf01`-`qsurf12` | Surface runoff (up to 12 surfaces) |
| `q_lid_in` | LID inflow |
| `q_lid_out` | LID outflow |
| `q_lid_drain` | LID drain |
| `q_exceedance` | Exceedance flow |

## Notes

- Exactly one subcatchment must be selected; a message box is shown otherwise.
- Results must be loaded before running the script.
- Each trace is colour-coded for easy identification in the legend.
- `qbase` is sourced from the subcatchment fixed field `base_flow` and repeated across all timesteps so it can be plotted and included in the cumulative graph.
- Zero-only component series are suppressed so the graphs only show contributors that are actually present.
- For design storms where time values are not valid DateTime values, the script falls back to numeric timesteps and labels the axis with inferred interval text (for example, `Timestep (5 minute intervals)`).
- Uses `_subcatchments` table alias so the script works on both InfoWorks and SWMM networks.
