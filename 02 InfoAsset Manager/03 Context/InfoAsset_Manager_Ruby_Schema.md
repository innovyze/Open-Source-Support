# InfoAsset Manager Ruby Schema Reference

**Source:** Autodesk InfoAsset Manager 2027 official documentation (Network Data Fields, Survey Grid, Repair Grid) and Exchange Appendix ICM.  
**Purpose:** Provide LLMs with accurate table names, object categories, and navigation relationships to use in `row_objects()`, `navigate()`, CSV import/export, and ODEC/ODIC scripts.

---

## Overview of Network Types and Prefixes

| Network Type | Prefix | Licence Requirement |
|---|---|---|
| Collection Network | `cams_` | Standard |
| Distribution Network | `wams_` | Standard |
| Asset Network (user-defined) | `ams_` | InfoAsset Manager Suite option required |
| User-defined objects | `{prefix}__{objectname}` | Suite option required (double underscore) |

**IAM Note:** In most repositories, scripts operate on Collection Networks (`cams_` prefix). Distribution Network scripts use `wams_` prefix. The Asset Network (`ams_`) requires the Suite licence.

---

## Collection Network Tables (`cams_`)

### Asset Grid Objects

| UI Name | Database Table | Object Category |
|---|---|---|
| Node (manhole) | `cams_manhole` | `_nodes` |
| Connection node | `cams_connection_node` | `_nodes` |
| Outlet | `cams_outlet` | `_nodes` |
| Storage area | `cams_storage` | `_nodes` (also area type) |
| Pipe | `cams_pipe` | `_links` |
| Connection pipe | `cams_connection_pipe` | `_links` |
| Channel | `cams_channel` | `_other` (ancillary) |
| Flume | `cams_flume` | `_other` (ancillary) |
| Head discharge | `cams_head_discharge` | `_other` (ancillary) |
| Orifice | `cams_orifice` | `_other` (ancillary) |
| Pump | `cams_pump` | `_other` (ancillary) |
| Screen | `cams_screen` | `_other` (ancillary) |
| Siphon | `cams_siphon` | `_other` (ancillary) |
| Sluice | `cams_sluice` | `_other` (ancillary) |
| User ancillary | `cams_ancillary` | `_other` (ancillary) |
| Valve | `cams_valve` | `_other` (ancillary) |
| Vortex | `cams_vortex` | `_other` (ancillary) |
| Weir | `cams_weir` | `_other` (ancillary) |
| Data logger | `cams_data_logger` | `_other` (asset point) |
| Generator | `cams_generator` | `_other` (asset point) |
| General asset | `cams_general_asset` | `_other` (asset point) |
| Defence area | `cams_defence_area` | `_other` |
| Defence structure | `cams_defence_structure` | `_other` (asset line) |
| Pump station | `cams_pump_station` | `_other` (asset point/area) |
| Treatment works | `cams_wtw` | `_other` (asset point/area) |

### Survey Tables (Collection)

| UI Name | Database Table | Notes |
|---|---|---|
| CCTV survey | `cams_cctv_survey` | Primary pipe inspection; navigate: `cctv_surveys`. BLOB field: `details` (see sub-fields below) |
| Manhole survey | `cams_manhole_survey` | Node inspection; navigate: `manhole_surveys` |
| GPS survey | `cams_gps_survey` | GPS position survey; navigate: `gps_surveys` |
| Cross section survey | `cams_cross_section_survey` | — |
| Monitoring survey | `cams_mon_survey` | navigate: `monitoring_surveys` |
| Smoke test | `cams_smoke_test` | navigate: `smoke_tests` |
| Smoke defect observation | `cams_smoke_defect` | navigate: `smoke_defects` |
| Dye test | `cams_dye_test` | navigate: `dye_tests` |
| Drain test | `cams_drain_test` | navigate: `drain_tests` |
| Flood defence survey | `cams_flood_defence_survey` | — |
| FOG inspection | `cams_fog_inspection` | Fat, Oil & Grease |
| Acoustic survey | `cams_acoustic_survey` | — |
| Pump station survey | `cams_pump_station_survey` | No dedicated navigate type — use `row_objects('cams_pump_station_survey')` |
| General survey | `cams_general_survey` | Generic survey |
| General survey line | `cams_general_survey_line` | Line-type generic survey |

