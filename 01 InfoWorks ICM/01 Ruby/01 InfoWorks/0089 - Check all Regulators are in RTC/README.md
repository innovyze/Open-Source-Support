# Check all Regulators are in RTC

## Overview

This UI Ruby script checks whether RTC-dependent regulator objects in the current InfoWorks network have corresponding entries in the RTC editor. Objects that control their behaviour via RTC but are not referenced in the RTC definition will operate with a fixed opening and may produce unexpected simulation results.

## Background

Several regulator link types in InfoWorks ICM are designed to be controlled via Real Time Control (RTC). When such objects exist in the network but have no RTC entry, they silently run with a fixed opening — no warning is raised during standard validation or engineering validation, because the RTC editor is not exposed as an Object Type in User Rules.

This script bridges that gap by cross-referencing regulator objects against the raw RTC data blob (`hw_rtc.rtc_data`).

## What it checks

| Table | Link Types | Severity if missing |
|---|---|---|
| `hw_blockage` | All | WARNING |
| `hw_pump` | `FIXPMP` | INFO (optional — can run on switch levels) |
| `hw_orifice` | `Vldorf` | WARNING |
| `hw_sluice` | `VSGate`, `RSGate`, `VRGate` | WARNING |
| `hw_weir` | `VCWEIR`, `VWWEIR`, `GTWEIR` | WARNING |

- **WARNING** — the object type requires RTC to operate as an adjustable control.
- **INFO** — RTC is beneficial but the object can function without it.

## Output

Results are printed to the Ruby output window, grouped by severity:

```
=== WARNING: Objects that require RTC but are NOT found in the RTC editor ===
  hw_sluice  MH_001.1  (link_type: VSGate)

=== INFO: Objects that may benefit from RTC but are NOT configured ===
  hw_pump  PS_002.1  (link_type: FIXPMP)

Total: 1 required, 1 optional missing from RTC
```

If all objects are configured, the script prints:

```
All RTC-dependent objects are configured in RTC.
```

## Usage

1. Open an InfoWorks network in the ICM UI.
2. Run `UI_script.rb` as a UI Action script.
3. Review the output window for any missing RTC entries.

## Notes

- Object IDs are matched against the RTC text blob using `us_node_id.link_suffix`. Export your RTC to a text file first (see [0015 - Import or Export RTC to txt](../0015%20-%20Import%20or%20Export%20RTC%20to%20txt/README.md)) to confirm the ID format used in your model if unexpected results are returned.
- This script reads data only — no changes are made to the network.
