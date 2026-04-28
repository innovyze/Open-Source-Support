# InfoWorks ICM SQL - Critical Lessons for LLM Agents

**Purpose:** High-priority warnings about InfoWorks ICM SQL behavior that differs from standard SQL. Load this FIRST before generating any query.

**Load Priority:** CRITICAL - Always load FIRST before any code generation
**Last Updated:** March 18, 2026

## How to Use This File

**For LLMs:** Read this file FIRST before generating any InfoWorks ICM SQL query. It contains critical anti-patterns and gotchas that will cause queries to fail. After reading this file, proceed to:
1. `InfoWorks_ICM_SQL_Function_Reference.md` - For function signatures and aggregates
2. `InfoWorks_ICM_SQL_Pattern_Reference.md` - For working code templates
3. `InfoWorks_ICM_SQL_Syntax_Reference.md` - For language syntax and data types
4. `InfoWorks_ICM_SQL_Schema_Common.md` - For correct database field names, IW vs SWMM differences, and Autodesk Help lookup workflow
5. `InfoWorks_ICM_SQL_Tutorial_Context.md` - For complete examples and workflows
6. `InfoWorks_ICM_SQL_Error_Reference.md` - When debugging errors
7. `InfoWorks_ICM_SQL_Glossary.md` - For terminology clarification

**Cross-References:**
- See `Function_Reference.md` for complete function signatures
- See `Pattern_Reference.md` for PAT_SQL_INIT_001, PAT_SQL_SEL_004 examples
- See `Error_Reference.md` for detailed error message diagnosis

---

## CRITICAL: This is NOT Standard ANSI SQL

### The Problem

InfoWorks ICM implements a **proprietary subset of SQL** specifically designed for hydraulic network modeling. Many standard SQL features do NOT exist, and several features work differently than expected.

**NOT Supported:**
```sql
// WRONG - CASE WHEN does not exist
SELECT CASE WHEN width > 600 THEN 'Large' ELSE 'Small' END FROM Conduit

// WRONG - Standard JOINs do not exist
SELECT n.node_id, c.conduit_width
FROM Node n JOIN Conduit c ON c.us_node_id = n.node_id

// WRONG - Subqueries in WHERE do not exist
SELECT FROM Node WHERE ground_level > (SELECT AVG(ground_level) FROM Node)

// WRONG - UNION, INTERSECT, EXCEPT do not exist
SELECT node_id FROM Node WHERE x > 100
UNION
SELECT node_id FROM Node WHERE y > 200

// WRONG - Window functions do not exist
SELECT node_id, ROW_NUMBER() OVER (ORDER BY ground_level) FROM Node

// WRONG - CREATE TABLE, ALTER TABLE do not exist
CREATE TABLE my_results (id TEXT, value REAL)

// WRONG - Transactions (BEGIN, COMMIT, ROLLBACK) do not exist
BEGIN TRANSACTION

// WRONG - Stored procedures / user-defined functions do not exist
CREATE FUNCTION my_func(x REAL) RETURNS REAL
```

### LLM Agent Rules

1. **NEVER use** CASE WHEN - use `IF/ELSEIF/ELSE/ENDIF` or `IIF()` instead
2. **NEVER use** JOIN - use dot notation navigation instead (e.g., `us_node.ground_level`)
3. **NEVER use** subqueries - use variables and multiple clauses instead
4. **NEVER use** UNION, INTERSECT, EXCEPT, window functions, CREATE TABLE, ALTER TABLE
5. **NEVER use** BEGIN/COMMIT/ROLLBACK transactions
6. **NEVER use** IS NULL / IS NOT NULL for comparisons (use `= NULL` / `<> NULL`) — but note `IS NULL` and `IS NOT NULL` do work as unary operators for testing

---

## CRITICAL: No CASE Statement - Use IF/ELSEIF/ELSE or IIF()

### The Problem

LLMs trained on standard SQL will instinctively reach for CASE WHEN. It does not exist.

**What FAILS:**
```sql
// WRONG - CASE WHEN not supported
SELECT CASE WHEN conduit_width >= 600 THEN 'Large'
            WHEN conduit_width >= 300 THEN 'Medium'
            ELSE 'Small' END
FROM Conduit
```

**What WORKS - For inline conditionals, use IIF():**
```sql
// CORRECT - IIF for simple conditions
SET user_text_1 = IIF(conduit_width >= 600, 'Large', 'Small');

// CORRECT - Nested IIF for multiple conditions
SET user_text_1 = IIF(conduit_width >= 600, 'Large',
                  IIF(conduit_width >= 300, 'Medium', 'Small'));
```

