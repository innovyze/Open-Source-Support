# InfoWorks ICM SQL Syntax & Language Reference for LLM Agents

**Source:** SQL Combined Help Documentation
**Last Updated:** March 18, 2026

**Load Priority:** CORE - Load for syntax questions, data type behavior, and join navigation
**Load Condition:** CONDITIONAL - When query involves syntax details, data types, implicit joins, operators, or advanced clause structure

## Purpose

This guide provides **language syntax and data model reference** for InfoWorks ICM SQL.

**For LLMs:** Use this file to:
- Understand clause structure and keyword ordering rules
- Look up data type behavior and type conversion rules
- Navigate implicit join tables (one-to-one and one-to-many)
- Understand NULL behavior (3-valued logic)
- Learn string operator details (LIKE, MATCHES)
- Understand bare array field vs. aggregate function interaction rules
- Reference SELECT clause types (explicit, GROUP BY, implicit GROUP BY)

**Prerequisite:** Read `Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_SQL_Lessons_Learned.md` - Read FIRST - Critical gotchas
- `InfoWorks_ICM_SQL_Function_Reference.md` - Function signatures and aggregates
- `InfoWorks_ICM_SQL_Pattern_Reference.md` - Working code templates
- `InfoWorks_ICM_SQL_Schema_Common.md` - Database field name lookups, IW vs SWMM differences, Autodesk Help workflow
- `InfoWorks_ICM_SQL_Error_Reference.md` - Error message diagnosis

---

## SQL Block Structure

A query consists of one or more **clauses** separated by semicolons.

**Clause types:**
1. **SELECT** - Select objects or produce report grids/CSV
2. **DESELECT** - Remove objects from selection
3. **DELETE** - Remove objects from network or blob rows
4. **SET / UPDATE** - Modify field values
5. **INSERT** - Create new objects or blob rows
6. **CLEAR SELECTION** - Clear all selections
7. **ADD SCENARIO / DROP SCENARIO** - Manage scenarios (ICM/InfoNet only)
8. **LET / LIST / SAVE / LOAD / SCALARS** - Variable management
9. **PROMPT LINE / PROMPT TITLE / PROMPT DISPLAY** - User dialogs
10. **IF / ELSEIF / ELSE / ENDIF / WHILE / WEND / BREAK** - Control flow

---

## Arithmetic & Comparison Operators

### Arithmetic (in precedence order, highest first)
| Operator | Description | Precedence |
|----------|-------------|------------|
| `-` (unary) | Negation | Highest |
| `^` | Exponentiation | |
| `*`, `/` | Multiplication, Division | |
| `+`, `-` | Addition/Concatenation, Subtraction | Lowest |
| `%` | Modulus | Same as `*`, `/` |

Use parentheses to override precedence. `a * (b + c)` forces addition first.

### Comparison
| Operator | Description |
|----------|-------------|
| `=` | Equal (also works with NULL) |
| `<>` | Not equal |
| `>`, `>=`, `<`, `<=` | Greater/less than |

Comparison operators have **lower** precedence than arithmetic: `a + b * c >= d + e` evaluates arithmetic first.

### Logical
| Operator | Description | Precedence |
|----------|-------------|------------|
| `NOT` | Invert | Higher |
| `AND` | Both true | |
| `OR` | Either true (inclusive) | Lower |

`A OR B AND C` means `A OR (B AND C)`. Use parentheses to clarify.

---

## Data Types

### Constants
| Type | Syntax | Examples |
|------|--------|---------|
| Number | Plain digits, optional decimal/sign | `123`, `-45.67`, `0.001` |
| String | Single or double quotes | `'text'`, `"text"` |
| Boolean | Keywords | `true`, `false` |
| Date | Hash delimiters, locale-dependent | `#31/1/2008#` (UK), `#1/31/2008#` (US) |
| NULL | Keyword | `NULL` |

**Notes:**
- No scientific notation (1.5e3 is invalid)
- String within single quotes can contain double quotes and vice versa
- Date format depends on Windows locale settings
- Boolean fields are never NULL in SQL (NULL treated as `false`)

### Type Conversion Rules

When mixing types in binary operations, rules are applied in this order:

1. **`= NULL`** → true only if both NULL; **`<> NULL`** → true only if one NULL
2. **`+ string`** → other value converted to string, concatenated
3. **Any operator (except OR) with NULL** → result is NULL
4. **`OR` with NULL** → other value converted to boolean; if true, result is true
5. **`+`, `-`, `/`, `*`, `^`** → both converted to numbers
6. **`OR`** (non-NULL) → both converted to boolean
7. **`AND`** → both converted to boolean
8. **Comparison operators** → if either is date, convert and compare; else if either is string, convert and compare; else compare as numbers
9. **`LIKE`, `MATCHES`** → false unless both are strings

