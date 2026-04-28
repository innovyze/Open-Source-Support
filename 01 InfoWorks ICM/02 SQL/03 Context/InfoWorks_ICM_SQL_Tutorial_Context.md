# InfoWorks ICM SQL Tutorial Context for AI/LLM Code Generation

**Last Updated:** March 17, 2026

**Load Priority:** LEARNING - Load for complete examples and workflows
**Load Condition:** CONDITIONAL - When user asks "how to" or requests a complete script

## About This Document

This is a **tutorial-style context guide** for InfoWorks ICM SQL scripting.

**For LLMs:** Use this file to:
- Understand complete workflows from start to finish
- See how multiple patterns combine to solve real problems
- Learn InfoWorks SQL concepts (variables, navigation, results, blobs, spatial)

**Prerequisite:** Read `Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_SQL_Lessons_Learned.md` - **CRITICAL** Read FIRST
- `InfoWorks_ICM_SQL_Function_Reference.md` - Function signatures
- `InfoWorks_ICM_SQL_Pattern_Reference.md` - Code templates used in these examples
- `InfoWorks_ICM_SQL_Syntax_Reference.md` - Complete syntax rules
- `InfoWorks_ICM_SQL_Schema_Common.md` - Field name lookups, IW vs SWMM differences

---

## Tutorial 1: Basic Selection and Reporting

**Goal:** Select conduits by width and produce a sorted report.

**Patterns Used:** PAT_SQL_INIT_001, PAT_SQL_SEL_004, PAT_SQL_REPORT_049

```sql
//Object: Conduit
//Spatial Search: blank

// Select large conduits
SELECT us_node_id, ds_node_id, conduit_width, conduit_height, system_type
WHERE conduit_width >= 300
ORDER BY conduit_width DESC;
```

**What This Shows:**
- Header comments declare object type and spatial context
- WHERE filters objects
- ORDER BY sorts the result grid
- Multiple fields separated by commas in SELECT

**Variation — Export to CSV:**
```sql
//Object: Conduit
//Spatial Search: blank

SELECT us_node_id, ds_node_id, conduit_width, conduit_height
INTO FILE 'C:\Temp\large_conduits.csv'
WHERE conduit_width >= 300
ORDER BY conduit_width DESC;
```

---

## Tutorial 2: Data Modification with User Prompts

**Goal:** Let the user select a diameter threshold and mark matching conduits.

**Patterns Used:** PAT_SQL_INIT_002, PAT_SQL_PROMPT_037, PAT_SQL_MOD_009, PAT_SQL_MOD_010

```sql
//Object: Conduit
//Spatial Search: blank

// Define diameter options
LIST $dia_options = 150, 225, 300, 450, 600, 900;

// Prompt user for selection
PROMPT TITLE 'Conduit Classification';
PROMPT LINE $min_dia 'Minimum Diameter (mm)' DP 0 LIST $dia_options;
PROMPT DISPLAY;

// Classify conduits using IIF
SET user_text_1 = IIF(conduit_width >= $min_dia, 'Above Threshold', 'Below Threshold');

// Select the ones above threshold
SELECT WHERE user_text_1 = 'Above Threshold';
```

**What This Shows:**
- LIST creates a dropdown of predefined values
- PROMPT TITLE/LINE/DISPLAY creates a user dialog
- Variable `$min_dia` receives the user's choice
- IIF provides inline conditional logic
- SET applies to all objects (no WHERE = all objects updated)

---

## Tutorial 3: Network Tracing (Upstream)

**Goal:** From a selected node, trace 5 links upstream and select them.

**Patterns Used:** PAT_SQL_INIT_003, PAT_SQL_TRACE_020

```sql
//Object: All Nodes
//Spatial Search: blank

// Step 1: Initialize flags
UPDATE [All Links] SET $link_sel = 0;
UPDATE [All Nodes] SET $node_sel = 0;

// Step 2: Mark currently selected node(s) as starting points
UPDATE SELECTED SET $node_sel = 1;

// Step 3: Iteratively trace upstream
LET $count = 0;
LET $depth = 5;
WHILE $count < $depth;
    // Flag upstream links of flagged nodes
    SET us_links.$link_sel = 1 WHERE $node_sel = 1;
    // Flag upstream nodes of newly flagged links
    UPDATE [All Links] SET us_node.$node_sel = 1 WHERE $link_sel = 1;
    LET $count = $count + 1;
WEND;

// Step 4: Select the traced links
SELECT FROM [All Links] WHERE $link_sel = 1;
```

