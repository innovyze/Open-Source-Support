# InfoWorks ICM SQL Schema — Common Fields, Results, and Workflow

**Last Updated:** March 25, 2026

**Load Priority:** LOOKUP — Load alongside a network-type schema file for complete field coverage
**Load Condition:** ALWAYS load with `Schema_InfoWorks.md` or `Schema_SWMM.md` for field lookups

**Related Files:**
- `InfoWorks_ICM_SQL_Schema_InfoWorks.md` — InfoWorks network object manifests and field tables
- `InfoWorks_ICM_SQL_Schema_SWMM.md` — SWMM network object manifests and field tables
- `InfoWorks_ICM_SQL_Lessons_Learned.md` — Read FIRST — Critical anti-patterns

## Purpose

This file consolidates schema content that applies to **both InfoWorks and SWMM networks** or that supports retrieval across general topics:

- **Common data fields** present on all objects (`user_text_*`, `user_number_*`, etc.)
- **Simulation results fields** (`sim.*`, `tsr.*`) — identical prefix/suffix across network types
- **Relationship-style navigation field paths** (`us_node.*`, `ds_node.*`, `spatial.*`, etc.)
- **InfoAsset and high-risk nested/blob structures** shared across contexts
- **InfoWorks vs SWMM key differences** — quick reference to prevent the most common field-name errors
- **Autodesk Help lookup workflow** — fallback when a field is not indexed here
- **Authoring and coverage governance** for maintaining the schema suite

---

## Common Data Fields

Source: Autodesk Help `Common Data Fields`. These fields exist on **all** network objects.

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| User Number 1–10 | `user_number_1` to `user_number_10` | Double | Additional numeric fields |
| User Text 1–10 | `user_text_1` to `user_text_10` | Text | Additional string fields |
| Hyperlinks | `hyperlinks` | Array | External files or URLs attached to an object. SQL navigation syntax: `hyperlinks.field` |
| Notes | `notes` | Memo | Freeform notes |

**Common property-sheet sections with SQL significance:**
- `Results` section appears when simulation results are open
- `Regulator` section appears for RTC-capable controls
- `Validation` section appears when validation is enabled

---


## InfoWorks vs SWMM — Key Field Differences

This is the **primary source of hallucination errors**. Always verify network type before providing field names.

| Concept | InfoWorks Field | SWMM Field | Notes |
|---------|----------------|------------|-------|
| Pipe width/diameter | `conduit_width` | `conduit_width` | Same in both networks |
| Pipe height | `conduit_height` | `conduit_height` | Same in both networks |
| Pipe length | `conduit_length` | `length` | Key difference |
| Node depth/invert | `chamber_floor_level` | `maximum_depth` | |
| Catchment area | `contributing_area` | `area` | |
| Imperviousness | `runoff_index` | `percent_impervious` | CORRECTED: `percent_imperv` is wrong |
| Node table | `hw_node` | `sw_node` | |
| Conduit table | `hw_conduit` | `sw_conduit` | |
| Subcatchment table | `hw_subcatchment` | `sw_subcatchment` |
| Conduit/Link identifier | `link_suffix` | `id` | Key difference — most common identifier field |

**Rules:**
- `hw_*` tables = InfoWorks network
- `sw_*` tables = SWMM network
- A Help page without `(SWMM)` in the title refers to InfoWorks

---

## Autodesk Help Lookup Workflow

Use this workflow when a field is **not indexed in the network-type schema files**.

### Step 1: Determine Object and Network Type
- Object type: Conduit, Node, Subcatchment, Pump, etc.
- Network type: InfoWorks (default) or SWMM (if specified)

### Step 2: Search Autodesk Help
Search pattern: `{Object Type} Data Fields` at https://help.autodesk.com/view/IWICMS/2026/ENU/

Examples:
- `Conduit Data Fields (InfoWorks)` → InfoWorks Conduit
- `Conduit Data Fields (SWMM)` → SWMM Conduit
- `Node Data Fields (InfoWorks)` → InfoWorks Node

### Step 3: Use the "Database field" Column
Each Help page has a table with:
1. **Field Name** — UI display name
2. **Database field** — ← use this in SQL
3. **Data Type** — TEXT, REAL, INTEGER, BLOB, etc.
4. **Description** — explanation

Always use the **Database field** column value, not the Field Name.

**Example:** For "Width" on the InfoWorks Conduit page, the Database field is `conduit_width`.