### CCTV Survey `details` BLOB Sub-fields

Access via `ro.details` on a `cams_cctv_survey` row object. Each element is a defect/observation record.

| Sub-field | Type | Notes |
|-----------|------|-------|
| `code` | String | Defect/observation code (e.g., MSCC/PACP codes) |
| `remarks` | String | Observation remarks text |
| `distance` | Float | Distance along pipe (m) |
| `continuous_defect_reference` | String | Reference for continuous defects |
| `joint` | Boolean | Joint indicator |
| `photo_ref` | String | Photo reference |
| `video_ref` | String | Video reference |
| `clock_ref` | String | Clock position reference |

### Repair / Maintenance Tables (Collection)

| UI Name | Database Table | navigate type |
|---|---|---|
| Pipe repair | `cams_pipe_repair` | `pipe_repairs` |
| Manhole repair | `cams_manhole_repair` | `manhole_repairs` |
| Pipe clean | `cams_pipe_clean` | `pipe_cleans` |
| General maintenance | `cams_general_maintenance` | `maintenance_records` |
| Pump station electrical maintenance | `cams_pump_station_em` | `maintenance_records` |
| Pump station mechanical maintenance | `cams_pump_station_mm` | `maintenance_records` |

### Incident Tables (Collection)

| UI Name | Database Table |
|---|---|
| Blockage incident | `cams_incident_blockage` |
| Collapse incident | `cams_incident_collapse` |
| Customer complaint | `cams_incident_complaint` |
| Flooding incident | `cams_incident_flooding` |
| General incident | `cams_incident_general` |
| Odor incident | `cams_incident_odor` |
| Pollution incident | `cams_incident_pollution` |

All incident tables: navigate via `incidents`.

### Other Collection Tables

| UI Name | Database Table | Notes |
|---|---|---|
| Approval level | `cams_approval_level` | — |
| Material | `cams_material` | — |
| Node name group | `cams_name_group_node` | Asset Name Group |
| Pipe name group | `cams_name_group_pipe` | Asset Name Group |
| Connection pipe name group | `cams_name_group_connection_pipe` | Asset Name Group |
| Order | `cams_order` | Work order |
| Property | `cams_property` | navigate: `properties` / `property` |
| Resource | `cams_resource` | — |
| Zone | `cams_zone` | — |
| General line | `cams_general_line` | — |

---

## Distribution Network Tables (`wams_`)

### Asset Grid Objects

| UI Name | Database Table | Notes |
|---|---|---|
| Pipe | `wams_pipe` | Primary link type |
| Manhole | `wams_manhole` | Node type |
| Hydrant | `wams_hydrant` | Fire hydrant |
| Meter | `wams_meter` | Water meter; navigate: `meters` |
| Valve | `wams_valve` | — |
| Fitting | `wams_fitting` | — |
| Borehole | `wams_borehole` | — |
| Data logger | `wams_data_logger` | — |
| Generator | `wams_generator` | — |
| General asset | `wams_general_asset` | — |
| Property | `wams_property` | navigate: `properties` / `property` |
| Pump | `wams_pump` | — |
| Pump station | `wams_pump_station` | — |
| Surface source | `wams_surface_source` | — |
| Tank | `wams_tank` | — |
| Treatment works | `wams_wtw` | — |
| Zone | `wams_zone` | — |
| General line | `wams_general_line` | — |

### Survey Tables (Distribution)

| UI Name | Database Table | navigate type |
|---|---|---|
| GPS survey | `wams_gps_survey` | `gps_surveys` |
| General survey | `wams_general_survey` | — |
| General survey line | `wams_general_survey_line` | — |
| Manhole survey | `wams_manhole_survey` | `manhole_surveys` |
| Monitoring survey | `wams_mon_survey` | `monitoring_surveys` |
| Hydrant test | `wams_hydrant_test` | `hydrant_tests` |
| Leak detection | `wams_leak_detection` | — |
| Meter test | `wams_meter_test` | `meter_tests` |
| Pipe sample | `wams_pipe_sample` | `pipe_samples` |
| Pump station survey | `wams_pump_station_survey` | No dedicated navigate type — use `row_objects('wams_pump_station_survey')` |
| Water quality survey | `wams_water_quality_survey` | — |

### Repair / Maintenance Tables (Distribution)

