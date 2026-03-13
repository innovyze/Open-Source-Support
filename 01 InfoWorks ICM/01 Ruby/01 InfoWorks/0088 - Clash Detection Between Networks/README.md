# Clash detection between networks

## Overview

This UI Ruby script detects vertical clashes between nearby links in the current network.
It supports both InfoWorks ICM and InfoWorks WS Pro, using a grid-based 2D pre-filter to reduce pair checks before computing vertical clearance.

A clash is reported when computed clearance is less than or equal to the user threshold.

## What it checks

- Uses selected links only (if any are selected), otherwise checks all links in the detected link table.
- Builds candidate pairs using XY proximity (`XY_TOL_M`) to avoid full pairwise comparison.
- Computes invert-at-intersection and pipe size/height to estimate clearance.
- Flags pairs as clashes when clearance `<= threshold` (with a small vertical tolerance).

## Supported tables

The script auto-detects the first available populated link table from:

- WS Pro: `wn_pipe`, `wn_connection`, `wn_valve`, `wn_pump`
- ICM: `hw_pipe`, `hw_conduit`, `hw_link`, `hw_connection`

For label points, it also tries common user/point tables for WS Pro and ICM.

## Usage

1. Open a network in the ICM/WS Pro UI.
2. (Optional) Select links to limit scope.
3. Run `UI_script.rb` from an Action.
4. Enter:
   - **Minimum vertical clearance (m)** for clash detection
   - **2D proximity tolerance (m)** for candidate pairing

## Outputs

- Console report with:
  - links processed
  - candidate pairs
  - clashes found
  - clash pair list and clearance values
- Selection list (when supported) or direct link selection fallback.
- Optional clash label points prefixed with `[CLR]`.
- CSV report written to the OS temp directory.

## Notes

- The script removes prior `[CLR]` labels before creating new ones.
- Shared-node pairs are excluded by default (`INCLUDE_SHARED_NODES = false`).
- Input values are clamped to non-negative numbers.
- Geometry/field access is handled defensively to support version/product differences.
