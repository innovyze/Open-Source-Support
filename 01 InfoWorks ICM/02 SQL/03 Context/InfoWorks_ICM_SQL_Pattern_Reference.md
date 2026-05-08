# InfoWorks ICM SQL Pattern Reference for LLM Code Generation

**Last Updated:** March 17, 2026

**Load Priority:** CORE - Load for code template lookup
**Load Condition:** ALWAYS when implementing specific functionality

## Document Purpose
This is a **pattern reference guide** for LLM-assisted SQL scripting in InfoWorks ICM.

**For LLMs:** Use this file to:
- Find working code templates organized by task
- Look up pattern IDs (PAT_SQL_XXX_NNN) referenced in other files
- Get intent, context, and related patterns for each code template

**Prerequisite:** Read `Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_SQL_Lessons_Learned.md` - **CRITICAL** Read FIRST
- `InfoWorks_ICM_SQL_Function_Reference.md` - Function signatures for functions used here
- `InfoWorks_ICM_SQL_Syntax_Reference.md` - Complete syntax rules
- `InfoWorks_ICM_SQL_Schema_Common.md` - Field names used in patterns, IW vs SWMM differences
- `InfoWorks_ICM_SQL_Tutorial_Context.md` - Complete workflow examples using these patterns
- `InfoWorks_ICM_SQL_Error_Reference.md` - References patterns for error solutions

## Pattern Index

| Pattern ID | Category | Use When | Tags |
|------------|----------|----------|------|
| **Initialization** |
| PAT_SQL_INIT_001 | Init | First lines of any query | header, setup |
| PAT_SQL_INIT_002 | Init | Declare variables | variables, scalar, list |
| PAT_SQL_INIT_003 | Init | Initialize flag variables | flags, cleanup |
| **Selection & Filtering** |
| PAT_SQL_SEL_004 | Selection | Select objects by condition | select, filter |
| PAT_SQL_SEL_005 | Selection | Select from multiple tables | multi-table |
| PAT_SQL_SEL_006 | Selection | Deselect and clear selection | deselect, clear |
| PAT_SQL_SEL_007 | Selection | Filter by list membership | member, list |
| PAT_SQL_SEL_008 | Selection | Select with string patterns | like, matches |
| **Data Modification** |
| PAT_SQL_MOD_009 | Modification | Update field values | set, update |
| PAT_SQL_MOD_010 | Modification | Conditional updates with IIF | iif, conditional |
| PAT_SQL_MOD_011 | Modification | Insert new objects | insert, create |
| PAT_SQL_MOD_012 | Modification | Delete objects or blob rows | delete |
| PAT_SQL_MOD_013 | Modification | Bulk update with IF/ELSEIF | if, procedural |
| PAT_SQL_MOD_014 | Modification | Set fields to NULL or empty | null, reset |
| **Navigation** |
| PAT_SQL_NAV_015 | Navigation | Access upstream/downstream node | one-to-one, link |
| PAT_SQL_NAV_016 | Navigation | Navigate to connected links | one-to-many, node |
| PAT_SQL_NAV_017 | Navigation | Subcatchment to node navigation | subcatchment |
| PAT_SQL_NAV_018 | Navigation | Cross-type field population | populate, concatenate |
| PAT_SQL_NAV_019 | Navigation | Survey to parent object (InfoAsset) | joined, asset |
| **Network Tracing** |
| PAT_SQL_TRACE_020 | Tracing | Trace N links upstream | upstream, iterative |
| PAT_SQL_TRACE_021 | Tracing | Trace N links downstream | downstream, iterative |
| PAT_SQL_TRACE_022 | Tracing | Trace all downstream to outfall | all_ds_links |
| PAT_SQL_TRACE_023 | Tracing | Bidirectional trace with prompt | prompt, direction |
| **Blob/Array Operations** |
| PAT_SQL_BLOB_024 | Blob | Count/filter blob table rows | count, details |
| PAT_SQL_BLOB_025 | Blob | Aggregate blob field values | min, max, sum |
| PAT_SQL_BLOB_026 | Blob | Insert into blob table | insert, blob |
| PAT_SQL_BLOB_027 | Blob | Delete from blob table | delete, blob |
| **Results Access** |
| PAT_SQL_RES_028 | Results | Summary results (sim.*) | sim, max |
| PAT_SQL_RES_029 | Results | Time series max/whenmax | tsr, whenmax |
| PAT_SQL_RES_030 | Results | Duration and count queries | duration, count |
| PAT_SQL_RES_031 | Results | Earliest/latest occurrence | earliest, iif |
| PAT_SQL_RES_032 | Results | WHEN clause to limit timesteps | when, filter |
| **Spatial** |
| PAT_SQL_SPATIAL_033 | Spatial | Distance-based spatial search | distance |
| PAT_SQL_SPATIAL_034 | Spatial | Spatial with cleanup | cleanup |
| PAT_SQL_SPATIAL_035 | Spatial | Crossing/intersecting objects | cross, intersect |
| **User Interaction** |
| PAT_SQL_PROMPT_036 | Prompt | Basic numeric/string prompt | input |
| PAT_SQL_PROMPT_037 | Prompt | Dropdown list selection | list, dropdown |
| PAT_SQL_PROMPT_038 | Prompt | Dynamic list from data | distinct, dynamic |
| PAT_SQL_PROMPT_039 | Prompt | Read-only confirmation dialog | readonly, confirm |
| **Looping** |
| PAT_SQL_LOOP_040 | Loop | Iterate through list | while, aref |
| PAT_SQL_LOOP_041 | Loop | Loop with condition | while, condition |
| PAT_SQL_LOOP_042 | Loop | Loop with BREAK | break, early-exit |
| **File I/O** |
| PAT_SQL_FILE_043 | File | Save variables to file | save |
| PAT_SQL_FILE_044 | File | Load variables from file | load |
| **Scenario Operations** |
| PAT_SQL_SCENARIO_045 | Scenario | Copy data between scenarios | copy, scenario |
| PAT_SQL_SCENARIO_046 | Scenario | Compare scenarios | compare, diff |
| PAT_SQL_SCENARIO_047 | Scenario | Add/drop scenarios | create, delete |
| **Reporting** |
| PAT_SQL_REPORT_048 | Report | GROUP BY with aggregation | group, count |
| PAT_SQL_REPORT_049 | Report | Export to CSV file | into, file |
| PAT_SQL_REPORT_050 | Report | TOP/BOTTOM with ORDER BY | top, ranking |
| PAT_SQL_REPORT_051 | Report | HAVING filter on groups | having, filter |
| PAT_SQL_REPORT_052 | Report | RANK assignment | rank, order |