### Critical Reminders
- Use underscores: `conduit_width` not `conduitwidth`
- Verify network type: the same UI label often maps to different Database fields
- Blob tables have their own Database field columns: search for the blob table section within the parent object's page

---

## Simulation Results Schema

Result fields are accessed through `sim.*` (summary results) and `tsr.*` (time-series results) prefixes. These prefixes work identically across InfoWorks and SWMM networks. Object-specific result field names differ between network types — complete listings are in the network-type schema files.

### Summary Results (`sim.*`)

The `sim.*` prefix syntax is common to both network types. However, the suffix names are **network-type specific** — InfoWorks and SWMM use different field codes for the same hydraulic concepts.

**Do not assume a `sim.*` suffix from one network type will work in the other.** Object- and network-specific `sim.*` field names are listed in the network-type schema files (`Schema_InfoWorks.md` and `Schema_SWMM.md`) alongside `tsr.*` fields.

### Time Series Metadata (`tsr.*`)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Timestep Number | `tsr.timestep_no` | result-meta | 1 = first timestep |
| Timestep Start | `tsr.timestep_start` | result-meta | Date for absolute time, number for relative |
| Number of Timesteps | `tsr.timesteps` | result-meta | Total simulation timesteps |
| Timestep Duration | `tsr.timestep_duration` | result-meta | Minutes |
| Simulation Start | `tsr.sim_start` | result-meta | Date/number |
| Simulation End | `tsr.sim_end` | result-meta | Date/number |

### Object-Specific Result Fields

Object-specific `tsr.*` result field names are listed by network type:

- **InfoWorks networks** — see `InfoWorks_ICM_SQL_Schema_InfoWorks.md`, section `## Simulation Results`
- **SWMM networks** — see `InfoWorks_ICM_SQL_Schema_SWMM.md`, section `## Simulation Results`

### Results Retrieval Notes

- `sim.*` and `tsr.*` are exact prefixes — do not paraphrase them
- `tsr.*` fields require aggregate functions when used in SQL (e.g., `MAX(tsr.depth)` for SWMM, `MAX(tsr.depnod)` for InfoWorks)
- **SQL is case-insensitive** for `tsr.*` attribute names — `tsr.depth` and `tsr.DEPTH` are equivalent
- `tsr.floodvolume` = InfoWorks node flood volume; `tsr.total_flood_volume` = SWMM equivalent
### Second Simulation Prefixes

| Prefix | Meaning | Notes |
|--------|---------|-------|
| `sim2.` | Summary results for second loaded simulation | Same suffix as `sim.` |
| `tsr2.` | Time series results for second loaded simulation | Same suffix as `tsr.` |

---

## Relationship-Style SQL Field Paths

These are valid SQL field paths created by InfoWorks navigation, not flat database columns. Retrieval often fails on these because the prefix is structural.

### One-to-One Navigation

| Meaning | Field Path | Type | Notes |
|---------|------------|------|-------|
| Upstream Node Ground Level | `us_node.ground_level` | relationship | Link to upstream node |
| Upstream Node ID | `us_node.node_id` | relationship | Link to upstream node |
| Upstream Node OID | `us_node.oid` | relationship | Link to upstream node |
| Upstream Node User Text N | `us_node.user_text_1` … `user_text_10` | relationship | Any common field works after prefix |
| Downstream Node Ground Level | `ds_node.ground_level` | relationship | Link to downstream node |
| Downstream Node ID | `ds_node.node_id` | relationship | Link to downstream node |
| Downstream Node OID | `ds_node.oid` | relationship | Link to downstream node |
| Downstream Node User Text/Number N | `ds_node.user_text_1` … `user_number_10` | relationship | Any common field works after prefix |
| Downstream Node X | `ds_node.X` | relationship | Case preserved from repository |
| Downstream Node y | `ds_node.y` | relationship | Case preserved from repository |
| Subcatchment Node Ground Level | `node.ground_level` | relationship | Subcatchment to node |
| Subcatchment Node ID | `node.node_id` | relationship | Subcatchment to node |
| Subcatchment Node User Number/Text N | `node.user_number_1` … `user_text_10` | relationship | Any common field works after prefix |

### One-to-Many and Full-Trace Navigation