| UI Name | Database Table | navigate type |
|---|---|---|
| Pipe repair | `wams_pipe_repair` | `pipe_repairs` |
| Manhole repair | `wams_manhole_repair` | `manhole_repairs` |
| General maintenance | `wams_general_maintenance` | `maintenance_records` |
| Hydrant maintenance | `wams_hydrant_maintenance` | `maintenance_records` |
| Meter maintenance | `wams_meter_maintenance` | `maintenance_records` |
| Valve maintenance | `wams_valve_maintenance` | `maintenance_records` |
| Valve shut off | `wams_valve_shut_off` | `maintenance_records` |
| Pump station electrical maintenance | `wams_pump_station_em` | `maintenance_records` |
| Pump station mechanical maintenance | `wams_pump_station_mm` | `maintenance_records` |

### Incident Tables (Distribution)

| UI Name | Database Table |
|---|---|
| Burst incident | `wams_incident_burst` |
| Customer complaint | `wams_incident_complaint` |
| General incident | `wams_incident_general` |
| Water quality incident | `wams_incident_wq` |

All incident tables: navigate via `incidents`.

### Other Distribution Tables

| UI Name | Database Table |
|---|---|
| Approval level | `wams_approval_level` |
| Material | `wams_material` |
| Node name group | `wams_name_group_node` |
| Pipe name group | `wams_name_group_pipe` |
| Order | `wams_order` |
| Resource | `wams_resource` |

---

## User-Defined Objects (`ams__*` / `cams__*` / `wams__*`)

User-defined objects use a **double underscore** separator:

```
{networkprefix}__{objectname}
```

Examples:
- `ams__MyAsset` — user-defined asset in an Asset Network  
- `cams__MyCollection` — user-defined object in a Collection Network  
- `wams__MyDistribution` — user-defined object in a Distribution Network  

The `objectname` is the value from the **Database Name** field in the User Defined Objects Dialog.

---

## Object Categories for `row_objects()`

The `row_objects(type)` method on `WSOpenNetwork` accepts either a table name or a category:

| Category String | Matches |
|---|---|
| `'_nodes'` | All node-type objects (manholes, connection nodes, outlets, etc.) |
| `'_links'` | All link-type objects (pipes, connection pipes) |
| `'_other'` | All non-node, non-link objects (ancillaries, asset points, etc.) |
| `'cams_pipe'` etc. | Exact table name — returns only that object type |
| `nil` | Not valid — always specify a table name or category |

```ruby
# All pipes in network
net.row_objects('cams_pipe').each { |ro| ... }

# All node objects
net.row_objects('_nodes').each { |ro| ... }

# All CCTV surveys
net.row_objects('cams_cctv_survey').each { |ro| ... }
```

---

## Navigate Types

`WSRowObject#navigate(type)` and `#navigate1(type)` traverses object relationships.

| Navigate Type | Returns | Has Results | Typical Source → Target |
|---|---|---|---|
| `'us_node'` | Single | Yes | Pipe → upstream node |
| `'ds_node'` | Single | Yes | Pipe → downstream node |
| `'us_links'` | Array | Yes | Node → upstream pipes |
| `'ds_links'` | Array | Yes | Node → downstream pipes |
| `'us_flow_links'` | Array | Yes | Node → upstream flow links |
| `'ds_flow_links'` | Array | Yes | Node → downstream flow links |
| `'node'` | Single | Yes | Survey/subcatchment → parent node |
| `'pipe'` | Single | Yes | Survey → parent pipe |
| `'joined'` | Single | No | Cross-reference to associated object |
| `'joined_pipes'` | Array | No | Node → all joined pipes |
| `'cctv_surveys'` | Array | No | Pipe → `cams_cctv_survey` records |
| `'manhole_surveys'` | Array | No | Node → `cams_manhole_survey` records |
| `'manhole_repairs'` | Array | No | Node → repair records |
| `'pipe_repairs'` | Array | No | Pipe → repair records |
| `'pipe_cleans'` | Array | No | Pipe → clean records |
| `'gps_surveys'` | Array | No | Object → GPS surveys |
| `'monitoring_surveys'` | Array | No | Object → monitoring surveys |
| `'smoke_tests'` | Array | No | Object → smoke tests |
| `'smoke_test'` | Single | No | Object → single smoke test (one-to-one) |
| `'smoke_defects'` | Array | No | Object → smoke defect observations |
| `'dye_tests'` | Array | No | Object → dye tests |
| `'drain_tests'` | Array | No | Object → drain tests |
| `'pipe_samples'` | Array | No | Pipe → pipe samples |
| `'meter_tests'` | Array | No | Meter → meter tests |
| `'hydrant_tests'` | Array | No | Hydrant → hydrant tests |
| `'incidents'` | Array | No | Object → incident records |
| `'maintenance_records'` | Array | No | Object → maintenance/repair records |
| `'meters'` | Array | No | Pipe → meters |
| `'properties'` | Array | No | Object → property records |
| `'property'` | Single | No | Object → single property record |
| `'lateral_pipe'` | Single | No | Connection node → lateral pipe |
| `'data_logger'` | Single | No | Object → data logger |
| `'alt_demand'` | Single | No | Node → alternative demand object |
| `'sanitary_pipe'` | Single | No | Connection pipe → sanitary pipe |
| `'sanitary_manhole'` | Single | No | Connection node → sanitary manhole |
| `'storm_pipe'` | Single | No | Connection pipe → storm pipe |
| `'storm_manhole'` | Single | No | Connection node → storm manhole |
| `'custom'` | Single | No | Custom user-defined relationship |