---

## Initialization Patterns

### PAT_SQL_INIT_001 - Query Header
**Intent:** Every query must declare object type and spatial context.

```sql
//Object: Node
//Spatial Search: blank
```

Common object types: `Node`, `Conduit`, `Subcatchment`, `Pump`, `Weir`, `Orifice`, `[River Reach]`, `[All Nodes]`, `[All Links]`, `Polygon`

For InfoAsset Manager: `Pipe`, `Manhole`, `[CCTV Survey]`, `[Manhole Survey]`

---

### PAT_SQL_INIT_002 - Variable Declaration
**Intent:** Declare scalar and list variables before use.

```sql
// Scalar variables
LET $distance = 50;
LET $threshold = 0.0;
LET $label = 'default';

// List variables with values
LIST $widths = 100, 300, 500, 700, 900;
LIST $codes = 'AB', 'CD', 'EF';
LIST $dates = #01/01/2024#, #01/06/2024#, #01/01/2025#;

// Empty list variables (populated later via SELECT INTO or LOAD)
LIST $oids STRING;
LIST $values = 0.0;
```

---

### PAT_SQL_INIT_003 - Initialize Flag Variables
**Intent:** Clear per-object flag variables before use to avoid stale state.

```sql
UPDATE [All Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
```

---

## Selection & Filtering Patterns

### PAT_SQL_SEL_004 - Basic Selection
**Intent:** Select objects matching a condition.

```sql
//Object: Conduit
//Spatial Search: blank

// Select by field value
SELECT FROM [Conduit] WHERE conduit_width >= 300 AND system_type = 'Foul';

// Select all objects in a table
SELECT ALL FROM [All Nodes];

// Select from currently selected objects only
SELECT SELECTED WHERE ground_level > 100;
```

---

### PAT_SQL_SEL_005 - Multi-Table Selection
**Intent:** Select objects across different tables in one query.

```sql
//Object: All Nodes
//Spatial Search: blank

// Select nodes
SELECT FROM Node WHERE node_type = 'manhole';

// Also select connected conduits (second clause)
SELECT FROM Conduit WHERE conduit_width > 300;
```

