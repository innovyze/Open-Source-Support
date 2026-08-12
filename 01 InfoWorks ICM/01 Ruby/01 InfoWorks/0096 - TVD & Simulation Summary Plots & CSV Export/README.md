# TVD & Simulation Summary Plots & CSV Export

InfoWorks (`hw_*`) UI script for simulation validation and auditing. It produces in-ICM graphs similar in purpose to the **Simulation Summary Plot**, plus a single CSV with one row per timestep.

## Overview

The script aggregates subcatchment wastewater/RDII flows, node flood storage, lost volume, and outfall discharge across the GeoPlan selection (or the whole network when nothing is selected). Graphs open in ICM; tabular output is written to one CSV file for Excel or further analysis.

## Usage

1. Open a network in InfoWorks ICM with simulation results loaded on the GeoPlan.
2. Optionally select subcatchments, nodes, and/or links on the GeoPlan.
3. Run [UI_script.rb](UI_script.rb) from the ICM UI script menu.
4. Review the graphs and open `C:\Temp\simulation_summary.csv`.

## Prerequisites

- Completed simulation with results loaded on the GeoPlan (drag result onto the network view).
- `C:\Temp` folder (created automatically if missing).

## Selection behaviour

| Goal | Action |
|------|--------|
| All subcatchments / nodes | Leave nothing selected |
| Selected subcatchments or nodes only | Select on GeoPlan before running |
| All outfall links (default) | Leave link selection empty |
| Selected outfall links only | Select links on GeoPlan |

Empty selection falls back to all objects automatically. Outfall link discovery is independent of node selection.

## What it reports

### Subcatchment wastewater / RDII breakdown

- `qtrade`, `qfoul`, `qrdii` summed across selected or all subcatchments
- `qcatch` as reference total outflow (includes runoff and other paths)
- `QCATCH minus three-flow` delta (informational, not pass/fail)

### Node / outfall metrics

| Metric | Source | Unit | Notes |
|--------|--------|------|-------|
| Positive flood storage | `floodvolume > 0` on nodes in scope | m3 | Excludes negative storage |
| Total floodvolume | all `floodvolume` on nodes in scope | m3 | Includes negative values |
| Cumulative lost volume | `flvol > 0` on lost nodes in scope | m3 | Matches OSS SQL 0051 / TVD Total lost |
| Outfall discharge | link `ds_flow` to outfall nodes | L/s / m3 | From all network links unless links are selected |

## Graphs

1. Wastewater/RDII instantaneous (L/s) — display values are m3/s x 1000
2. Wastewater/RDII cumulative volume (m3) — INTEGRAL x 60 on raw result values
3. QCATCH minus three-flow delta (informational)
4. Positive flood storage + lost volume (m3)
5. Total floodvolume all nodes (m3)
6. Outfall discharge instantaneous (L/s)
7. Outfall discharge cumulative (m3)

## CSV columns

| Column | Unit | Meaning |
|--------|------|---------|
| timestep | - | 1-based step number |
| rel_minutes | min | Minutes from simulation start |
| qtrade_ls, qfoul_ls, qrdii_ls | L/s | Instantaneous flows (m3/s x 1000 for display) |
| qcatch_ls | L/s | Reference total subcatchment outflow (display) |
| delta_ls | L/s | QCATCH minus three-flow |
| qtrade_m3, qfoul_m3, qrdii_m3, qcatch_m3 | m3 | Cumulative volumes (INTEGRAL x 60) |
| flood_positive_m3 | m3 | Sum of positive floodvolume only |
| flood_all_m3 | m3 | Sum of all floodvolume (includes negative) |
| lost_m3 | m3 | Sum of positive flvol on lost nodes in scope |
| outfall_ls | L/s | Sum of outfall ds_flow (display) |
| outfall_m3 | m3 | Cumulative outfall discharge (INTEGRAL x 60) |

Cumulative volumes use INTEGRAL x 60 on raw m3/s result values (TVD Summary / OSS SQL 0051). Instantaneous flow columns multiply by 1000 for L/s display.

## Notes

- InfoWorks networks only (`hw_*` tables).
- Results must be loaded before running the script.
- Works with both relative and absolute time simulations. Cumulative volume uses the absolute difference between consecutive timestep values, so relative-time negative seconds are handled correctly.
- For design storms where time values are not valid DateTime values, the script falls back to numeric timesteps and labels the axis with inferred interval text