### Conversion to String
- Boolean: `true` → `'1'`, `false` → `'0'`
- Number: Standard format, trailing zeros removed. `12.34000` → `'12.34'`, `123.00` → `'123'`
- Date: Short form (dd/mm/yyyy or mm/dd/yyyy depending on locale) with hh:mm time appended

### Conversion to Boolean
- **True:** Any non-empty string, any date, any non-zero number
- **False:** NULL, empty string `''`, zero `0`

### Conversion to Number
- Date → floating point days since 30 December 1899 (Microsoft convention)
- String → number if string contains only a number, otherwise `0`
- Boolean → `true` = 1, `false` = 0

---

## NULL Handling (3-Valued Logic)

| Expression | Result |
|------------|--------|
| `NULL = NULL` | `true` |
| `NULL <> NULL` | `false` |
| `value = NULL` (where value is not NULL) | `false` |
| `value <> NULL` (where value is not NULL) | `true` |
| `NULL + 5` | `NULL` |
| `NULL AND true` | `NULL` |
| `NULL OR true` | `true` |
| `NULL OR false` | `false` |
| `NOT NULL` | `NULL` |

**Key principle:** NULL represents an absent/unknown value. Operations with NULL produce NULL, except for the special cases above.

Fields return NULL when:
- A numeric field is blank/empty
- An object doesn't have the field (e.g., querying `[All Links]` and the object is a conduit but the field is flap-valve-specific)

---

## String Operators

### LIKE
Pattern matching with two wildcards:
- `?` — matches any single character
- `*` — matches the rest of the string (can only appear at the end)

```sql
node_id LIKE 'MH*'          // Starts with MH
node_id LIKE '????????'     // Exactly 8 characters
node_id LIKE 'MH??????'     // MH followed by 6 characters
node_id LIKE '??1????'      // 3rd character is 1
node_id LIKE 'MH??*'        // MH + at least 2 more characters
```

**Limitations:** Cannot use `*` at the beginning or check content after `*`. `*01` and `*01*` are invalid. For complex patterns, use MATCHES.

### MATCHES
Full regular expression matching. Case insensitive. Must match the **whole string**.

```sql
node_id MATCHES '[0-9]*'       // Only digits (note: * is regex quantifier here)
node_id MATCHES 'MH[0-9]+'    // MH followed by one or more digits
node_id MATCHES '.*01.*'      // Contains 01 anywhere
```

For notes fields, MATCHES works on multiline content. Use `\n` to match end of line.

---

## Implicit Joins (One-to-One)

These allow navigating from one object to a single related object via dot notation.

### ICM Modelling Network / CS / SD

| From | To | Name |
|------|----|------|
| Link | Node | `us_node` |
| Link | Node | `ds_node` |
| Subcatchment | Node | `node` |

### ICM / InfoNet Collection (Asset) Network

| From | To | Name |
|------|----|------|
| CCTV Survey | Pipe | `joined` (or `pipe`) |
| Manhole Survey | Manhole | `joined` (or `manhole`) |
| GPS Survey | Manhole | `joined` |
| Monitoring Survey | Pipe | `joined` |
| Pipe Repair | Pipe | `joined` |
| Manhole Repair | Manhole | `joined` |
| Dye Test | Pipe | `joined` |
| Smoke Test | Pipe | `joined` |
| Smoke Defect | Smoke Test | `joined` |
| General/Blockage/Pollution/Collapse/Flooding/Complaint/Odor Incident | Pipe | `joined` |
| Link | Node | `us_node` |
| Link | Node | `ds_node` |
| Node | Pipe | `lateral_pipe` |

### ICM / InfoNet Distribution (Asset) Network

| From | To | Name |
|------|----|------|
| GPS Survey / Monitoring Survey | Node | `joined` |
| Manhole Survey | Manhole | `joined` |
| Pipe Repair | Pipe | `joined` |
| Manhole Repair | Manhole | `joined` |
| Pipe Sample | Pipe | `joined` |
| General/Burst/Water Quality/Complaint Incident | Pipe | `joined` |
| Link | Node | `us_node` |
| Link | Node | `ds_node` |
| Node | Pipe | `lateral_pipe` |

### InfoWorks WS

| From | To | Name |
|------|----|------|
| Customer Point | Link | `pipe` |
| Incident Report | Link | `pipe` |
| Link | Node | `us_node` |
| Link | Node | `ds_node` |
| Demand Polygon | Node | `node` |

**Note:** The `joined` prefix appears in the grid as italic fields to the right of the object. In ICM/InfoNet there is always an alternative name reflecting the actual joined type.

---

## One-to-Many Links

These allow accessing multiple related objects. Use with aggregate functions or bare field references.

### ICM Modelling Network