---

### PAT_SQL_SEL_006 - Deselect and Clear
**Intent:** Remove objects from selection or clear entirely.

```sql
// Deselect specific objects
DESELECT WHERE ground_level < 50;

// Deselect from specific table
DESELECT FROM [All Links] WHERE conduit_width < 100;

// Clear entire selection (all object types)
CLEAR SELECTION;
```

---

### PAT_SQL_SEL_007 - Filter by List Membership
**Intent:** Select objects where a field value is in a predefined list.

```sql
LIST $defect_codes = 'CC', 'CCJ', 'CL', 'CLJ', 'CM', 'CMJ';
SELECT WHERE MEMBER(details.code, $defect_codes);

// With IF for conditional logic
IF MEMBER($current_value, $valid_values);
    // Value is in list
ENDIF;
```
**See:** `../01 InfoWorks/0049` for real-world MEMBER usage

---

### PAT_SQL_SEL_008 - String Pattern Matching
**Intent:** Select objects using wildcard or regex patterns.

```sql
// LIKE - simple wildcards (? = one char, * = rest of string)
SELECT WHERE node_id LIKE 'MH*';          // Starts with MH
SELECT WHERE node_id LIKE '????????';     // Exactly 8 characters
SELECT WHERE node_id LIKE 'MH??*';        // MH + at least 2 more chars

// MATCHES - full regex (case insensitive, must match whole string)
SELECT WHERE node_id MATCHES '[0-9]+';    // Only digits
SELECT WHERE node_id MATCHES '.*MH.*';    // Contains MH anywhere
```

---

## Data Modification Patterns

### PAT_SQL_MOD_009 - Basic Field Update
**Intent:** Set field values for objects.

```sql
// Set for all objects
SET user_number_1 = 0;

// Set with condition
SET user_text_1 = 'reviewed' WHERE ground_level > 100;

// Set multiple fields at once (left to right evaluation)
SET user_number_1 = x, user_number_2 = y;

// Override table
UPDATE [All Links] SET user_number_1 = conduit_width / conduit_height;

// Override selection behavior
UPDATE ALL Node SET user_text_1 = '';
UPDATE SELECTED Conduit SET user_number_1 = 1;
```

---

### PAT_SQL_MOD_010 - Conditional Update with IIF
**Intent:** Set values based on conditions inline.

```sql
// Simple conditional
SET user_text_1 = IIF(conduit_width >= 600, 'Large', 'Small');

// Nested conditional
SET user_number_1 = IIF(system_type = 'Foul', 1,
                    IIF(system_type = 'Storm', 2, 3));

// Conditional aggregation
SET user_number_1 = SUM(IIF(area_measurement_type = 'Percent',
    (area_percent_1 / 100.0) * contributing_area,
    area_absolute_1));
```
**See:** `../01 InfoWorks/0049` for IIF with GROUP BY aggregation

---

### PAT_SQL_MOD_011 - Insert New Objects
**Intent:** Create new network objects programmatically.

```sql
// Insert a single node
INSERT INTO Node (node_id, x, y, system_type, ground_level, flood_type)
VALUES ($new_id, $new_x, $new_y, $sys, $gl, 'sealed');

// Insert a conduit
INSERT INTO Conduit (us_node_id, ds_node_id, link_suffix, system_type)
VALUES ($us_id, $ds_id, 1, $sys);

// Insert from SELECT (copies matching data)
INSERT INTO [Head Discharge] (head_discharge_id)
SELECT SELECTED asset_id FROM Pump;

// Insert into a scenario
INSERT INTO Node (node_id, x, y) IN SCENARIO 'design' VALUES ('NEW01', 500, 600);
```
**See:** `../02 SWMM/0003` for INSERT within a loop to split links

---

### PAT_SQL_MOD_012 - Delete Objects or Blob Rows
**Intent:** Remove objects from the network or rows from blob tables.

```sql
// Delete matching objects
DELETE WHERE ground_level IS NULL;
DELETE FROM [All Links] WHERE conduit_width < 50;

// Delete ALL selected objects from a table
DELETE SELECTED FROM [Shape];

// Delete from blob table (removes blob rows, not the parent object)
DELETE FROM [CCTV Survey].details WHERE details.code <> 'ID' AND details.code <> 'IDJ';

// Delete ALL rows from a blob table
DELETE ALL FROM [Head Discharge].HDP_table;
```
**See:** `../01 InfoWorks/0034` for bulk cleanup with staged DELETE