**What WORKS - For procedural logic, use IF blocks:**
```sql
// CORRECT - IF/ELSEIF/ELSE/ENDIF
IF conduit_width >= 600;
    SET user_text_1 = 'Large';
ELSEIF conduit_width >= 300;
    SET user_text_1 = 'Medium';
ELSE;
    SET user_text_1 = 'Small';
ENDIF;
```

### LLM Agent Rules

1. **Use `IIF(condition, true_value, false_value)`** for inline conditionals
2. **Use `IF condition; ... ELSEIF condition; ... ELSE; ... ENDIF;`** for procedural logic
3. **Semicolons are required** after IF, ELSEIF, ELSE, and ENDIF

---

## CRITICAL: No Standard JOINs - Use Dot Notation Navigation

### The Problem

InfoWorks ICM SQL uses **implicit joins** via dot notation instead of explicit JOIN syntax. The software knows its own data structure and navigates relationships automatically.

**What FAILS:**
```sql
// WRONG - JOIN syntax does not exist
SELECT n.node_id, c.conduit_width
FROM Node n
JOIN Conduit c ON c.us_node_id = n.node_id
```

**What WORKS:**
```sql
// CORRECT - Navigate from link to its upstream node
SELECT us_node.ground_level WHERE us_node.ground_level > 100;

// CORRECT - Navigate from node to connected links
SET us_links.$link_selected = 1 WHERE $node_selected = 1;

// CORRECT - Navigate from subcatchment to its node
SELECT node.ground_level FROM Subcatchment;
```

**Navigation Keywords:**
- `us_node` / `ds_node` - Upstream/downstream node from a link
- `us_links` / `ds_links` - Links immediately connected to a node
- `all_us_links` / `all_ds_links` - All upstream/downstream links (full network trace)
- `node` - Node from a subcatchment
- `spatial.field` - Spatially related objects
- `joined` - Associated object in asset networks (e.g., CCTV Survey → Pipe)
- `cctv_surveys` / `manhole_surveys` etc. - One-to-many survey links (InfoAsset Manager)

---

## CRITICAL: Every Query Needs Object Type and Spatial Context

### The Problem

InfoWorks ICM SQL operates on **network objects**, not database tables. Every query must specify what object type it targets.

**What FAILS:**
```sql
// WRONG - No object type specified
SELECT node_id, ground_level WHERE ground_level > 100;
```

**What WORKS:**
```sql
// CORRECT - Object type and spatial context in header comments
//Object: Node
//Spatial Search: blank

SELECT node_id, ground_level WHERE ground_level > 100;
```

### LLM Agent Rules

1. **ALWAYS include** `//Object: <type>` as the first line of every query
2. **ALWAYS include** `//Spatial Search: blank` (or appropriate spatial search) as the second line
3. Common object types: `Node`, `Conduit`, `Subcatchment`, `Pump`, `Weir`, `Orifice`, `River Reach`, `Polygon`, `All Nodes`, `All Links`
4. For InfoAsset Manager: `Pipe`, `Manhole`, `CCTV Survey`, `Manhole Survey`

---

## CRITICAL: Arrays and Lists Are 1-Indexed

### The Problem

AREF() and other list functions use **1-based indexing**, not 0-based. LLMs trained on most programming languages will default to 0-indexed.

**What FAILS:**
```sql
// WRONG - 0-indexed access
LET $first = AREF(0, $my_list);
```

**What WORKS:**
```sql
// CORRECT - 1-indexed access
LET $first = AREF(1, $my_list);

// CORRECT - Loop pattern
LET $i = 1;
WHILE $i <= LEN($my_list);
    LET $current = AREF($i, $my_list);
    // ... process ...
    LET $i = $i + 1;
WEND;
```

### LLM Agent Rules

1. **ALWAYS start loops at 1** (not 0) when iterating lists
2. **AREF(1, $list)** returns the first element
3. **LEN($list)** returns the count; last element is `AREF(LEN($list), $list)`

---

## CRITICAL: Semicolons Required After Every Statement

### The Problem

Every clause must end with a semicolon. Missing semicolons cause parse errors.

**What FAILS:**
```sql
// WRONG - Missing semicolons
LET $i = 1
WHILE $i <= 10
    SET user_number_1 = $i
    LET $i = $i + 1
WEND
```

**What WORKS:**
```sql
// CORRECT - Semicolons after every statement
LET $i = 1;
WHILE $i <= 10;
    SET user_number_1 = $i;
    LET $i = $i + 1;
WEND;
```

### LLM Agent Rules