| From | To | Name |
|------|----|------|
| Node | Link | `us_links` |
| Node | Link | `ds_links` |
| Link | Link | `us_links` |
| Link | Link | `ds_links` |
| Node | Subcatchment | `subcatchments` |

**Special:** `all_us_links` and `all_ds_links` perform a full network trace (all upstream/downstream links).

### Collection (Asset) Network

| From | To | Name |
|------|----|------|
| Node | Link | `us_links` / `ds_links` |
| Pipe | CCTV Survey | `cctv_surveys` |
| Pipe | Monitoring Survey | `monitoring_surveys` |
| Pipe | Pipe Repair | `pipe_repairs` |
| Pipe | Smoke Test | `smoke_tests` |
| Pipe | Dye Test | `dye_tests` |
| Pipe | General Incident | `incidents` |
| Pipe | Property | `properties` |
| Manhole | Manhole Survey | `manhole_surveys` |
| Manhole | Manhole Repair | `manhole_repairs` |
| Manhole | GPS Survey | `gps_surveys` |
| Manhole | Drain Test | `drain_tests` |
| Manhole | Monitoring Survey | `monitoring_surveys` |
| Smoke Test | Smoke Defect | `smoke_defects` |
| Data Logger | Monitoring Survey | `monitoring_surveys` |
| Property | Incident | `incidents` |

---

## Bare Array Fields vs. Aggregate Functions

### Bare field in WHERE clause
When an array field appears outside an aggregate function in a WHERE clause, the expression is evaluated for **each row** of the array:

```sql
// True if ANY detail has code GP (equivalent to ANY(details.code='GP'))
SELECT WHERE details.code = 'GP';

// CAUTION: True if ANY detail has code OTHER than GP (NOT "none have GP")
SELECT WHERE details.code <> 'GP';

// To find objects where NO detail has GP:
SELECT WHERE NOT ANY(details.code = 'GP');
```

### Bare field in SET clause
When an array field appears outside an aggregate in a SET clause:

```sql
// Sets width for EVERY pipe-in record in EVERY manhole survey
SET pipes_in.width = 123;

// Sets only for objects meeting the WHERE condition
SET pipes_in.width = 234 WHERE shaft_depth = 1650;

// Sets only for matching array rows
SET pipes_in.width = 345 WHERE pipes_in.diameter > 200;
```

**Restriction:** a single expression can reference only **one** bare array field. Multiple references to the same array field are allowed, but mixing different array fields is not.

```sql
// CORRECT - one array field in this expression
SET left_bank.modular_ratio = 0.67, left_bank.discharge_coeff = 0.8 WHERE $selected = 1;

// CORRECT - different array field, separate clause
SET right_bank.modular_ratio = 0.67, right_bank.discharge_coeff = 0.8 WHERE $selected = 1;

// WRONG - mixes left_bank and right_bank in one expression
UPDATE SELECTED [River Reach]
SET left_bank.modular_ratio = 0.67,
    right_bank.modular_ratio = 0.67;
```

### Interaction: Bare WHERE + Aggregate SET
If bare array fields appear in WHERE and aggregates in SET, the aggregate only considers rows matching the WHERE:

```sql
// Sum service_score only for detail rows with code 'DE'
SET user_number_1 = SUM(details.service_score) WHERE details.code = 'DE';
```

If an aggregate appears **in** the WHERE clause, it runs on all rows:
```sql
// Uses ALL details rows for COUNT, not just filtered ones
SET user_number_1 = 1 WHERE COUNT(details.code = 'DE') > 5;
```

### Flags as Array Fields
Object flags can be treated like array fields with two fields: `value` and `name`.

```sql
SELECT oid, COUNT(flags.value = 'S1');
SELECT WHERE ANY(flags.value = 'XX');
```

---

## SELECT Clause Types

### 1. Explicit SELECT (one row per object)
Produces a grid/CSV with one line per matching object.

```sql
SELECT node_id, x, y, ground_level WHERE ground_level > 50;
SELECT us_node_id, ds_node_id, conduit_width ORDER BY conduit_width DESC;
SELECT node_id INTO FILE 'C:\Temp\output.csv' WHERE node_type = 'outfall';
```

### 2. GROUP BY SELECT (one row per group)
Aggregates objects into groups.

```sql
SELECT system_type, COUNT(*) AS [Count], AVG(conduit_width) AS [Avg Width]
GROUP BY system_type
HAVING COUNT(*) > 5
ORDER BY COUNT(*) DESC;
```

### 3. Implicit GROUP BY (no GROUP BY keyword, but uses aggregates)
Aggregates over all objects (or all matching WHERE).

**How it's distinguished from explicit SELECT:**
- Contains aggregate functions operating at group level (not on array/one-to-many fields)
- Contains nested aggregates like `SUM(COUNT(details.*))`

