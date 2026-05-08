# InfoWorks ICM SQL Scripting - Glossary

**Purpose:** Define InfoWorks SQL-specific terms, operators, and concepts. Standard SQL terms with identical meanings in InfoWorks are NOT included.

**Load Priority:** REFERENCE - Load for terminology clarification
**Last Updated:** March 17, 2026

---

## Product & Environment

| Term | Definition |
|------|------------|
| **InfoWorks ICM** | Integrated Catchment Modeling software for hydraulic/hydrological simulation |
| **InfoAsset Manager** | Asset management product sharing the same SQL engine with additional survey/asset tables |
| **InfoWorks WS Pro** | Water supply modeling product sharing the same SQL engine (some variations) |
| **GeoPlan** | The map/plan view in InfoWorks ICM where SQL queries are typically run |
| **SQL Dialog** | The interface for entering and running SQL queries within the application |
| **Network** | A database object containing interconnected hydraulic elements (nodes, links, subcatchments) |
| **Modelling Network** | Network used for hydraulic simulation (InfoWorks or SWMM type) |
| **Collection Network** | Network for asset/survey data (InfoAsset Manager) — also called "Asset Network" |

---

## SQL Concepts

| Term | Definition |
|------|------------|
| **Clause** | A single statement in the SQL script, separated by semicolons. A script consists of one or more clauses. |
| **Sub-clause** | A part of a clause identified by a keyword (e.g., WHERE sub-clause, GROUP BY sub-clause, HAVING sub-clause) |
| **Object Type** | The type of network element being queried: Node, Conduit, Subcatchment, Pump, etc. Specified in header comments. |
| **Default Table** | The object type selected in the SQL dialog dropdown. Can be overridden with `FROM [table]`. |
| **Default Selection Behavior** | Controlled by the "Apply to current selection" checkbox. Overridden by `ALL` or `SELECTED` keywords. |
| **Object Variable** | A per-object variable (prefixed with `$`) that stores a value for each object. Created on first use in SET. |
| **Scalar Variable** | A single-value variable (prefixed with `$`) declared with `LET`. Holds one number, string, or date. |
| **List Variable** | An ordered collection variable (prefixed with `$`) declared with `LIST`. Holds multiple values of the same type. |
| **Implicit Join** | Automatic navigation between related objects via dot notation (e.g., `us_node.ground_level`). No explicit JOIN syntax. |
| **One-to-One Link** | A relationship where an object links to at most one other object (e.g., link → upstream node) |
| **One-to-Many Link** | A relationship where an object links to multiple objects (e.g., node → upstream links) |
| **Blob Table** | A nested/child table within an object (e.g., `details` in CCTV Survey, `sections` in River Reach, `HDP_table` in Head Discharge). Also called "structure blob" or "array field". |
| **Aggregate Function** | A function that reduces multiple values to one: COUNT, MAX, MIN, AVG, SUM, ANY, ALL, FIRST, LAST |
| **WHEN Clause** | A filter that limits which timesteps are processed in time-varying aggregate functions |
| **Explicit SELECT** | A SELECT that produces one output row per object (grid/CSV display) |
| **Implicit GROUP BY** | A SELECT with aggregate functions but no GROUP BY keyword — aggregates over all objects as one group |
| **Cross Network Query** | A query that runs across multiple networks simultaneously (Tools menu) |

---

## Network Navigation Keywords

*Quick-lookup summary. See `Syntax_Reference.md` → "Implicit Joins" for complete From→To relationship tables including asset and distribution networks.*

| Keyword | Direction | Context | Description |
|---------|-----------|---------|-------------|
| `us_node` | one-to-one | From link | Upstream node of a link |
| `ds_node` | one-to-one | From link | Downstream node of a link |
| `us_links` | one-to-many | From node | Links immediately upstream of a node |
| `ds_links` | one-to-many | From node | Links immediately downstream of a node |
| `all_us_links` | one-to-many | From node | ALL upstream links (full network trace) |
| `all_ds_links` | one-to-many | From node | ALL downstream links (full network trace) |
| `us_links` | one-to-many | From link | Links upstream of this link's upstream node |
| `ds_links` | one-to-many | From link | Links downstream of this link's downstream node |
| `node` | one-to-one | From subcatchment | Node the subcatchment drains to |
| `subcatchments` | one-to-many | From node | Subcatchments draining to this node |
| `joined` | one-to-one | From survey | Associated parent object (e.g., CCTV Survey → Pipe) |
| `spatial` | one-to-one | After SPATIAL | Spatially related object from a spatial search |
| `lateral_pipe` | one-to-one | From node | Lateral pipe (asset networks) |

---

## Table Prefixes (Ruby/API context)

| Prefix | Engine | Example |
|--------|--------|---------|
| `hw_` | InfoWorks tables | `hw_node`, `hw_conduit` |
| `sw_` | SWMM tables | `sw_node`, `sw_conduit` |
| `cams_` | Asset management tables | `cams_pipe`, `cams_manhole` |

**Note:** In SQL queries, table names use display names (e.g., `Node`, `Conduit`, `[All Links]`), not the `hw_`/`sw_` internal prefixes. The prefixes are used in Ruby API scripting.

---

## Data Types

*Quick-lookup summary. See `Syntax_Reference.md` → "Data Types" for full type conversion rules and NULL handling.*