1. **ALWAYS add `;`** after every clause: LET, LIST, SET, UPDATE, SELECT, IF, ELSEIF, ELSE, ENDIF, WHILE, WEND, BREAK, PROMPT, SPATIAL, INSERT, DELETE, DESELECT, CLEAR SELECTION
2. **Control flow keywords need semicolons too:** `IF condition;`, `ELSEIF condition;`, `ELSE;`, `ENDIF;`, `WHILE condition;`, `WEND;`

---

## CRITICAL: No FOR Loops - Use WHILE/WEND

### The Problem

FOR loops do not exist. Use WHILE/WEND with manual counters.

**What FAILS:**
```sql
// WRONG - FOR loops don't exist
FOR $i = 1 TO LEN($oids)
    // ...
NEXT
```

**What WORKS:**
```sql
// CORRECT - WHILE/WEND with manual counter
LET $i = 1;
WHILE $i <= LEN($oids);
    LET $current = AREF($i, $oids);
    // ... process ...
    LET $i = $i + 1;
WEND;
```

### LLM Agent Rules

1. **ALWAYS use** `WHILE condition; ... WEND;`
2. **ALWAYS manually increment** the counter inside the loop
3. **BREAK** can be used to exit a loop early (within an IF block)
4. There is no CONTINUE statement

---

## CRITICAL: Variables Must Be Declared Before Use

### The Problem

Scalar variables use `LET`, list variables use `LIST`. They must be declared before use in expressions (though object variables prefixed with `$` are created implicitly on first assignment in SET clauses).

**What FAILS:**
```sql
// WRONG - Using undeclared scalar in expression
LET $result = $threshold * 2;  // $threshold not yet declared
```

**What WORKS:**
```sql
// CORRECT - Declare before use
LET $threshold = 100;
LET $result = $threshold * 2;

// CORRECT - List declaration
LIST $widths = 100, 300, 500, 700;
LIST $codes = 'AB', 'CD', 'EF';
LIST $empty_list STRING;           // Empty string list for later population
```

### LLM Agent Rules

1. **LET** for scalar variables: `LET $name = value;`
2. **LIST** for list variables: `LIST $name = val1, val2, val3;` or `LIST $name STRING;`
3. **Object variables** (per-object) are auto-created: `SET $my_flag = 1;` creates `$my_flag` for each object
4. **LET can only assign constant values** — `LET $x = $y + 1;` works only with scalar expressions of already-defined scalars, not field values
5. **SELECT INTO** assigns query results to scalars: `SELECT COUNT(*) INTO $n;`

---

## CRITICAL: String Concatenation Uses + Not || or CONCAT()

### The Problem

```sql
// WRONG - Standard SQL concatenation
SET user_text_1 = node_id || '_suffix';
SET user_text_1 = CONCAT(node_id, '_suffix');

// CORRECT - Use + operator
SET user_text_1 = node_id + '_suffix';
```

---

## CRITICAL: Use "Database field" Names, Not UI "Field Names"

### The Problem

Users refer to fields by their display name in the UI (e.g., "Width"), but SQL requires the **database field** name (e.g., `conduit_width`). These are often different.

Additionally, **InfoWorks and SWMM networks use different field names** for the same concepts.

**What FAILS:**
```sql
// WRONG - Using display name
SELECT Width FROM Conduit;

// WRONG - Using InfoWorks length field in SWMM network
SELECT conduit_length FROM Conduit;  // SWMM uses 'length' instead
```

**What WORKS:**
```sql
// CORRECT - InfoWorks network
SELECT us_node_id, ds_node_id, conduit_width, conduit_length FROM Conduit;

// CORRECT - SWMM network (conduit_width is the same; only length field differs)
SELECT us_node_id, ds_node_id, conduit_width, length FROM Conduit;
```

### LLM Agent Rules

1. **ALWAYS ask** if the user is working with InfoWorks or SWMM network type
2. **ALWAYS use** the "Database field" name, not the "Field Name" from the UI
3. See `InfoWorks_ICM_SQL_Schema_Common.md` for the workflow to find correct field names

---

## IMPORTANT: Time Series Results (tsr.*) vs Summary Results (sim.*)

### The Problem

There are two ways to access simulation results, and they work differently:

- **`sim.*`** - Summary results at the current timestep or maximum. Returns a single value per object.
- **`tsr.*`** - Time series results across ALL timesteps. Requires aggregate functions.

**What FAILS:**
```sql
// WRONG - Using tsr.* without aggregate function
SELECT tsr.ds_depth WHERE tsr.ds_depth > 1.0;
```