---

### PAT_SQL_MOD_013 - Procedural Update with IF/ELSEIF
**Intent:** Complex conditional updates within a loop.

```sql
LIST $oids STRING;
SELECT DISTINCT oid INTO $oids;
LET $i = 1;
WHILE $i <= LEN($oids);
    LET $current_oid = AREF($i, $oids);
    SELECT conduit_width INTO $width WHERE oid = $current_oid;

    IF $width >= 600;
        SET user_text_1 = 'Large' WHERE oid = $current_oid;
    ELSEIF $width >= 300;
        SET user_text_1 = 'Medium' WHERE oid = $current_oid;
    ELSE;
        SET user_text_1 = 'Small' WHERE oid = $current_oid;
    ENDIF;

    LET $i = $i + 1;
WEND;
```
**See:** `../01 InfoWorks/0020` for CASE emulation using IF

---

### PAT_SQL_MOD_014 - Reset Fields to NULL or Empty
**Intent:** Clear field values.

```sql
// Set numeric field to NULL (blank)
SET ground_level = NULL;

// Set text field to empty string
SET user_text_1 = '';
UPDATE [All Nodes] SET user_text_1 = '';

// Set text field to NULL
SET user_text_1 = NULL;
```

---

## Navigation Patterns

### PAT_SQL_NAV_015 - Access Upstream/Downstream Node
**Intent:** Read properties of connected nodes from a link context.

```sql
//Object: Conduit
//Spatial Search: blank

// Read upstream node properties
SELECT us_node_id, ds_node_id, us_node.ground_level, ds_node.ground_level;

// Filter by connected node
SELECT WHERE us_node.ground_level > 100;

// Set node value from link context
SET us_node.user_text_1 = 'connected';
```

---

### PAT_SQL_NAV_016 - Navigate to Connected Links
**Intent:** Access or modify links connected to nodes.

```sql
//Object: Node
//Spatial Search: blank

// Flag upstream links of flagged nodes
SET us_links.$link_selected = 1 WHERE $node_selected = 1;

// Flag downstream links
SET ds_links.$link_selected = 1 WHERE $node_selected = 1;

// Count upstream links
SELECT node_id, COUNT(us_links.*), COUNT(ds_links.*);
```

---

### PAT_SQL_NAV_017 - Subcatchment to Node
**Intent:** Navigate between subcatchments and their discharge nodes.

```sql
//Object: Subcatchment
//Spatial Search: blank

// Access node properties from subcatchment
SELECT subcatchment_id, node.ground_level, node.node_id;

// Set node field from subcatchment context
SET node.user_number_1 = contributing_area;
```

---

### PAT_SQL_NAV_018 - Populate Node with Connected Link Info
**Intent:** Build a comma-separated list of connected link IDs in a node field.

```sql
//Object: All Links
//Spatial Search: blank

// Clear first
UPDATE Node SET user_text_1 = '';

// Append each link's OID to its downstream node's field
SET ds_node.user_text_1 = ds_node.user_text_1 +
    IIF(LEN(ds_node.user_text_1) = 0, '', ',') + oid;
```
**See:** `../01 InfoWorks/0017` for full implementation

---

### PAT_SQL_NAV_019 - Survey to Parent Object (InfoAsset Manager)
**Intent:** Navigate from survey objects to their parent pipes/manholes.

```sql
//Object: CCTV Survey
//Spatial Search: blank

// Select surveys via parent pipe properties
UPDATE SELECTED Pipe SET cctv_surveys.$survey_sel = 1;
SELECT FROM [CCTV Survey] WHERE $survey_sel = 1;

// Select most recent survey per pipe
UPDATE SELECTED Pipe SET cctv_surveys.$survey_sel = 1
    WHERE cctv_surveys.when_surveyed = MAX(cctv_surveys.when_surveyed);
```

---

## Network Tracing Patterns

### PAT_SQL_TRACE_020 - Trace N Links Upstream
**Intent:** Iteratively select links upstream of selected nodes.

```sql
//Object: All Nodes
//Spatial Search: blank

UPDATE [All Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

LET $count = 0;
LET $n = 3;  // Number of links to trace
WHILE $count < $n;
    SET us_links.$link_selected = 1 WHERE $node_selected = 1;
    UPDATE [All Links] SET us_node.$node_selected = 1 WHERE $link_selected = 1;
    LET $count = $count + 1;
WEND;

SELECT FROM [All Links] WHERE $link_selected = 1;
```
**See:** `../01 InfoWorks/0007`, `../01 InfoWorks/0045`