| Meaning | Field Path | Type | Notes |
|---------|------------|------|-------|
| Upstream Links Width | `us_links.width` | relationship | One-to-many link path |
| Downstream Links Width | `ds_links.width` | relationship | One-to-many link path |
| Downstream Links Height | `ds_links.height` | relationship | One-to-many link path |
| Downstream Links Shape | `ds_links.shape` | relationship | One-to-many link path |
| Downstream Links Crest | `ds_links.crest` | relationship | One-to-many link path |
| Downstream Links Invert | `ds_links.invert` | relationship | One-to-many link path |
| Downstream Links Upstream Invert | `ds_links.us_invert` | relationship | One-to-many link path |
| Downstream Links User Number/Text N | `ds_links.user_number_1` … `user_text_10` | relationship | Any common field works after prefix |
| All Upstream Links Length | `all_us_links.conduit_length` | relationship | Full network trace path; InfoWorks only — SWMM uses `all_us_links.length` |
| All Upstream Links Upstream Node ID | `all_us_links.us_node_id` | relationship | Full network trace path |

### Spatial Relationship Paths

| Meaning | Field Path | Type | Notes |
|---------|------------|------|-------|
| Spatial User Number/Text N | `spatial.user_number_1` … `user_text_10` | relationship | Any common field works after prefix |
| Spatial Node ID | `spatial.node_id` | relationship | Spatially related node |
| Spatial Identifier | `spatial.ident` | relationship | Extracted from GIS point example |
| Spatial Value | `spatial.value` | relationship | Extracted from GIS point example |
| Spatial Upstream Node ID | `spatial.us_node_id` | relationship | Spatial comparison path |
| Spatial Downstream Node ID | `spatial.ds_node_id` | relationship | Spatial comparison path |
| Generic Spatial Field | `spatial.field` | relationship | Placeholder path used in docs |

### InfoAsset Relationship Paths

| Meaning | Field Path | Type | Notes |
|---------|------------|------|-------|
| CCTV Surveys Structural Grade | `cctv_surveys.structural_grade` | relationship | Pipe to surveys |
| CCTV Surveys Survey Date | `cctv_surveys.when_surveyed` | relationship | Pipe to surveys |

---

## InfoAsset Manager and Nested Structures

### Pipe (`ia_pipe` / asset context)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Asset ID | `asset_id` | scalar | Common asset identifier |
| Pipe Material | `pipe_material` | scalar | Asset pipe material |

### CCTV Survey

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Structural Grade | `structural_grade` | scalar | Survey grade |
| Survey Date | `when_surveyed` | scalar | Used for latest survey selection |
| Detail Code | `details.code` | blob | Blob/nested detail field |
| Detail Distance | `details.distance` | blob | Blob/nested detail field |
| Detail Remarks | `details.remarks` | blob | Blob/nested detail field |
| Detail Service Score | `details.service_score` | blob | Blob/nested detail field |

### CCTV Survey Resource Details

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Resource ID | `resource_details.resource_id` | blob | Nested resource blob field |
| Estimated Hours | `resource_details.estimated_hours` | blob | Nested resource blob field |

### Manhole Survey

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Pipe In Diameter | `pipes_in.diameter` | blob | Nested manhole survey field |
| Pipe In Width | `pipes_in.width` | blob | Nested manhole survey field |
| Pipe Out Width | `pipes_out.width` | blob | Nested manhole survey field |

### Generic Flags Array

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Flag Value | `flags.value` | pseudo-array | Flags behave like an array in SQL |
| Flag Name | `flags.name` | pseudo-array | Flags behave like an array in SQL |

### Head Discharge Table (`hw_head_discharge`)

**High-risk blob object** — `HDP_table.*` fields are common in INSERT and aggregate queries.

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Head | `HDP_table.head` | blob | Head-discharge curve field |
| Discharge | `HDP_table.discharge` | blob | Head-discharge curve field |

---

## Authoring and Expansion Rules

### Authoring Rules

- Keep one object per section.
- Repeat exact field strings verbatim.
- Prefer short rows over prose.
- Include both InfoWorks and SWMM where names differ; put InfoWorks in `Schema_InfoWorks.md` and SWMM in `Schema_SWMM.md`.
- Mark nested fields explicitly in `Type` as `blob` or `nested`.
- If a field is user-confirmed but not yet documented from Autodesk Help, label it in `Notes`.
- If uncertain, omit it rather than guessing.

### Expansion Priority

1. Promote remaining InfoWorks and SWMM objects to Autodesk-transcribed coverage where official field tables can be harvested cleanly
2. Reconcile any remaining alias mismatches between Autodesk labels and repo-local internal table names
3. River Reach full field set from Autodesk Help, plus additional nested/blob fields
4. InfoAsset Manager survey and blob-table fields