```sql
// Implicit GROUP BY: aggregates over all objects
SELECT COUNT(*) INTO $total;
SELECT MAX(x) INTO $max_x, MIN(y) INTO $min_y;
```

### SELECT INTO for Scalar Assignment
```sql
SELECT COUNT(*) INTO $count;
SELECT MAX(ground_level) INTO $max_gl, MIN(ground_level) INTO $min_gl;
```

---

## Clause Keyword Ordering

Required ordering within a clause:

**SELECT/DESELECT/DELETE:**
`SELECT [ALL|SELECTED] [FROM table] [IN SCENARIO ...] [WHERE ...] [GROUP BY ...] [HAVING ...] [ORDER BY ...]`

**SET/UPDATE:**
`[UPDATE [ALL|SELECTED] table] SET field = expr [, field = expr ...] [IN SCENARIO ...] [WHERE ...] [ORDER BY ...]`

**Key rules:**
- WHERE must come before GROUP BY
- HAVING must come after GROUP BY
- ORDER BY always last
- INTO FILE comes before ORDER BY but after WHERE
- TOP/BOTTOM comes after SELECT keyword

---

## Scenario Operations (ICM/InfoNet Only)

```sql
// Override current scenario
SELECT IN BASE SCENARIO WHERE x > 100;
SELECT IN SCENARIO 'design' WHERE x > 100;
SELECT IN SCENARIO $var_name WHERE x > 100;
UPDATE [All Links] IN SCENARIO 'test' SET user_number_1 = 0;

// Add/remove scenarios
ADD SCENARIO 'new_design';
ADD SCENARIO 'v2' BASED ON 'v1';
DROP SCENARIO 'old_design';
```

Variables exist independently of scenarios — there are no scenario-dependent variables.

---

## Control Flow

### IF / ELSEIF / ELSE / ENDIF
```sql
IF expression;
    // statements
ELSEIF expression;
    // statements
ELSE;
    // statements
ENDIF;
```
Note: ELSEIF and ENDIF are each one word.

### WHILE / WEND
```sql
WHILE expression;
    // statements
WEND;
```
A progress bar appears during WHILE loops. User can break into the query.

### BREAK
Exits the immediately containing WHILE loop.
```sql
WHILE $i <= LEN($list);
    IF $found = 1;
        BREAK;
    ENDIF;
    LET $i = $i + 1;
WEND;
```

---

## Cross-Network Queries

Available via Tools menu for asset networks. The network name and ID can be used:
```sql
network.name    // Name of the network
network.id      // ID of the network
```

Queries are typically developed on a single network then run cross-network.

---

## Common Field Names - Quick Reference

**IMPORTANT:** InfoWorks and SWMM networks use **different field names**. See `InfoWorks_ICM_SQL_Schema_Common.md` for the complete workflow to find correct field names.

### Universal Fields (All Objects)
- `oid` — Unique object identifier (read-only)
- `user_text_1` through `user_text_10` — Custom text fields
- `user_number_1` through `user_number_10` — Custom numeric fields

### InfoWorks Node
`node_id`, `x`, `y`, `ground_level`, `node_type`, `flood_type`, `chamber_floor_level`, `shaft_area`

### SWMM Node
`node_id`, `x`, `y`, `ground_level`, `maximum_depth`, `initial_depth`, `surcharge_depth`

### InfoWorks Conduit
`us_node_id`, `ds_node_id`, `link_suffix`, `conduit_length`, `conduit_width`, `conduit_height`, `shape`, `conduit_material`, `system_type`, `us_invert`, `ds_invert`

### SWMM Conduit
`id`, `us_node_id`, `ds_node_id`, `length`, `conduit_width`, `conduit_height`, `shape`, `number_of_barrels`, `Mannings_N`, `us_invert`, `ds_invert`

### InfoWorks Subcatchment
`subcatchment_id`, `node_id`, `contributing_area`, `area_measurement_type`, `runoff_index`

### SWMM Subcatchment
`subcatchment_id`, `outlet_id`, `raingauge_id`, `sw_drains_to`, `area`, `width`, `catchment_slope`, `percent_impervious`

### Results Fields
- **Summary:** `sim.max_depth`, `sim.max_flow`, `sim.max_Surcharge`
- **Time Series:** `tsr.ds_depth`, `tsr.us_depth`, `tsr.ds_flow`, `tsr.us_flow`, `tsr.us_vel`, `tsr.ds_vel`
- **Time Series Meta:** `tsr.timestep_no`, `tsr.timesteps`, `tsr.timestep_start`, `tsr.timestep_duration`

### InfoAsset Manager
`pipe_material`, `asset_id`, `cctv_surveys.structural_grade`, `details.code`