---

### PAT_SQL_TRACE_021 - Trace N Links Downstream
**Intent:** Same as upstream trace but in downstream direction.

```sql
UPDATE [All Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

LET $count = 0;
WHILE $count < $n;
    SET ds_links.$link_selected = 1 WHERE $node_selected = 1;
    UPDATE [All Links] SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
    LET $count = $count + 1;
WEND;

SELECT FROM [All Links] WHERE $link_selected = 1;
```

---

### PAT_SQL_TRACE_022 - Trace All Downstream to Outfall
**Intent:** Select all links downstream using full trace (no loop needed).

```sql
UPDATE [All Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

// all_ds_links traces the entire downstream path
SET all_ds_links.$link_selected = 1 WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;
```
**See:** `../01 InfoWorks/0028`, `../01 InfoWorks/0036`

---

### PAT_SQL_TRACE_023 - Bidirectional Trace with Prompt
**Intent:** Let user choose trace direction and number of links.

```sql
LIST $direction = 'Upstream', 'Downstream';
LET $n = 0;

PROMPT TITLE 'Network Trace';
PROMPT LINE $dir 'Direction' STRING LIST $direction;
PROMPT LINE $n 'Number of Links' DP 0;
PROMPT DISPLAY;

UPDATE [All Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

LET $count = 0;
IF $dir = 'Upstream';
    WHILE $count < $n;
        SET us_links.$link_selected = 1 WHERE $node_selected = 1;
        UPDATE [All Links] SET us_node.$node_selected = 1 WHERE $link_selected = 1;
        LET $count = $count + 1;
    WEND;
ELSEIF $dir = 'Downstream';
    WHILE $count < $n;
        SET ds_links.$link_selected = 1 WHERE $node_selected = 1;
        UPDATE [All Links] SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
        LET $count = $count + 1;
    WEND;
ENDIF;

SELECT FROM [All Links] WHERE $link_selected = 1;
```

---

## Blob/Array Operations

### PAT_SQL_BLOB_024 - Count and Filter Blob Rows
**Intent:** Query blob table contents (e.g., CCTV details, river sections).

```sql
// Count rows in blob table
SELECT oid, COUNT(details.*) FROM [CCTV Survey];

// Select objects with specific blob content
SELECT WHERE ANY(details.code = 'GP');

// Select where no details exist
SELECT WHERE COUNT(details.code) = 0;

// Count specific defect types
SET user_number_1 = COUNT(details.code = 'CC');
```

---

### PAT_SQL_BLOB_025 - Aggregate Blob Field Values
**Intent:** Calculate statistics on blob table data.

```sql
// Min river bed level across sections
SELECT MIN(sections.z) DP 3 FROM [River Reach];

// Max discharge from pump curve
SELECT MAX(HDP_table.discharge) INTO $maxQ FROM [Head Discharge];

// Group by with blob aggregation
SELECT SUM(COUNT(details.*)) GROUP BY direction;

// Min of min (nested aggregate in GROUP BY)
SELECT MIN(MIN(sections.z)) DP 3 GROUP BY oid, sections.key;
```

---

### PAT_SQL_BLOB_026 - Insert into Blob Table
**Intent:** Add rows to a blob/child table.

```sql
// Insert from field values
INSERT INTO [Head Discharge].HDP_table
    (head_discharge_id, HDP_table.head, HDP_table.discharge)
SELECT asset_id, user_number_3, user_number_4
FROM Pump WHERE user_text_1 = 1;

// Insert with constants
INSERT INTO [CCTV Survey].resource_details
    (id, resource_details.resource_id, resource_details.estimated_hours)
SELECT id, 'TBD', 5 FROM [CCTV Survey]
WHERE COUNT(resource_details.*) = 0;

// Insert SuDS controls
INSERT INTO Subcatchment.suds_controls
    (subcatchment_id, suds_controls.suds_structure, suds_controls.id)
SELECT oid, $structure_type, $structure_id FROM Subcatchment;
```
**See:** `../01 InfoWorks/0048` for full HD table INSERT workflow

---

### PAT_SQL_BLOB_027 - Delete from Blob Table
**Intent:** Remove rows from blob tables.