| Type | Description | Example Constants |
|------|-------------|-------------------|
| **Number** | Integer or floating point. No scientific notation. | `123`, `-45.67`, `0.001` |
| **String** | Text enclosed in single or double quotes. | `'MH001'`, `"MH001"` |
| **Boolean** | True/false. Represented by checkboxes in UI. | `true`, `false` |
| **Date** | Date/time enclosed in `#` characters. Format depends on Windows locale. | `#31/1/2008#` (UK), `#1/31/2008#` (US) |
| **NULL** | Absent or unknown value. Numeric fields can be NULL; Boolean fields cannot. | `NULL` |

---

## Operators

*Quick-lookup summary. See `Syntax_Reference.md` → "Arithmetic & Comparison Operators" for precedence rules.*

| Operator | Type | Description |
|----------|------|-------------|
| `+` | Arithmetic / String | Addition or string concatenation |
| `-` | Arithmetic | Subtraction or unary negation |
| `*` | Arithmetic | Multiplication |
| `/` | Arithmetic | Division |
| `^` | Arithmetic | Exponentiation (e.g., `width^2`, `area^0.5`) |
| `%` | Arithmetic | Modulus |
| `=` | Comparison | Equal to (also works with NULL) |
| `<>` | Comparison | Not equal to |
| `>`, `>=`, `<`, `<=` | Comparison | Greater/less than |
| `AND` | Logical | Both conditions true |
| `OR` | Logical | Either condition true (inclusive) |
| `NOT` | Logical | Inverts condition |
| `IS NULL` | Unary | Tests if value is NULL |
| `IS NOT NULL` | Unary | Tests if value is not NULL |
| `LIKE` | String | Pattern matching (`?` = one char, `*` = rest of string) |
| `MATCHES` | String | Regular expression matching (case insensitive, whole string) |

---

## Results Prefixes

| Prefix | Meaning | Requires Aggregate | Available In |
|--------|---------|-------------------|--------------|
| `sim.` | Summary results at current/max timestep | No | InfoWorks products |
| `sim2.` | Summary results for second loaded simulation | No | InfoWorks products |
| `tsr.` | Time series results across all timesteps | Yes | InfoWorks WS, ICM |
| `tsr2.` | Time series results for second simulation | Yes | InfoWorks WS, ICM |

---

## Spatial Search Types

| Type | Description |
|------|-------------|
| `Distance` | Objects within a specified distance of target objects |
| `Contains` | Objects spatially contained within target objects |
| `Cross` | Objects that cross/intersect target objects |
| `Intersects` | Objects with geometric intersection |
| `NONE` | Clear spatial search |

---

## PROMPT Types

| Keyword | Description |
|---------|-------------|
| `PROMPT TITLE` | Set dialog title |
| `PROMPT LINE` | Define an input field |
| `PROMPT DISPLAY` | Show the dialog and wait for user input |
| `PROMPT DISPLAY READONLY` | Show read-only dialog (OK/Cancel only) |
| `LIST` (after PROMPT LINE) | Dropdown selection from a list |
| `STRING` (after PROMPT LINE) | String input type |
| `DATE` (after PROMPT LINE) | Date input type |
| `DP n` (after PROMPT LINE) | Numeric with n decimal places |
| `FILE` (after PROMPT LINE) | File picker |
| `FOLDER` (after PROMPT LINE) | Folder picker |
| `MONTH` (after PROMPT LINE) | Month picker |
| `RANGE start end` (after PROMPT LINE) | Numeric range constraint |

---

## Special Keywords

| Keyword | Context | Description |
|---------|---------|-------------|
| `oid` | Any object | Read-only unique object identifier (multi-part for multi-part IDs) |
| `rank` | SET with ORDER BY | Position in sorted order (tied values get equal rank) |
| `TOP n` | SELECT/DELETE/UPDATE | Limit to first n results |
| `BOTTOM n` | SELECT/DELETE/UPDATE | Limit to last n results |
| `PERCENT` | After TOP/BOTTOM n | Interpret n as a percentage |
| `WITH TIES` | After TOP/BOTTOM | Include all objects tied with the last selected |
| `ASC` / `DESC` | ORDER BY | Sort ascending (default) or descending |
| `DP n` | SELECT expression | Display with n decimal places |
| `AS alias` | SELECT expression | Column header alias. Use `[brackets]` for special characters. |
| `INTO $var` | SELECT | Store result in scalar variable |
| `INTO FILE 'path'` | SELECT | Export results to CSV file |
| `IN BASE SCENARIO` | Various | Override to base scenario (ICM/InfoNet only) |
| `IN SCENARIO 'name'` | Various | Override to named scenario (ICM/InfoNet only) |
| `SCALARS` | Debug | Display scalar variable values |

---

## File Formats

| Extension | Purpose |
|-----------|---------|
| **.icmm** | Standalone database file |
| **.sql** | SQL query script file |
| **.csv** | Comma-separated output from SELECT INTO FILE |
| **.txt** | Variable data from SAVE/LOAD TO/FROM FILE |

---

## Abbreviations

| Abbrev | Meaning |
|--------|---------|
| **TSR** | Time Series Results |
| **RTC** | Real-Time Control |
| **SWMM** | Storm Water Management Model (EPA) |
| **2D** | Two-dimensional overland flow |
| **CCTV** | Closed-Circuit Television (pipe survey) |
| **HD** | Head-Discharge (pump curve) |
| **MHS** | Manhole Survey |

---

**Cross-References:**
- `InfoWorks_ICM_SQL_Function_Reference.md` - Function signatures
- `InfoWorks_ICM_SQL_Pattern_Reference.md` - Code using these concepts
- `InfoWorks_ICM_SQL_Syntax_Reference.md` - Detailed syntax rules
- `InfoWorks_ICM_SQL_Schema_Common.md` - Field name lookups, IW vs SWMM differences
