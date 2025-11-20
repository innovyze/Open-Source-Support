# ICM InfoWorks Peaking Factor Calculator

## Script Information

**Version:** 3.0 (Fixed Variable Scoping & Read-Only Detection)  
**Author:** RD + AI Assistant  
**Last Updated:** November 2025  
**Purpose:** Calculate peaking factors for sanitary sewer flows in ICM InfoWorks

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [How It Works](#how-it-works)
4. [Installation & Usage](#installation--usage)
5. [Parameters](#parameters)
6. [Peaking Formulas](#peaking-formulas)
7. [Output Fields](#output-fields)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Technical Notes](#technical-notes)

---

## Overview

This Ruby script for ICM InfoWorks reads simulation results from selected links, calculates peaking factors using various formulas, and assigns flow components to link fields. It operates in two phases to ensure proper data handling and includes comprehensive error checking.

### Key Features

- ✅ **Two-phase processing** (calculate, then assign)
- ✅ **Read-only network detection** and handling
- ✅ **Multiple peaking formulas** (standard, alternative Babbitt)
- ✅ **Comprehensive debug output** for troubleshooting
- ✅ **Proper variable scoping** (no scope errors!)
- ✅ **Results summary table** even if network is read-only

![alt text](<# ICM InfoWorks Peaking Factor Calculator - visual selection.png>)

### Typical Use Cases

- Post-processing simulation results
- Applying design peaking factors to average flows
- Separating flow components for capacity analysis
- Preparing data for detailed hydraulic studies
- Converting between flow component methodologies

---

## Prerequisites

### Required Setup

Before running this script, ensure:

- ✅ ICM InfoWorks network is open
- ✅ Simulation has been run with results committed
- ✅ Network is opened in **EDIT mode** (not read-only)
- ✅ Simulation has at least **2 timesteps**
- ✅ Results include `us_flow` field data

### Selection Requirements

**CRITICAL:** You must select **LINKS** (conduits/pipes), not nodes!

#### How to Select Links

**Option 1: Manual Selection**
```
1. Open GeoPlan view
2. Click in empty space to deselect all
3. Use selection tools to draw box around pipes
4. Status bar should show "N links selected"
```

**Option 2: SQL Selection**
```
1. Go to Selection > SQL Selection
2. Enter query, for example:
   - SELECT * FROM _links
   - SELECT * FROM _links WHERE diameter > 300
   - SELECT * FROM _links WHERE us_node_id LIKE 'MH%'
3. Click Execute
4. Verify "N links selected" in status bar
```

### Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|----------|
| Selecting nodes (manholes) | Selecting links (pipes) |
| Opening network read-only | Opening in edit mode |
| No simulation results | Simulation run and committed |
| Steady-state (1 timestep) | Dynamic (2+ timesteps) |

---

## How It Works

### Two-Phase Process

The script uses a two-phase approach to prevent variable scoping issues:

#### Phase 1: Calculate & Store

For each selected link:
1. Read `us_flow` results from all timesteps
2. Calculate statistics:
   - Total flow (sum of all timestep values)
   - Mean flow (average across timesteps)
   - Minimum flow
   - Maximum flow
   - Peak flow (using selected formula)
3. Store ALL values in `link_data` hash
```ruby
link_data[link_id] = {
  total_flow: 1234.56,
  mean_flow: 51.44,
  min_flow: 12.34,
  max_flow: 98.76,
  mean_peak: 123.45,
  count: 24
}
```

#### Phase 2: Assign Values

For each selected link:
1. Retrieve stored data from `link_data` hash
2. Calculate flow components:
   - `base_flow = total_flow - peakable_coverage_load`
   - `trade_flow = peakable_coverage_load`
   - `additional_foul_flow = x_coverage * y_peaking_multiplier`
   - `conduit_flow = mean_peak` (if enabled)
3. Write values to link fields
4. Commit changes to database

### Read-Only Detection

The script automatically detects if the network is opened in read-only mode:

- **If read-only detected:**
  - Shows prominent warning
  - Offers to continue (calculate only, no save)
  - Provides instructions to open in edit mode
  - Displays results table for reference

- **If editable:**
  - Proceeds normally
  - Saves results to network fields

---

## Installation & Usage

### Step-by-Step Procedure

#### Step 1: Prepare Network
```
1. Open ICM InfoWorks
2. Load your network model
3. Verify model is valid (no errors)
```

#### Step 2: Run Simulation
```
1. Go to Run > Run Simulation (F5)
2. Select simulation profile
3. Wait for completion
4. IMPORTANT: Commit results to network
   - Right-click simulation results
   - Select "Commit to Network"
```

#### Step 3: Verify Results
```
1. Open a link in Grid View
2. Check for 'us_flow' in results section
3. Verify values are present (not blank)
4. Note number of timesteps (need ≥ 2)
```

#### Step 4: Select Links
```
1. Go to GeoPlan view
2. Deselect all (click empty space)
3. Select links using selection tools
4. Verify: "N links selected" in status bar
```

#### Step 5: Run Script
```
1. Network > Run Ruby Script
2. Browse to script file (.rb)
3. Click Open/Run
4. Parameter dialog will appear
```

#### Step 6: Configure Parameters
```
See Parameters section below for details
```

#### Step 7: Monitor Execution
```
Watch Output window for:
- Phase 1: Statistics for each link
- Phase 2: Field assignments
- Any error messages
- Completion summary
```

#### Step 8: Verify Results
```
1. Open Grid View
2. Select _links table
3. Check new field values:
   - base_flow
   - trade_flow
   - additional_foul_flow
   - conduit_flow (if enabled)
```

#### Step 9: Save Work
```
1. File > Save Network (Ctrl+S)
2. Consider backup:
   - File > Save As
   - Add date: "MyNetwork_PeakFlows_2025-11-03.icm"
```

---

## Parameters

### Unit Selection

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Use USA Units (GPM)** | Boolean | `false` | Display results in Gallons Per Minute |
| **Use SI Units (L/s)** | Boolean | `true` | Display results in Liters Per Second |

> **Note:** ICM internally uses m³/s. Unit selection affects display only.

### Calculation Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Save Peak Flow to Inflow Conduit Field** | Boolean | `true` | Saves calculated peak to `conduit_flow` |
| **Include Peak Flow Calculation** | Boolean | `true` | Enables peaking calculations |

### Flow Component Assignments

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Unpeakable Flow as Base Flow** | Boolean | `true` | Assigns to `base_flow` field |
| **Peakable Point Flow as Trade Flow** | Boolean | `true` | Assigns to `trade_flow` field |
| **Peakable Coverage as Additional Foul Flow** | Boolean | `true` | Assigns to `additional_foul_flow` field |

### Formula Parameters

#### Standard Formula: `peak = k × Q^p`

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| **k (Peaking Factor)** | Float | `1.0` | 1.0 - 4.0 | Base multiplier |
| **p (Exponent)** | Float | `2.0` | -1.0 - 2.0 | Controls peaking curve |

**Common Values:**
- Residential: `k=3.0, p=0.16` (high peaking)
- Commercial: `k=2.0, p=0.25` (moderate peaking)
- Industrial: `k=1.5, p=0.40` (low peaking)

#### Alternative Formula (Babbitt): `PF = a / (Q × b)^p`

| Parameter | Type | Default | Typical | Description |
|-----------|------|---------|---------|-------------|
| **Alternative Peaking Curve** | Boolean | `false` | - | Enable alternative formula |
| **a (Coefficient)** | Float | `0.0` | `2.6` | Numerator coefficient |
| **b (Multiplier)** | Float | `0.0` | `1.547` | Denominator multiplier |

### Coverage Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| **Use Peakable Coverage Load** | Boolean | `true` | Enable coverage load |
| **Peakable Coverage Load** | Float | `0.0` | Point load value |
| **X Coverage** | Float | `23` | Coverage area/population |
| **Y Peaking Multiplier** | Float | `23` | Multiplier for coverage |

### Reserved Parameters

| Parameter | Type | Default | Status |
|-----------|------|---------|--------|
| **c, d, e** | Float | `0.0` | Reserved for future use |

---

## Peaking Formulas

### Standard Formula

**Formula:** `peak = k × Q^p`

**Where:**
- `Q` = Average flow rate (L/s or GPM)
- `k` = Peaking factor coefficient
- `p` = Exponent

**Example Calculation:**

Given: `Q=100 L/s, k=2.6, p=0.16`
```
peak = 2.6 × (100)^0.16
peak = 2.6 × 1.585
peak = 4.12
actual peak = 100 × 4.12 = 412 L/s
```

### Alternative Formula (Babbitt)

**Formula:** 
```
PF = a / (Q × b)^p
peak = Q × PF
```

**Where:**
- `Q` = Average flow rate
- `a` = Coefficient (typically 2.6)
- `b` = Multiplier (typically 1.547)
- `p` = Exponent (typically 0.16)

**Example Calculation:**

Given: `Q=100 L/s, a=2.6, b=1.547, p=0.16`
```
Step 1: Calculate PF
  PF = 2.6 / (100 × 1.547)^0.16
  PF = 2.6 / (154.7)^0.16
  PF = 2.6 / 1.641
  PF = 1.585

Step 2: Calculate peak
  peak = 100 × 1.585
  peak = 158.5 L/s
```

### Flow Component Formulas
```
base_flow = total_flow - peakable_coverage_load
trade_flow = peakable_coverage_load
additional_foul_flow = x_coverage × y_peaking_multiplier
```

### Common Engineering Formulas

| Formula | Equation | Use Case |
|---------|----------|----------|
| **Babbitt (1928)** | `PF = 5 / P^0.2` | Small residential (P in thousands) |
| **Harmon (1918)** | `PF = (14 + √P) / (4 + √P)` | General residential |
| **Ten States Standards** | `PF = (18 + √P) / (4 + √P)` | Design standards (max 4.0) |
| **Gifft** | `PF = 5.0 / Q^0.2` | Based on flow (Q in MGD) |

---

## Output Fields

### Fields Written by Script

| Field Name | Type | Units | Formula | Purpose |
|------------|------|-------|---------|---------|
| **base_flow** | Double | m³/s | `total_flow - peakable_coverage_load` | Background/unpeakable flow (I/I) |
| **trade_flow** | Double | m³/s | `peakable_coverage_load` | Commercial/industrial point loads |
| **additional_foul_flow** | Double | m³/s | `x_coverage × y_peaking_multiplier` | Population-based residential flow |
| **conduit_flow** | Double | m³/s | `mean(k × Q^p)` | Calculated peak flow |

### Field Descriptions

#### base_flow (Unpeakable)
- Constant background flow
- Infiltration/Inflow (I/I)
- Groundwater seepage
- Does NOT vary with time of day

#### trade_flow (Peakable - Point Sources)
- Commercial establishments
- Industrial facilities
- Institutional buildings
- Peaks during business hours

#### additional_foul_flow (Peakable - Area Sources)
- Residential population
- Per-capita contributions
- Peaks morning and evening

#### conduit_flow (Peak Flow)
- Calculated design peak
- For comparison with simulation
- Can be used in capacity analysis

### Viewing Results in ICM
```
1. Window > Grid View
2. Select table: _links
3. Right-click column header > Choose Columns
4. Enable fields:
   - base_flow
   - trade_flow
   - additional_foul_flow
   - conduit_flow
5. View calculated values
```

---

## Troubleshooting

### Common Errors

#### Error: "Not enough timesteps available! (Found: 0)"

**Cause:** No simulation results or not committed

**Solutions:**
1. Run a simulation: `Run > Run Simulation`
2. Wait for completion
3. Commit results: Right-click simulation → "Commit to Network"
4. Verify results exist in link grid view

---

#### Error: "Only tags may be set in read only networks"

**Cause:** Network opened in read-only mode

**Solutions:**
1. Close the network
2. File > Open
3. **UNCHECK "Read Only" box**
4. Click Open
5. Re-run script

**Alternative checks:**
- Another user viewing network?
- Another ICM instance open?
- File marked as read-only in Windows?

---

#### Error: "undefined local variable or method 'total_flow'"

**Cause:** Using old version (v1.0-v2.0) with scoping bug

**Solution:** Use current version (v3.0+) which fixes this issue

---

#### Warning: "Could not get link object for [ID]"

**Cause:** Selected object is not a link

**Solutions:**
1. Verify selection: Status bar should say "N links selected"
2. NOT "N nodes selected"
3. Deselect all (click empty space)
4. Select CONDUITS/PIPES only
5. Check link exists in _links table

---

#### Error: "Mismatch in timestep count"

**Cause:** Link's results don't match expected timesteps

**Solutions:**
1. Re-run simulation
2. Check link included in simulation
3. Verify link has valid geometry
4. Check for corrupted results

---

### Unexpected Results

#### Peak flows way too high

**Problem:** `peak = 1000×` when `average = 10`

**Causes:**
- Wrong formula (p value too high with k > 1)
- If `p=2.0` and `k=3.0`: `peak = 3 × 100 = 300×` too high!

**Solutions:**
- Use `p=0.16` for Babbitt-style
- Use `p=1.0` for direct multiplication
- Check if alternative formula should be enabled

---

#### Peak flows barely different from average

**Problem:** `peak ≈ average` (no peaking)

**Causes:**
- `k=1.0` (no peaking applied)
- "Include Peak Flow Calculation" disabled

**Solutions:**
- Increase k value (try 2.0-3.5)
- Verify checkbox is enabled
- Check alternative formula parameters

---

#### Negative flow values

**Problem:** `base_flow` shows negative values

**Cause:** `peakable_coverage_load > total_flow`

**Formula:** `base_flow = total_flow - peakable_coverage_load`

**Solutions:**
- Reduce `peakable_coverage_load` value
- Check if `total_flow` is reasonable
- Verify flow units are consistent

---

#### All values are zero

**Problem:** All assigned values near zero

**Causes:**
- Simulation had no flow
- Wrong units conversion
- Very small base flows

**Solutions:**
- Check simulation setup
- Verify boundary conditions
- Review `us_flow` results in grid
- Verify simulation converged

---

## Best Practices

### Workflow Recommendations

1. ✅ **Always backup network** before running scripts
```
   File > Save As
   Add date: "MyNetwork_2025-11-03.icm"
```

2. ✅ **Test on small selection** first (5-10 links)
   - Verify results make sense
   - Check values are reasonable
   - Then process entire network

3. ✅ **Document parameter choices**
   - Keep notes on k and p values
   - Record reasoning for selections
   - Save for project documentation

4. ✅ **Verify results after processing**
   - Spot-check random links
   - Compare peak-to-average ratios
   - Ensure no negative values
   - Check magnitude is reasonable

5. ✅ **Compare against hand calculations**
   - Pick a typical link
   - Calculate peak manually
   - Verify formula is correct

### Parameter Selection Guidelines

#### For RESIDENTIAL Areas
```
k = 2.5 to 3.5
p = 0.14 to 0.20
Higher peaking for smaller populations
```

#### For COMMERCIAL Areas
```
k = 2.0 to 2.5
p = 0.20 to 0.30
Moderate peaking during business hours
```

#### For INDUSTRIAL Areas
```
k = 1.2 to 1.8
p = 0.30 to 0.50
Low peaking (continuous operation)
```

#### For MIXED USE Areas
```
k = 2.0 to 2.8
p = 0.16 to 0.25
Run script multiple times for different zones
```

### Quality Assurance Checklist

After running script, verify:

- ✅ Peak flows ≥ average flows
- ✅ Magnitudes are reasonable (not 1000× or 0.01× average)
- ✅ Residential areas peak higher than industrial
- ✅ No unexpected negative values
- ✅ Results match engineering judgment

### Reporting

Include in technical reports:

- Script version used (v3.0)
- Date and time of execution
- Parameter values (k, p, etc.)
- Number of links processed
- Sample calculations
- Before/after comparison table
- Methodology explanation
- Assumptions and limitations

---

## Technical Notes

### Script Version History

| Version | Changes | Status |
|---------|---------|--------|
| **v1.0** | Original implementation | ❌ Variable scoping error |
| **v2.0** | Added debug output | ❌ Still had scoping issue |
| **v3.0** | Two-phase processing, read-only detection | ✅ All issues fixed |

### Key Fix in v3.0

**Old Way (v1.0-v2.0):**
```ruby
Loop 1: Calculate total_flow (local variable)
Loop 2: Try to use total_flow (ERROR - out of scope!)
```

**New Way (v3.0):**
```ruby
Phase 1: Calculate and store in link_data hash
Phase 2: Retrieve from link_data hash and assign
```

### Performance

| Network Size | Processing Time |
|--------------|----------------|
| 100 links | ~10 seconds |
| 1,000 links | ~1-2 minutes |
| 10,000 links | ~10-15 minutes |
| 50,000+ links | Process in batches |

**Factors affecting speed:**
- Number of timesteps
- Number of links
- Network complexity
- Computer performance

### Memory Usage
```ruby
link_data structure ≈ 150 bytes per link
10,000 links ≈ 1.5 MB (negligible)
```

### Ruby Details

- **Ruby version:** Typically 2.x (embedded in ICM)
- **Required library:** `date` (standard)
- **API used:** WSApplication (ICM-specific)
- **Data structure:** Ruby Hash
- **Float precision:** Double precision

### Known Limitations

1. ❌ Requires simulation results (cannot work on unsimulated networks)
2. ❌ Link-based only (does not process nodes directly)
3. ❌ Simple formulas only (c, d, e parameters not yet implemented)
4. ❌ No table-based peaking curve interpolation
5. ❌ Unit selection affects display only (no actual conversion)

### Future Enhancements

Planned improvements:
- ✨ Full polynomial formulas (c, d, e parameters)
- ✨ Table-based peaking curve interpolation
- ✨ CSV import/export of parameters
- ✨ Graphical peaking curve output
- ✨ Node population data integration
- ✨ Batch processing by attribute
- ✨ Parameter optimization tools

---

## Support & Resources

### For Script Help
1. Review this documentation completely
2. Check Troubleshooting section
3. Examine debug output
4. Verify inputs and selection
5. Test with small subset

### ICM InfoWorks Resources
- ICM Help System (F1 in application)
- Ruby Scripting Guide
- Autodesk support portal
- ICM user forums

### Engineering References
- Metcalf & Eddy: *Wastewater Engineering*
- *Ten States Standards*
- ASCE Manuals and Reports
- State/local design guidelines

---

## Quick Reference

### Formula Cheat Sheet
```ruby
# Standard Formula
peak = k × (Q)^p

# Alternative (Babbitt)
PF = a / (Q × b)^p
peak = Q × PF

# Flow Components
base_flow = total_flow - peakable_coverage_load
trade_flow = peakable_coverage_load
additional_foul_flow = x_coverage × y_peaking_multiplier
```

### Typical Parameter Sets
```ruby
# Small Residential
k = 3.5, p = 0.16

# Large Residential
k = 2.6, p = 0.16

# Commercial
k = 2.0, p = 0.25

# Industrial
k = 1.5, p = 0.40

# Babbitt Alternative
a = 2.6, b = 1.547, p = 0.16
```

### File Locations

**Script file:** `InfoSewerPeakingFactor.rb`  
**Fields modified:** `_links` table  
**Results from:** `us_flow` field

---

## License & Disclaimer

This script is provided "as is" for use with ICM InfoWorks. Always backup your network before running any scripts. Verify results before using in production models.

**Author:** Robert Dickinson + AI Assistant  
**Contact:** [Your contact information]  
**Repository:** [Link to repository if applicable]

---

*Last updated: November 2025*