```sql
// Delete all blob rows
DELETE ALL FROM [Head Discharge].HDP_table;

// Delete with condition (keeps parent object)
DELETE FROM [CCTV Survey].details
WHERE details.code <> 'ID' AND details.code <> 'IDJ';
```

---

## Results Access Patterns

### PAT_SQL_RES_028 - Summary Results (sim.*)
**Intent:** Access simulation summary results (single values per object).

```sql
//Object: Conduit
//Spatial Search: blank

// Select by result threshold
SELECT us_node_id, ds_node_id, sim.max_Surcharge
WHERE sim.max_Surcharge >= 0.5;

// Surcharge/capacity ratios
SELECT sim.ds_depth / conduit_height AS [d/D],
       sim.ds_flow / capacity AS [q/Q];
```
**See:** `../01 InfoWorks/0037`, `../01 InfoWorks/0047`

---

### PAT_SQL_RES_029 - Time Series Max/WhenMax
**Intent:** Find peak values and their timing from time series results.

```sql
//Object: All Links
//Spatial Search: blank

// Max depth and when it occurred
SELECT oid, MAX(tsr.ds_depth), WHENMAX(tsr.ds_depth);

// Max flow and velocity
SELECT oid, MAX(tsr.ds_flow), MAX(tsr.us_vel);

// Min with timing
SELECT oid, MIN(tsr.us_froude), WHENMIN(tsr.us_froude);
```
**See:** `../02 SWMM/0001` for comprehensive result statistics

---

### PAT_SQL_RES_030 - Duration and Count Queries
**Intent:** Measure how long conditions persist in time series.

```sql
// Duration of flooding (minutes)
SELECT oid, DURATION(tsr.ds_depth > 1.0) AS [Flood Duration (min)];

// Select nodes flooded for more than 30 minutes
SELECT WHERE DURATION(tsr.flooddepth > 0) > 30;

// Count timesteps exceeding threshold
SELECT oid, COUNT(tsr.ds_depth > 1.0) AS [Timesteps > 1m];
```

---

### PAT_SQL_RES_031 - Earliest/Latest Occurrence
**Intent:** Find the first or last time a condition is met.

```sql
// First surcharge exceeding threshold
SELECT oid,
    EARLIEST(IIF(tsr.surcharge > 0.5, tsr.surcharge, NULL)) AS [First Surcharge],
    WHENEARLIEST(tsr.surcharge > 0.5) AS [When First];

// First time head drops below threshold
SELECT WHENEARLIEST(tsr.head < 150);
```

---

### PAT_SQL_RES_032 - WHEN Clause to Limit Timesteps
**Intent:** Restrict result analysis to specific timestep ranges.

```sql
// Specific timestep
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no = 20;

// Specific time
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_start = #01/01/2013 12:30#;

// Last timestep only
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no = tsr.timesteps;

// Range of timesteps
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no > 20;

// Using variables with WHEN
LET $start = 10;
LET $end = 50;
SELECT AVG(tsr.ds_depth) WHEN tsr.timestep_no >= $start AND tsr.timestep_no <= $end;

// Moving average with variable bounds
UPDATE [All Links] SET $speed = AVG(IIF(
    (tsr.timestep_no > $left) AND (tsr.timestep_no < $right),
    tsr.us_vel, NULL));
```
**See:** `../01 InfoWorks/0027` for results access within a tracing loop

---

## Spatial Patterns

### PAT_SQL_SPATIAL_033 - Distance-Based Spatial Search
**Intent:** Find objects within a distance of other objects.

```sql
// Set up spatial search
SPATIAL Distance Network [River Reach] 100;

// Select nodes near river reaches
SELECT FROM [All Nodes] WHERE spatial.user_number_1 = 1;

// Clear when done
SPATIAL NONE;
```

---

### PAT_SQL_SPATIAL_034 - Spatial Query with Cleanup
**Intent:** Complete spatial workflow with proper setup and teardown.

```sql
// Clear any previous spatial search
SPATIAL NONE;

// Select target objects and mark them
SELECT ALL FROM [All Nodes];
UPDATE [River Reach] SET user_number_1 = 1;

// Perform spatial search
SPATIAL Distance Network [River Reach] 100;
SELECT FROM [All Nodes] WHERE spatial.user_number_1 = 1;

// Clean up
SPATIAL NONE;
UPDATE [River Reach] SET user_number_1 = '';
```
**See:** `../01 InfoWorks/0009`, `../01 InfoWorks/0011`

---