**Usage:**
```ruby
# One-to-many: use navigate()
pipe.navigate('cctv_surveys').each do |survey|
  puts survey['id']
end

# One-to-one: use navigate1()
node = pipe.navigate1('us_node')
puts node['node_id'] if node
```

---

## MSCC/PACP Survey Export Table Names

For `net.mscc_export_cctv_surveys` and `net.mscc_import_cctv_surveys`, the survey table involved is always `cams_cctv_survey`. For MACP/PACP exports:

- `net.macp_export` / `net.macp_import` — MACP manhole surveys
- `net.pacp_export` / `net.pacp_import` — PACP pipe surveys

These operate on `cams_manhole_survey` and `cams_cctv_survey` respectively.

---

## CSV Import/Export Table Names

When using `net.csv_export` or `net.csv_import` (`WSBaseNetworkObject`), specify the database table name exactly:

```ruby
net.csv_export({'file' => 'pipes.csv', 'table' => 'cams_pipe'})
net.csv_export({'file' => 'surveys.csv', 'table' => 'cams_cctv_survey'})
```

The table name must be the database table name (e.g., `cams_pipe`), not the UI name ("Pipe").

---

## ODEC Export `table` Parameter

For `net.odec_export_ex` and `net.odic_import_ex`, the `table` parameter uses the **UI display name with spaces removed**:

| UI Name (spaces) | table parameter |
|---|---|
| CCTV Survey | `CCTVSurvey` |
| Manhole Survey | `ManholeSurvey` |
| GPS Survey | `GPSSurvey` |
| Pipe | `Pipe` |
| Node | `Node` |
| Smoke Test | `SmokeTest` |
| Manhole Repair | `ManholeRepair` |
| Pipe Repair | `PipeRepair` |
| Pipe Clean | `PipeClean` |

**Note:** This is different from the database table name (`cams_cctv_survey` vs `CCTVSurvey`). Use UI-name-no-spaces for ODEC/ODIC.

---

## Common Field Names

These fields are present across most object types:

| Field | Database Column | Type | Notes |
|---|---|---|---|
| ID | `id` | String(40) | Primary key, unique per table |
| System Type | `system_type` | String | Collection/Distribution system type |
| Notes | `notes` | String | Free text notes |
| User text 1–10 | `user_text_n` | String | User-defined fields |
| User number 1–5 | `user_number_n` | Double | User-defined numeric fields |

**Key collection pipe fields:**

| Field | Database Column | Type |
|---|---|---|
| US node ID | `us_node_id` | String(40) |
| DS node ID | `ds_node_id` | String(40) |
| Link suffix | `link_suffix` | String(1) |
| Pipe ID | `id` | String(40) |
| Internal diameter | `diameter` | Double |
| Length | `conduit_length` | Double |

**Key collection node (manhole) fields:**

| Field | Database Column | Type |
|---|---|---|
| Node ID | `node_id` | String(40) |
| X coordinate | `x` | Double |
| Y coordinate | `y` | Double |
| Ground level | `ground_level` | Double |
| Cover level | `cover_level` | Double |
| Invert level | `invert_level` | Double |