**What WORKS:**
```sql
// CORRECT - sim.* for summary results (no aggregate needed)
SELECT sim.max_depth, sim.max_flow;

// CORRECT - tsr.* with aggregate function
SELECT MAX(tsr.ds_depth), WHENMAX(tsr.ds_depth);

// CORRECT - tsr.* with WHEN clause to limit timesteps
SELECT MAX(tsr.ds_depth) WHEN tsr.timestep_no > 20;
```

### LLM Agent Rules

1. **`tsr.*` ALWAYS requires** an aggregate function: MAX, MIN, AVG, COUNT, SUM, DURATION, INTEGRAL, FIRST, LAST, EARLIEST, LATEST, WHENMAX, WHENMIN, WHENEARLIEST, WHENLATEST, ALL, ANY
2. **`sim.*` does NOT** require aggregate functions
3. **AVG for tsr.* is TIME-WEIGHTED** — it is NOT a simple arithmetic average. It accounts for varying timestep lengths.
4. **tsr.* operates on results FILE timesteps**, not computational timesteps. `MAX(tsr.depth2d)` may differ from the stored maximum which uses all computational timesteps.
5. **AVG, INTEGRAL, and SUM skip the final timestep** because its duration is unknown.
6. Use **WHEN clauses** to limit timestep range: `WHEN tsr.timestep_no >= 10`

---

## IMPORTANT: NULL Comparison Behavior

### The Problem

InfoWorks SQL uses 3-valued logic for NULL, but the comparison syntax differs from standard SQL.

**Both work but have different meanings:**
```sql
// These unary operators work for testing NULL
SELECT WHERE ground_level IS NULL;
SELECT WHERE ground_level IS NOT NULL;

// The equality operator also works with NULL
SELECT WHERE ground_level = NULL;     // True only if ground_level IS NULL
SELECT WHERE ground_level <> NULL;    // True only if ground_level IS NOT NULL
```

**Key behavior:** Any arithmetic or comparison with NULL produces NULL (except `= NULL` and `<> NULL` which are special-cased, and OR where the other operand is true).

### LLM Agent Rules

1. **Both `IS NULL` and `= NULL` work** for testing NULL values
2. **Any operation with NULL returns NULL** (3-valued logic) except the special cases above
3. **Boolean fields are NEVER NULL** from SQL's perspective — NULL Booleans are treated as `false`
4. **Empty strings are different from NULL** — a text field can be `''` (empty) or NULL (blank/absent)

---

## IMPORTANT: Table Names with Spaces Need Square Brackets

### The Problem

Object type names containing spaces must be enclosed in square brackets.

**What FAILS:**
```sql
// WRONG - Spaces without brackets
SELECT FROM All Nodes WHERE ground_level > 100;
SELECT FROM River Reach WHERE bank_level > 50;
```

**What WORKS:**
```sql
// CORRECT - Square brackets around names with spaces
SELECT FROM [All Nodes] WHERE ground_level > 100;
SELECT FROM [River Reach] WHERE bank_level > 50;
SELECT FROM [Head Discharge] WHERE oid = $pump_id;

// OK - Single-word names don't need brackets (but brackets are always allowed)
SELECT FROM Conduit WHERE conduit_width > 300;
SELECT FROM [Conduit] WHERE conduit_width > 300;  // Also fine
```

---

## IMPORTANT: String Comparison is Case Insensitive

### The Problem

All string comparisons in InfoWorks SQL are **case insensitive**. This includes `=`, `<>`, `LIKE`, and `MATCHES`.

```sql
// These all match the same objects:
SELECT WHERE node_id = 'MH001';
SELECT WHERE node_id = 'mh001';
SELECT WHERE node_id = 'Mh001';
```

### LLM Agent Rules

1. **String comparisons are always case insensitive** — do not add UPPER() or LOWER() workarounds
2. **Strings are always trimmed** — no leading or trailing spaces or tabs
3. **LIKE** uses `?` (single char) and `*` (rest of string) — NOT `%` and `_` like standard SQL
4. **MATCHES** uses full regular expressions (case insensitive, must match whole string)

---

## IMPORTANT: LIKE Uses ? and * Not % and _

### The Problem

LLMs will instinctively use standard SQL wildcards. InfoWorks uses different ones.

**What FAILS:**
```sql
// WRONG - Standard SQL wildcards
SELECT WHERE node_id LIKE 'MH%';
SELECT WHERE node_id LIKE 'MH___';
```

**What WORKS:**
```sql
// CORRECT - InfoWorks wildcards
SELECT WHERE node_id LIKE 'MH*';       // MH followed by anything
SELECT WHERE node_id LIKE 'MH???';     // MH followed by exactly 3 characters
SELECT WHERE node_id LIKE '????????';  // Exactly 8 characters
```