### PAT_SQL_SPATIAL_035 - Crossing/Intersecting Objects
**Intent:** Find objects that cross or intersect target objects.

```sql
// Select conduits that cross other conduits (excluding connected ones)
//Spatial Search: Cross, Network layer, Conduit

SELECT WHERE (us_node_id <> spatial.ds_node_id)
    AND (ds_node_id <> spatial.us_node_id)
    AND (us_node_id <> spatial.us_node_id)
    AND (ds_node_id <> spatial.ds_node_id);
```
**See:** `../01 InfoWorks/0003` for intersecting conduit detection

---

## User Interaction Patterns

### PAT_SQL_PROMPT_036 - Basic Prompt
**Intent:** Get numeric or string input from user.

```sql
LET $iterations = 3;
LET $min_speed = 0.5;

PROMPT TITLE 'Define Parameters';
PROMPT LINE $iterations 'Number of iterations upstream' DP 0;
PROMPT LINE $min_speed 'Minimum assumed average velocity' DP 3;
PROMPT DISPLAY;
```

---

### PAT_SQL_PROMPT_037 - Dropdown List Selection
**Intent:** Let user choose from a predefined list.

```sql
LIST $surface_types = 'All', 'Surface 1', 'Surface 2', 'Surface 3';

PROMPT TITLE 'Select Surface Type';
PROMPT LINE $selection 'Surface' STRING LIST $surface_types;
PROMPT DISPLAY;
```

---

### PAT_SQL_PROMPT_038 - Dynamic List from Data
**Intent:** Build a selection list from actual data in the network.

```sql
LIST $materials STRING;
SELECT DISTINCT pipe_material INTO $materials;

PROMPT TITLE 'Filter by Material';
PROMPT LINE $selected_material 'Material' STRING LIST $materials;
PROMPT DISPLAY;

SELECT WHERE pipe_material = $selected_material;
```

---

### PAT_SQL_PROMPT_039 - Read-Only Confirmation Dialog
**Intent:** Show information and let user OK/Cancel before proceeding.

```sql
SELECT COUNT(count(ds_links.*) = 1 AND link_suffix > 1) INTO $n;

PROMPT TITLE 'Press OK to continue or Cancel to review';
PROMPT LINE $n 'Number of affected objects';
PROMPT DISPLAY READONLY;
```
**See:** `../01 InfoWorks/0024` for confirmation before update

---

## Looping Patterns

### PAT_SQL_LOOP_040 - Iterate Through List
**Intent:** Process each item in a list sequentially.

```sql
LIST $oids STRING;
SELECT DISTINCT oid INTO $oids;

LET $i = 1;
WHILE $i <= LEN($oids);
    LET $current_oid = AREF($i, $oids);

    // Process individual object
    SELECT conduit_width INTO $width WHERE oid = $current_oid;
    SET user_text_1 = 'Processed' WHERE oid = $current_oid;

    LET $i = $i + 1;
WEND;
```

---

### PAT_SQL_LOOP_041 - Loop with Condition
**Intent:** Loop until a condition is met (not counter-based).

```sql
LET $chainage = $distance;
WHILE $chainage < $length;
    // Create intermediate objects at chainage points
    LET $new_x = $x_us + ($v_x * $chainage / $length);
    LET $new_y = $y_us + ($v_y * $chainage / $length);

    INSERT INTO Node (node_id, x, y)
    VALUES ($prefix + '_' + $chainage, $new_x, $new_y);

    LET $chainage = $chainage + $distance;
WEND;
```
**See:** `../02 SWMM/0003` for splitting links with geometric interpolation

---

### PAT_SQL_LOOP_042 - Loop with BREAK
**Intent:** Exit a loop early when a condition is met.

```sql
LET $i = 1;
WHILE $i <= LEN($oids);
    LET $current = AREF($i, $oids);
    SELECT ground_level INTO $gl WHERE oid = $current;

    IF $gl > 0 AND $gl < 10;
        BREAK;
    ENDIF;

    LET $i = $i + 1;
WEND;
```

---

## File I/O Patterns

### PAT_SQL_FILE_043 - Save Variables to File
**Intent:** Persist variable values to an external file.

```sql
SAVE $x, $y, $z, $label TO FILE 'C:\Temp\output.txt';

// Or using a variable path
LET $path = 'C:\Temp\results.txt';
SAVE ALL TO FILE $path;
```

---

### PAT_SQL_FILE_044 - Load Variables from File
**Intent:** Read previously saved variable values from a file.

