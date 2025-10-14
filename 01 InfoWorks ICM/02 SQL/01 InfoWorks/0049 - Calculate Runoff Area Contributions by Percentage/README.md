# Calculate Runoff Area Contributions (Auto-Detect Percent or Absolute)

This SQL script intelligently calculates the total contributing area for each runoff area (1-12) in subcatchments by automatically detecting whether each subcatchment uses percentage or absolute values.

## Overview

For each subcatchment, the script:
1. Checks the `area_measurement_type` field to determine calculation method
2. **If "Percent"**: Multiplies `area_percent_X` by `contributing_area` 
3. **If "Absolute"**: Uses `area_absolute_X` directly
4. Sums all values across subcatchments
5. Groups results by `system_type` into a single summary table

This works seamlessly even if your network has a mix of subcatchments using different measurement types!

## Calculation Method

The script uses InfoWorks ICM's `IIF()` function for conditional logic:

```sql
IIF(area_measurement_type = 'Percent', 
    (area_percent_X / 100.0) * contributing_area,  // Percent calculation
    area_absolute_X)                               // Absolute value
```

**Examples:**

*Subcatchment with Percent measurement:*
- Contributing Area = 10 hectares
- area_percent_1 = 35%
- Result = (35 / 100.0) × 10 = 3.5 hectares

*Subcatchment with Absolute measurement:*
- area_absolute_1 = 2.5 hectares
- Result = 2.5 hectares (used directly)

## Output

The query produces a single summary table grouped by system type with the following columns:

- **SYSTEM_TYPE** - System classification (Foul, Storm, Combined, etc.)
- **Runoff_Area_1 to Runoff_Area_12** - Total calculated areas for each runoff area across all subcatchments

All values are automatically calculated using the appropriate method based on each subcatchment's `area_measurement_type` setting.

## Quick Reference

| Field | Description |
|-------|-------------|
| `area_measurement_type` | Determines calculation method: "Percent" or "Absolute" |
| `area_percent_1` to `area_percent_12` | Percentage values (0-100) - used when type is "Percent" |
| `area_absolute_1` to `area_absolute_12` | Absolute area values - used when type is "Absolute" |
| `contributing_area` | Total contributing area of the subcatchment |