**What This Shows:**
- Object variables (`$link_sel`, `$node_sel`) are per-object flags, initialized to 0
- `UPDATE SELECTED` marks only currently-selected objects
- `us_links.$link_sel = 1` navigates from nodes to their upstream links
- `us_node.$node_sel = 1` navigates from links to their upstream nodes
- Each WHILE iteration extends the trace by one link
- Final SELECT shows all traced links in the result

---

## Tutorial 4: Working with Simulation Results

**Goal:** Analyze time-series results to find peak depths, their timing, and flooding duration.

**Patterns Used:** PAT_SQL_RES_029, PAT_SQL_RES_030, PAT_SQL_RES_032

```sql
//Object: All Nodes
//Spatial Search: blank

// Peak depth and when it occurred
SELECT node_id,
    MAX(tsr.flooddepth) DP 3 AS [Max Flood Depth],
    WHENMAX(tsr.flooddepth) AS [Time of Max],
    DURATION(tsr.flooddepth > 0) DP 1 AS [Flood Duration (min)]
ORDER BY MAX(tsr.flooddepth) DESC;
```

**What This Shows:**
- `tsr.*` fields require aggregate functions (MAX, WHENMAX, DURATION)
- `DP n` controls decimal places in output
- `AS [alias]` provides column headers (square brackets allow special characters)
- Multiple tsr aggregates can appear in one SELECT

**Variation — Filter to specific timestep range:**
```sql
//Object: Conduit
//Spatial Search: blank

LET $start_step = 10;
LET $end_step = 50;

SELECT us_node_id, ds_node_id,
    MAX(tsr.ds_depth) DP 3 AS [Max Depth],
    AVG(tsr.ds_flow) DP 2 AS [Time-Weighted Avg Flow]
WHEN tsr.timestep_no >= $start_step AND tsr.timestep_no <= $end_step
ORDER BY MAX(tsr.ds_depth) DESC;
```

**Important:** AVG on tsr.* is time-weighted, not a simple arithmetic mean. It accounts for varying timestep lengths.

---

## Tutorial 5: Blob Table Operations

**Goal:** Populate pump head-discharge curves from pump attributes, then query the curves.

**Patterns Used:** PAT_SQL_BLOB_026, PAT_SQL_BLOB_027, PAT_SQL_BLOB_025

```sql
//Object: Pump
//Spatial Search: blank

// Step 1: Create Head Discharge records for pumps that need them
INSERT INTO [Head Discharge] (head_discharge_id)
SELECT SELECTED asset_id FROM Pump;

// Step 2: Clear any existing curve data
DELETE ALL FROM [Head Discharge].HDP_table;

// Step 3: Populate curve points from pump attributes
// (user_number_3 = head, user_number_4 = discharge, user_text_1 = point flag)
INSERT INTO [Head Discharge].HDP_table
    (head_discharge_id, HDP_table.head, HDP_table.discharge)
SELECT asset_id, user_number_3, user_number_4
FROM Pump WHERE user_text_1 = '1';

// Step 4: Find maximum discharge from all curves
SELECT oid, MAX(HDP_table.discharge) DP 2 AS [Max Q]
FROM [Head Discharge];
```

**What This Shows:**
- INSERT INTO creates parent objects, INSERT INTO table.blob creates blob rows
- DELETE ALL FROM table.blob clears blob contents without deleting the parent
- Blob fields are accessed via `parent.blob_field` dot notation
- Aggregate functions (MAX) work on blob fields

---

## Tutorial 6: Spatial Query Workflow

**Goal:** Find all nodes within 100m of selected river reaches.

**Patterns Used:** PAT_SQL_SPATIAL_034

```sql
//Object: All Nodes
//Spatial Search: blank

// Step 1: Clear any previous spatial search
SPATIAL NONE;

// Step 2: Mark river reaches for the spatial search
UPDATE [River Reach] SET user_number_1 = 1;

// Step 3: Perform distance-based spatial search
SPATIAL Distance Network [River Reach] 100;

// Step 4: Select nodes near river reaches
SELECT FROM [All Nodes] WHERE spatial.user_number_1 = 1;

// Step 5: Clean up
SPATIAL NONE;
UPDATE [River Reach] SET user_number_1 = '';
```

