# Calculate Pipe Gradient and Full Flow Capacity

This SQL script calculates two hydraulic properties for all circular conduits in a SWMM network and stores the results in user-defined fields.

> **Units: US customary only** (feet, cfs). Inverts and pipe dimensions must be in feet/inches as per ICM SWMM US unit conventions.

> **Object type:** Run with **All Links** selected as the object type in the SQL editor.

## What it Calculates

### `user_number_9` — Pipe Gradient (S)
The absolute slope of the pipe calculated from the difference in upstream and downstream invert levels divided by pipe length. A minimum value of 0.0001 is applied to avoid division by zero for flat pipes.

### `user_number_10` — Manning's Full Flow Capacity (cfs)
The theoretical full-pipe flow capacity for a circular conduit using Manning's equation:

**Q = (1.4859 / n) × A × R^(2/3) × S^(1/2)**

| Symbol | Description |
|---|---|
| Q | Full flow capacity (cfs) |
| n | Manning's roughness coefficient (`Mannings_N`) |
| A | Cross-sectional area = πD²/4 |
| R | Hydraulic radius = D/4 (full circular pipe) |
| S | Pipe gradient (`user_number_9`) |

## Use Case

Useful for capacity screening — once `user_number_10` is populated, it can be compared against peak simulated flows to identify pipes running near or at full capacity without needing to open the results viewer.