---

## Appendix: Table Name Lookup Quick Reference

### Collection Network — Most Used
```
cams_manhole        (nodes / manholes)
cams_pipe           (pipes)
cams_cctv_survey    (CCTV survey records)
cams_manhole_survey (manhole survey records)
cams_pipe_repair    (pipe repair records)
cams_manhole_repair (manhole repair records)
cams_gps_survey     (GPS survey records)
cams_smoke_test     (smoke test surveys)
cams_general_survey (generic surveys)
cams_connection_node
cams_connection_pipe
```

### Distribution Network — Most Used
```
wams_pipe           (distribution pipes)
wams_manhole        (distribution manholes/chambers)
wams_hydrant        (fire hydrants)
wams_meter          (water meters)
wams_valve          (valves)
wams_pipe_repair    (pipe repairs)
wams_manhole_repair (manhole repairs)
wams_gps_survey     (GPS surveys)
wams_hydrant_test   (hydrant test records)
wams_meter_test     (meter test records)
```

---

## Database Object Types

These type strings are used with `model_object_from_type_and_id`, `model_object_collection`, and `find_root_model_object`.

| Object Type | Evidence | Notes |
|-------------|----------|-------|
| `Collection Network` | `0029 List Database Objects Contents`, `0001 ODEC Export`, `0002 ODIC Import`, `0004 GIS Export`, `0041 Export to GeoJSON` | Most common network object in repository examples |
| `Distribution Network` | `0029 List Database Objects Contents` | Listed in database inventory examples |
| `Asset Network` | `0029 List Database Objects Contents` | Listed in database inventory examples |
| `Theme` | `0029 List Database Objects Contents` | Listed in database inventory examples |
| `Stored Query` | `0029 List Database Objects Contents` | Listed in database inventory examples |
| `Selection List` | `0029 List Database Objects Contents`, `0041 Export to GeoJSON` | Used as a database object with numeric IDs |

---

## Report Type Pairings

Use these `[table, sub_type]` pairs with `net.generate_report(table, sub_type, title, output_path)`:

| Report Label | Ruby Pair |
|--------------|-----------|
| Manhole Report | `['cams_manhole', nil]` |
| Manhole Survey Report | `['cams_manhole_survey', nil]` |
| CCTV Survey Report | `['cams_cctv_survey', nil]` |
| CCTV Survey Report (MSCC) | `['cams_cctv_survey', 'MSCC']` |
| CCTV Survey Report (PACP) | `['cams_cctv_survey', 'PACP']` |
| Pipe Clean Report | `['cams_pipe_clean', nil]` |
| Pipe Repair Report | `['cams_pipe_repair', nil]` |
| Manhole Repair Report | `['cams_manhole_repair', nil]` |
| FOG Inspection Report | `['cams_fog_inspection', nil]` |

---

## Repository Evidence

Common table names and their observed usage in repository example folders:

| Table Name | Evidence Folders |
|------------|-----------------|
| `cams_pipe` | `0041 Export to GeoJSON`, `0011 Find Duplicate IDs`, `0013 Update from external CSV` |
| `cams_manhole` | `0041 Export to GeoJSON`, `0011 Find Duplicate IDs`, `0020 Generate Individual Reports` |
| `cams_cctv_survey` | `0006 Snapshot`, `0020 Generate Individual Reports`, `0012 Locate Missing Attachments` |
| `cams_manhole_survey` | `0006 Snapshot`, `0020 Generate Individual Reports`, `0012 Locate Missing Attachments` |
| `cams_pipe_clean` | `0020 Generate Individual Reports` |
| `cams_pipe_repair` | `0020 Generate Individual Reports` |
| `cams_manhole_repair` | `0020 Generate Individual Reports` |
| `cams_fog_inspection` | `0020 Generate Individual Reports` |
| `cams_outlet` | `0011 Find Duplicate IDs` |
| `cams_connection_pipe` | `0011 Find Duplicate IDs` |

---

## Do Not Invent

- Do not fabricate object types or table names from other Autodesk water products when working in IAM.
- If a required table name is not listed in this file, verify it with official Autodesk Help (`INFOAMAN` product code, release 2027) or a nearby IAM example.
- IAM Collection Networks use `cams_*` table names. Do not substitute generic names from other products.