### LLM Agent Rules

1. **`?`** matches any single character (equivalent to `_` in standard SQL)
2. **`*`** matches the rest of the string (similar to `%` but can only appear at the end)
3. **Cannot use `*` at both beginning and end** — `*01*` is NOT valid
4. **Cannot check after `*`** — `*01` does NOT match strings ending in 01
5. For complex pattern matching, use **MATCHES** with regular expressions instead

---

## IMPORTANT: Aggregate Functions on Arrays vs Groups vs Time Series

### The Problem

The same function names (COUNT, MAX, MIN, AVG, etc.) behave differently depending on context:

1. **Array/blob context:** Aggregate over rows within a single object's array field
   ```sql
   COUNT(details.code = 'GP')  // Count detail records with code GP for this CCTV survey
   ```

2. **GROUP BY context:** Aggregate over objects within a group
   ```sql
   SELECT COUNT(*) GROUP BY system_type  // Count objects per system type
   ```

3. **Time series context:** Aggregate over timesteps for each object
   ```sql
   MAX(tsr.ds_depth)  // Maximum depth across all timesteps for this object
   ```

4. **Nested aggregates (GROUP BY on arrays):** Aggregate the per-object aggregate over a group
   ```sql
   SELECT SUM(COUNT(details.*)) GROUP BY direction  // Sum of detail counts per direction
   ```

### LLM Agent Rules

1. **Context determines meaning** — same function, different behavior
2. **Cannot mix** bare array/one-to-many fields with time series results in the same query
3. **Nested aggregates** only valid in GROUP BY context (e.g., `SUM(COUNT(details.*))`)
4. **FIRST and LAST** are available for arrays and time series, but NOT for GROUP BY

---

## IMPORTANT: One Bare Array Field Per Expression

### The Problem

When using bare array fields outside aggregate functions, a single expression can reference only **one** array field. Multiple references to the **same** array field are fine, but mixing different array fields in one `SET`, `WHERE`, or `UPDATE ... SET` expression causes a parser error.

**What FAILS:**
```sql
// WRONG - references two different array fields in one assignment clause
UPDATE SELECTED [River Reach]
SET left_bank.modular_ratio = 0.67,
    left_bank.discharge_coeff = 0.8,
    right_bank.modular_ratio = 0.67,
    right_bank.discharge_coeff = 0.8;
```

**Typical error:**
```sql
Queries cannot access more than one array field
```

**What WORKS:**
```sql
// CORRECT - stamp selection, then update each array field separately
UPDATE SELECTED [River Reach] SET $selected = 1;
SET left_bank.modular_ratio = 0.67, left_bank.discharge_coeff = 0.8 WHERE $selected = 1;
SET right_bank.modular_ratio = 0.67, right_bank.discharge_coeff = 0.8 WHERE $selected = 1;
```

### LLM Agent Rules

1. **Never mix different bare array fields** in one expression
2. **Multiple references to the same array field are allowed** in one expression
3. When updating multiple array fields on the same object, **split them into separate clauses**
4. For selected objects, prefer **`UPDATE SELECTED [Object Type] SET $selected = 1;`** followed by separate `SET ... WHERE $selected = 1;` clauses

---

## IMPORTANT: ADD SCENARIO Cannot Be Used in the Same Block as IN SCENARIO

ICM validates **all scenario references in a SQL block before executing any statements**. If `ADD SCENARIO 'name'` and `IN SCENARIO 'name'` appear in the same block, validation fails because the scenario doesn't exist yet:

> *"The following scenarios are used in this SQL query but are currently invalid: name"*

**Split into separate, ordered SQL scripts:**
```sql
// SQL 1 — create scenarios
ADD SCENARIO 'design_v2';
ADD SCENARIO 'design_v3' BASED ON 'design_v2';

// SQL 2 — use the scenario (run after SQL 1)
UPDATE [Conduit] IN SCENARIO 'design_v2' SET conduit_width = conduit_width + 75;

// SQL 3 — next scenario (run after SQL 2)
UPDATE [Conduit] IN SCENARIO 'design_v3' SET conduit_width = conduit_width + 150;
```

Place scripts in a model group named alphanumerically (`01_...`, `02_...`) and drag the group to run in order.

### LLM Agent Rules

1. **Never place `ADD SCENARIO` and `IN SCENARIO 'name'` (for the same name) in the same SQL block**
2. All `ADD SCENARIO` calls can share one script; each scenario population pass needs its own script
