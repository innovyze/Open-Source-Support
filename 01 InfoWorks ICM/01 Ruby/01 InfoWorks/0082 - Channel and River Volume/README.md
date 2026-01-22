# Channel and River Reach Storage Volume Calculators

This folder contains Ruby scripts for calculating water storage volumes in InfoWorks ICM channel and river reach objects. These are currently excluded from the in-built 'storage volume' calculation tool.

## Scripts

### Channel_Storage_Volume.rb

Calculates water storage volume for selected `hw_channel` links based on their cross-section shape profiles.

**How it works:**
1. Prompts user for a water level (mAD)
2. For each selected channel:
   - Retrieves the cross-section shape from `hw_channel_shape`
   - Clips the cross-section polygon at the water level using linear interpolation
   - Calculates wetted area using the shoelace formula
   - Adjusts for channel gradient (slope-adjusted length)
   - Computes volume = area × slope-adjusted length

**Usage:**
1. Open a network in GeoPlan
2. Select one or more `hw_channel` links
3. Run the script
4. Enter the water level when prompted

**Output:** Volume for each channel and total volume across all selected channels.

---

### River_Reach_Storage_Volume.rb

Calculates water storage volume for selected `hw_river_reach` links using cross-section survey data.

**How it works:**
1. Gathers statistics from all selected reaches (invert range, bank elevations, section heights)
2. Prompts user to select calculation method:
   - **Method 1 - Full section capacity:** Water level at maximum bank elevation per section
   - **Method 2 - By depth:** User specifies depth above invert (applies to each section)
   - **Method 3 - By elevation:** User specifies absolute water level (mAD)
3. For each reach:
   - Reads centreline geometry from `point_array`
   - Calculates chainage for each section by projecting section midpoint onto centreline
   - Computes horizontal offset across each section from XY coordinates
   - Calculates wetted area at each section using shoelace formula
   - Integrates volume using trapezoidal rule between adjacent sections

**Usage:**
1. Open a network in GeoPlan
2. Select one or more `hw_river_reach` links
3. Run the script
4. Select calculation method and enter parameters when prompted

**Output:** Per-section data (chainage, invert, water level, area) and total volume.

---

## Technical Notes

### Coordinate Systems

**Channel shapes** use:
- `x` = horizontal offset across section (m)
- `y` = elevation (mAD)

**River reach sections** use:
- `X`, `Y` = map coordinates (eastings, northings)
- `Z` = elevation (mAD)

### Chainage Calculation

River reach chainages are **not stored** in the sections blob. They are calculated by:
1. Reading the reach centreline from `point_array`
2. Finding the closest point on the centreline to each section's midpoint
3. Computing cumulative distance along the centreline

### Volume Integration

Both scripts use **trapezoidal integration**:
```
Volume = Σ [(Area₁ + Area₂) / 2 × distance]
```

---

## Limitations & Differences from ICM Engine

### Channel Script Limitations

- Assumes uniform cross-section along channel length
- Gradient adjustment uses simple slope-adjusted length formula
- Does not account for hydraulic transitions or backwater effects

### River Reach Script vs ICM Simulation Results

The script typically produces volumes similar to ICM's internal calculations. Differences arise from:

| Factor | Script | ICM Engine |
|--------|--------|------------|
| **Sections** | Uses only defined cross-sections | Interpolates additional sections |
| **Water surface** | Flat (same level at all sections for Method 3) | May slope along reach |
| **Integration** | Trapezoidal (linear between sections) | May use different interpolation |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01 | Initial release |