```sql
LIST $codes STRING;
LET $threshold = 0.0;

LOAD $codes, $threshold FROM FILE 'C:\Temp\saved_data.txt';
```

---

## Scenario Operations

### PAT_SQL_SCENARIO_045 - Copy Data Between Scenarios
**Intent:** Transfer field values from one scenario to another.

```sql
// Copy from base to named scenario
UPDATE [All Links] IN BASE SCENARIO SET $column = user_number_1;
UPDATE [All Links] IN SCENARIO 'design' SET user_number_1 = $column;
```
**See:** `../01 InfoWorks/0002` for full scenario copy workflow

---

### PAT_SQL_SCENARIO_046 - Compare Scenarios
**Intent:** Find objects that differ between scenarios.

```sql
// Store base scenario values
UPDATE IN SCENARIO 'original' SET $base_value = user_number_1;

// Select objects where current scenario differs
SELECT WHERE $base_value <> user_number_1;
```

---

### PAT_SQL_SCENARIO_047 - Add/Drop Scenarios
**Intent:** Create or remove scenarios programmatically.

> **WARNING:** `ADD SCENARIO` and `IN SCENARIO 'name'` (for the same name) cannot appear in the same SQL block — ICM validates all scenario references before executing any statements. Split into separate, ordered scripts. See Lessons_Learned.

```sql
// Add scenarios
ADD SCENARIO 'design_v2';
ADD SCENARIO 'design_v3' BASED ON 'design_v2';

// Remove a scenario
DROP SCENARIO 'old_design';

// Using a variable
LET $name = 'new_scenario';
ADD SCENARIO $name;
```

---

## Reporting Patterns

### PAT_SQL_REPORT_048 - GROUP BY with Aggregation
**Intent:** Summarize data by categories.

```sql
// Count objects per system type
SELECT COUNT(*) AS [Count], system_type GROUP BY system_type;

// Multiple aggregations
SELECT system_type,
    COUNT(*) AS [Count],
    SUM(contributing_area) AS [Total Area],
    AVG(contributing_area) AS [Avg Area]
GROUP BY system_type;

// Bucket objects using RINDEX
LIST $breaks = 0, 0.3, 0.5, 1.0;
SET $bucket = RINDEX(sim.max_Surcharge, $breaks);
SELECT $bucket, COUNT(*) GROUP BY $bucket;
```
**See:** `../01 InfoWorks/0049` for complex aggregation with IIF

---

### PAT_SQL_REPORT_049 - Export to CSV File
**Intent:** Write query results to a CSV file.

```sql
SELECT node_id, x, y, ground_level
INTO FILE 'C:\Temp\node_export.csv'
WHERE ground_level > 50
ORDER BY ground_level DESC;

// GROUP BY to file
SELECT system_type, COUNT(*), SUM(contributing_area)
INTO FILE 'C:\Temp\summary.csv'
GROUP BY system_type;
```

---

### PAT_SQL_REPORT_050 - TOP/BOTTOM with ORDER BY
**Intent:** Retrieve the highest or lowest N objects.

```sql
// Top 5 nodes by ground level
SELECT TOP 5 node_id, ground_level ORDER BY ground_level DESC;

// Bottom 10 percent
SELECT BOTTOM 10 PERCENT node_id, ground_level ORDER BY ground_level ASC;

// With ties (include all objects matching the last value)
SELECT TOP 10 node_id, ground_level WITH TIES ORDER BY ground_level DESC;

// Variable count
LET $n = 5;
SELECT TOP $n node_id, ground_level ORDER BY ground_level DESC;

// TOP with UPDATE - only modify the top N
UPDATE TOP 10 SET user_number_1 = 1 ORDER BY ground_level DESC;
```

---

### PAT_SQL_REPORT_051 - HAVING Filter on Groups
**Intent:** Filter group results after aggregation.

```sql
// Only show materials with more than 10 objects
SELECT COUNT(*) AS [Count]
GROUP BY material, network.name
HAVING COUNT(*) > 10
ORDER BY COUNT(*);
```

---

### PAT_SQL_REPORT_052 - RANK Assignment
**Intent:** Assign positional rank to objects based on a sort order.

```sql
// Assign rank (tied values get equal rank)
SET $r = rank ORDER BY ground_level DESC;

// Display with rank
SELECT node_id, ground_level, $r ORDER BY $r ASC;
```