**What This Shows:**
- SPATIAL sets up a spatial search context (distance-based in this case)
- `spatial.field` accesses values from the spatially matched objects
- **Always clean up** after spatial queries: `SPATIAL NONE;` and reset markers
- The spatial search remains active between clauses until explicitly cleared

---

## Tutorial 7: Loop-Based Batch Processing

**Goal:** For each selected conduit, calculate and store a derived value requiring per-object processing.

**Patterns Used:** PAT_SQL_LOOP_040, PAT_SQL_MOD_013

```sql
//Object: Conduit
//Spatial Search: blank

// Step 1: Collect selected object IDs
LIST $oids STRING;
SELECT DISTINCT oid INTO $oids;

// Step 2: Process each object
LET $i = 1;
WHILE $i <= LEN($oids);
    LET $current = AREF($i, $oids);

    // Read current object's values
    SELECT conduit_width INTO $w WHERE oid = $current;
    SELECT conduit_height INTO $h WHERE oid = $current;

    // Calculate derived value
    LET $ratio = $w / $h;

    // Classify and store
    IF $ratio >= 2.0;
        SET user_text_1 = 'Wide' WHERE oid = $current;
    ELSEIF $ratio >= 1.0;
        SET user_text_1 = 'Square' WHERE oid = $current;
    ELSE;
        SET user_text_1 = 'Tall' WHERE oid = $current;
    ENDIF;

    SET user_number_1 = $ratio WHERE oid = $current;

    LET $i = $i + 1;
WEND;
```

**What This Shows:**
- `SELECT DISTINCT oid INTO $list` populates a list with object IDs
- WHILE + AREF iterates through objects (1-indexed!)
- `SELECT field INTO $var WHERE oid = $current` reads a specific object's value
- IF/ELSEIF/ELSE provides conditional logic within the loop
- SET with `WHERE oid = $current` targets specific objects

**Note:** For simple classifications, IIF is often more efficient than a loop:
```sql
SET user_text_1 = IIF(conduit_width / conduit_height >= 2.0, 'Wide',
                  IIF(conduit_width / conduit_height >= 1.0, 'Square', 'Tall'));
```

---

## Tutorial 8: Scenario Comparison

**Goal:** Compare field values between two scenarios and flag differences.

**Patterns Used:** PAT_SQL_SCENARIO_045, PAT_SQL_SCENARIO_046

```sql
//Object: All Links
//Spatial Search: blank

// Step 1: Store base scenario values in object variable
UPDATE [All Links] IN BASE SCENARIO SET $base_width = conduit_width;

// Step 2: Compare with current scenario
// (Assumes the current scenario is the design scenario)
SET user_text_1 = IIF($base_width <> conduit_width, 'Changed', '');

// Step 3: Show only changed objects
SELECT us_node_id, ds_node_id, $base_width AS [Base Width], conduit_width AS [Design Width]
WHERE user_text_1 = 'Changed';
```

**What This Shows:**
- `IN BASE SCENARIO` accesses the base scenario data
- Object variable `$base_width` stores per-object base scenario values
- Comparison in current scenario detects changes
- There is only one copy of each variable (not scenario-dependent)

---

## Tutorial 9: GROUP BY Reporting

**Goal:** Produce a summary report of conduit statistics grouped by material.

**Patterns Used:** PAT_SQL_REPORT_048, PAT_SQL_REPORT_051, PAT_SQL_REPORT_050

```sql
//Object: Conduit
//Spatial Search: blank

// Summary report
SELECT material AS [Material],
    COUNT(*) AS [Count],
    SUM(conduit_length) DP 1 AS [Total Length (m)],
    AVG(conduit_width) DP 0 AS [Avg Width (mm)],
    MIN(conduit_width) DP 0 AS [Min Width],
    MAX(conduit_width) DP 0 AS [Max Width]
GROUP BY material
HAVING COUNT(*) > 5
ORDER BY COUNT(*) DESC;
```

**What This Shows:**
- GROUP BY aggregates objects by field value
- Multiple aggregate functions in one SELECT
- AS with square brackets provides column headers
- DP controls decimal places
- HAVING filters groups after aggregation (like WHERE but for groups)
- ORDER BY sorts the group summary

**Variation — Conditional aggregation with IIF:**
```sql
//Object: Subcatchment
//Spatial Search: blank

SELECT system_type AS [System],
    COUNT(*) AS [Count],
    SUM(IIF(area_measurement_type = 'Percent',
        (area_percent_1 / 100.0) * contributing_area,
        area_absolute_1)) DP 2 AS [Runoff Area 1]
GROUP BY system_type;
```

---

## Tutorial 10: InfoAsset Manager Survey Selection

**Goal:** Select the most recent CCTV survey for each selected pipe, then filter by structural grade.

**Patterns Used:** PAT_SQL_NAV_019, PAT_SQL_BLOB_024

```sql
//Object: CCTV Survey
//Spatial Search: blank

// Step 1: For each selected pipe, flag its most recent CCTV survey
UPDATE SELECTED Pipe SET cctv_surveys.$survey_sel = 1
    WHERE cctv_surveys.when_surveyed = MAX(cctv_surveys.when_surveyed);

// Step 2: Select the flagged surveys
SELECT FROM [CCTV Survey] WHERE $survey_sel = 1;

// Step 3: Further filter by structural grade
DESELECT FROM [CCTV Survey] WHERE structural_grade < 4;
```

**What This Shows:**
- `cctv_surveys` is a one-to-many link from Pipe to CCTV Survey
- `MAX(cctv_surveys.when_surveyed)` finds the most recent survey per pipe
- Setting `$survey_sel = 1` via the one-to-many link flags objects on the survey side
- `DESELECT` removes objects from the selection (reverse of SELECT)

**Variation — Count defects by code:**
```sql
//Object: CCTV Survey
//Spatial Search: blank

SELECT id,
    COUNT(details.code = 'CC') AS [CC Count],
    COUNT(details.code = 'CL') AS [CL Count],
    COUNT(details.*) AS [Total Details]
WHERE $survey_sel = 1
ORDER BY COUNT(details.*) DESC;
```

---

## Complete Real-World Example: Travel Time Estimation

**Goal:** Estimate upstream travel time using simulation velocity results.

This example combines: prompts, variable declaration, network tracing, time-series results with IIF inside AVG, and loop-based iterative processing.

**Patterns Used:** PAT_SQL_PROMPT_036, PAT_SQL_INIT_003, PAT_SQL_TRACE_020, PAT_SQL_RES_032, PAT_SQL_LOOP_040

```sql
//Object: All Nodes
//Spatial Search: blank

// Step 1: Get parameters from user
LET $iterations = 3;
LET $min_speed = 0.5;
LET $n_hours = 24;
LET $start = 18;
LET $end = 22;

PROMPT TITLE 'Travel Time Parameters';
PROMPT LINE $iterations 'Number of upstream iterations' DP 0;
PROMPT LINE $min_speed 'Minimum velocity (m/s)' DP 3;
PROMPT LINE $n_hours 'Simulation duration (hours)' DP 0;
PROMPT LINE $start 'Analysis start hour' DP 0;
PROMPT LINE $end 'Analysis end hour' DP 0;
PROMPT DISPLAY;

// Step 2: Initialize
UPDATE [All Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

// Step 3: Calculate timestep bounds for the analysis window
LET $left = $start * MAX(tsr.timesteps) / $n_hours;
LET $right = $end * MAX(tsr.timesteps) / $n_hours;

// Step 4: Calculate average velocity in analysis window for all links
UPDATE [All Links] SET $speed = AVG(IIF(
    (tsr.timestep_no > $left) AND (tsr.timestep_no < $right),
    tsr.us_vel, NULL));

// Step 5: Iteratively trace upstream, accumulating travel time
LET $count = 0;
WHILE $count < $iterations;
    SET us_links.$link_selected = 1 WHERE $node_selected = 1;
    UPDATE [All Links] SET us_node.$node_selected = 1 WHERE $link_selected = 1;

    // Calculate travel time for each link:
    // time = length / velocity (use minimum speed if velocity too low)
    UPDATE [All Links] SET user_number_5 =
        ds_node.user_number_5 +
        IIF($speed > $min_speed,
            conduit_length / $speed / 60,
            conduit_length / $min_speed / 60)
        WHERE $link_selected = 1;

    LET $count = $count + 1;
WEND;

// Step 6: Select traced links
SELECT FROM [All Links] WHERE $link_selected = 1;
```

**What This Shows:**
- Complex real-world workflow combining 6+ patterns
- IIF inside AVG for conditional time-series analysis
- Travel time accumulation via `ds_node.user_number_5` navigation
- Division by 60 converts seconds to minutes
- `$min_speed` prevents division by zero or unrealistic velocities

**See:** `../01 InfoWorks/0027` for the original script this is based on
