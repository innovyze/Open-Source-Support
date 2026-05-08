# InfoWorks ICM SQL Schema — SWMM Networks

**Last Updated:** March 25, 2026

**Load Priority:** LOOKUP — Load for any SWMM network SQL query requiring field names
**Load Condition:** CONDITIONAL — When user asks about SWMM fields, schemas, or object inventory

**Related Files:**
- `InfoWorks_ICM_SQL_Schema_Common.md` — Common fields (`user_text_*`, `user_number_*`), results schema (`sim.*`, `tsr.*`), relationship paths, Autodesk Help workflow
- `InfoWorks_ICM_SQL_Schema_InfoWorks.md` — InfoWorks network field names (separate file; do NOT mix with SWMM fields)
- `InfoWorks_ICM_SQL_Lessons_Learned.md` — Read FIRST — Critical field name gotchas

## Purpose

This file is the **authoritative field-name and object-manifest reference for SWMM networks**.

Use it when:
- A user is working with a SWMM network (indicated by `(SWMM)` in the context or query)
- The query involves field names from `sw_*` tables
- An object manifest or coverage check is needed for SWMM objects

**InfoWorks fields are in `InfoWorks_ICM_SQL_Schema_InfoWorks.md`. Do not mix field sets.**

Key distinction: SWMM uses `length` for conduit length while InfoWorks uses `conduit_length`. Conduit dimensions (`conduit_width`/`conduit_height`) are the same in both networks.

## Retrieval Rules for LLMs

1. Confirm the network type is **SWMM** before using this file.
2. Match the **object type** (Node, Conduit, Subcatchment, etc.).
3. Use exact strings from the `Database Field` column.
4. If a user gives a UI label, check the `UI Label` column.
5. If a field is not listed here, check `InfoWorks_ICM_SQL_Schema_Common.md` for common/results fields.
6. Do not invent field names.

## Critical SQL Reminders

InfoWorks ICM SQL is **not standard ANSI SQL**. Even if `Lessons_Learned.md` was not loaded, these rules are mandatory:

- **No CASE WHEN** — use `IIF(condition, true_val, false_val)` or `IF condition; ... ELSEIF ...; ELSE; ... ENDIF;`
- **No JOINs** — use dot-notation navigation (e.g., `us_node.ground_level`, `ds_links.width`)
- **Semicolons required** after every statement, including control flow (`IF;`, `ELSE;`, `ENDIF;`, `WEND;`)
- **LIKE uses `?` and `*`** — not `%` and `_` (e.g., `LIKE 'MH*'` not `LIKE 'MH%'`)

For full anti-pattern coverage, load `InfoWorks_ICM_SQL_Lessons_Learned.md`.

---

## SWMM Network Object Manifest

Source: Autodesk Help `Network Data Fields` index page.

### Nodes Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Node | Node Data Fields (SWMM) | `sw_node` |
| Unit hydrograph group | Unit Hydrograph Group Data Fields (SWMM) | `sw_uh_group` |
| Unit hydrograph | Unit Hydrograph Data Fields (SWMM) | `sw_uh` |
| Storage curve | Storage Curve Data Fields (SWMM) | `sw_curve_storage` |
| Tidal curve | Tidal Curve Data Fields (SWMM) | `sw_curve_tidal` |

### Links Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Conduit | Conduit Data Fields (SWMM) | `sw_conduit` |
| Shape curve | Shape Curve Data Fields (SWMM) | `sw_curve_shape` |
| Orifice | Orifice Data Fields (SWMM) | `sw_orifice` |
| Pump | Pump Data Fields (SWMM) | `sw_pump` |
| Pump curve | Pump Curve Data Fields (SWMM) | `sw_curve_pump` |
| Weir | Weir Data Fields (SWMM) | `sw_weir` |
| Weir curve | Weir Curve Data Fields (SWMM) | `sw_curve_weir` |
| Outlet | Outlet Data Fields (SWMM) | `sw_outlet` |
| Rating curve | Rating Curve Data Fields (SWMM) | `sw_curve_rating` |
| Transect | Transect Data Fields (SWMM) | `sw_transect` |
| Control curve | Control Curve Data Fields (SWMM) | `sw_curve_control` |

### Subcatchments Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Subcatchment | Subcatchment Data Fields (SWMM) | `sw_subcatchment` |
| Land use | Land Use Data Fields (SWMM) | `sw_land_use` |
| Pollutant | Pollutant Data Fields (SWMM) | `sw_pollutant` |
| Snow pack | Snow Pack Data Fields (SWMM) | `sw_snow_pack` |
| LID control | LID Controls Data Fields (SWMM) | `sw_suds_control` |
| Underdrain curve | Underdrain Curve Data Fields (SWMM) | `sw_curve_underdrain` |
| Aquifer | Aquifer Data Fields (SWMM) | `sw_aquifer` |
| Soil | Soil Data Fields (SWMM) | `sw_soil` |

### Polygons Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| 2D zone | 2D Zone Data Fields (SWMM) | `sw_2d_zone` |
| Mesh zone | Mesh Zone Data Fields (SWMM) | `sw_mesh_zone` |
| Mesh level zone | Mesh Level Zone Data Fields (SWMM) | `sw_mesh_level_zone` |
| Porous polygon | Porous Polygon Data Fields (SWMM) | `sw_porous_polygon` |
| Roughness zone | Roughness Zone Data Fields (SWMM) | `sw_roughness_zone` |
| Roughness definition | Roughness Definition Data Fields (SWMM) | `sw_roughness_definition` |
| Polygon | Polygon Data Fields (SWMM) | `sw_polygon` |
| TVD connector | TVD Connector Data Fields (SWMM) | `sw_tvd_connector` |
| Spatial rain zone | Spatial Rain Zone Data Fields (SWMM) | `sw_spatial_rain_zone` |
| Spatial rain source | Spatial Rain Source Data Fields (SWMM) | `sw_spatial_rain_source` |

### Lines Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| General line | General Line Data Fields (SWMM) | `sw_general_line` |
| Porous wall | Porous Wall Data Fields (SWMM) | `sw_porous_wall` |
| 2D boundary | 2D Boundary Line Data Fields (SWMM) | `sw_2d_boundary_line` |
| Head unit flow | Head Unit Flow Data Fields (SWMM) | `sw_head_unit_discharge` |

### Points Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Rain gage | Rain Gage Data Fields (SWMM) | `sw_raingage` |

---

## SWMM Field Tables

All SWMM field tables are indexed here. For results fields (`sim.*`, `tsr.*`) and shared metadata, see `InfoWorks_ICM_SQL_Schema_Common.md`.

Unless stated otherwise for a specific object, every `sw_*` network object in this file also exposes `user_text_1`–`user_text_10`, `user_number_1`–`user_number_10`, `notes`, and `hyperlinks` (see `InfoWorks_ICM_SQL_Schema_Common.md`).

`boundary_array`, link `point_array`, and line `general_line_xy` are intentionally omitted from the field tables below (coordinate-array fields; same omission policy as polygon boundaries).

### Nodes

#### Node (`sw_node`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Node ID | `node_id` | scalar | |
| Node type | `node_type` | scalar | 'Junction', 'Outfall', 'Storage' |
| x | `x` | scalar | |
| y | `y` | scalar | |
| Route to subcatchment | `route_subcatchment` | scalar | |
| Unit hydrograph | `unit_hydrograph_id` | scalar | linked UH group |
| Sewershed contributing area | `unit_hydrograph_area` | scalar | |
| Ground level | `ground_level` | scalar | |
| Invert elevation | `invert_elevation` | scalar | SWMM node invert |
| Max depth | `maximum_depth` | scalar | SWMM node depth |
| Surcharge depth | `surcharge_depth` | scalar | SWMM surcharge depth |
| Initial water depth | `initial_depth` | scalar | SWMM initial condition |
| Ponded area | `ponded_area` | scalar | surface flooding ponded area |
| Flood type | `flood_type` | scalar | 'Lost', '2D' |
| Flooding discharge coefficient | `flooding_discharge_coeff` | scalar | |
| Evaporation factor | `evaporation_factor` | scalar | |
| Initial moisture deficit | `initial_moisture_deficit` | scalar | Green-Ampt infiltration |
| Capillary suction | `suction_head` | scalar | Green-Ampt infiltration |
| Hydraulic conductivity | `conductivity` | scalar | Green-Ampt saturated hydraulic conductivity |
| Outfall type | `outfall_type` | scalar | 'FREE', 'NORMAL', 'FIXED', 'TIDAL', 'TIMESERIES' |
| Tide gate | `flap_gate` | scalar | outfall flap gate |
| Tidal curve | `tidal_curve_id` | scalar | outfall using sw_curve_tidal |
| Fixed stage | `fixed_stage` | scalar | outfall fixed stage level |
| Storage type | `storage_type` | scalar | 'TABULAR', 'FUNCTIONAL' |
| Storage curve | `storage_curve` | scalar | links to sw_curve_storage |
| Coeff of shape function | `functional_coefficient` | scalar | A×H^B + C |
| Constant of shape function | `functional_constant` | scalar |  |
| Exponent of shape function | `functional_exponent` | scalar |  |
| Baseline inflow | `inflow_baseline` | scalar | DWF baseline inflow |
| Inflow scale factor | `inflow_scaling` | scalar | DWF scaling factor |
| Inflow pattern | `inflow_pattern` | scalar | DWF pattern ID |
| Base flow | `base_flow` | scalar |  |
| Base flow pattern 1 | `bf_pattern_1` | scalar |  |
| Base flow pattern 2 | `bf_pattern_2` | scalar |  |
| Base flow pattern 3 | `bf_pattern_3` | scalar |  |
| Base flow pattern 4 | `bf_pattern_4` | scalar |  |
| Treatment | `treatment` | blob | Sub-fields: `treatment.pollutant`, `treatment.result`, `treatment.function` |
| Pollutant inflow | `pollutant_inflows` | blob | Sub-fields: `pollutant_inflows.pollutant`, `pollutant_inflows.baseline`, `pollutant_inflows.baseline_pattern`, `pollutant_inflows.mass_units_factor`, `pollutant_inflows.scaling` |
| Additional DWF | `additional_dwf` | blob | Sub-fields: `additional_dwf.baseline`, `additional_dwf.bf_pattern_1`, `additional_dwf.bf_pattern_2`, `additional_dwf.bf_pattern_3`, `additional_dwf.bf_pattern_4` |
| Pollutant DWF | `pollutant_dwf` | blob | Sub-fields: `pollutant_dwf.pollutant`, `pollutant_dwf.baseline`, `pollutant_dwf.bf_pattern_1`, `pollutant_dwf.bf_pattern_2`, `pollutant_dwf.bf_pattern_3`, `pollutant_dwf.bf_pattern_4` |

#### Unit Hydrograph Group (`sw_uh_group`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| UH group ID | `id` | scalar | Group identifier |
| Rain gage | `raingage_id` | scalar | Linked rain gage |
| All months unit hydrograph | `uh_all` | scalar | Group reference for all months |
| January unit hydrograph | `uh_jan` | scalar | Monthly group reference |
| February unit hydrograph | `uh_feb` | scalar | Monthly group reference |
| March unit hydrograph | `uh_mar` | scalar | Monthly group reference |
| April unit hydrograph | `uh_apr` | scalar | Monthly group reference |
| May unit hydrograph | `uh_may` | scalar | Monthly group reference |
| June unit hydrograph | `uh_jun` | scalar | Monthly group reference |
| July unit hydrograph | `uh_jul` | scalar | Monthly group reference |
| August unit hydrograph | `uh_aug` | scalar | Monthly group reference |
| September unit hydrograph | `uh_sep` | scalar | Monthly group reference |
| October unit hydrograph | `uh_oct` | scalar | Monthly group reference |
| November unit hydrograph | `uh_nov` | scalar | Monthly group reference |
| December unit hydrograph | `uh_dec` | scalar | Monthly group reference |

#### Unit Hydrograph (`sw_uh`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| UH group | `group_id` | scalar | Parent group identifier |
| Month | `month` | scalar | Month selector |
| Response ratio R - short term | `R1` | scalar | RTK parameter |
| Time to peak T - short term | `T1` | scalar | RTK parameter |
| Recession limb ratio K - short term | `K1` | scalar | RTK parameter |
| Response ratio R - medium term | `R2` | scalar | RTK parameter |
| Time to peak T - medium term | `T2` | scalar | RTK parameter |
| Recession limb ratio K - medium term | `K2` | scalar | RTK parameter |
| Response ratio R - long term | `R3` | scalar | RTK parameter |
| Time to peak T - long term | `T3` | scalar | RTK parameter |
| Recession limb ratio K - long term | `K3` | scalar | RTK parameter |
| Max initial abstraction depth - short term | `Dmax1` | scalar | RTK parameter |
| Initial abstraction recovery rate - short term | `Drec1` | scalar | RTK parameter |
| Initial abstraction depth - short term | `D01` | scalar | RTK parameter |
| Max initial abstraction depth - medium term | `Dmax2` | scalar | RTK parameter |
| Initial abstraction recovery rate - medium term | `Drec2` | scalar | RTK parameter |
| Initial abstraction depth - medium term | `D02` | scalar | RTK parameter |
| Max initial abstraction depth - long term | `Dmax3` | scalar | RTK parameter |
| Initial abstraction recovery rate - long term | `Drec3` | scalar | RTK parameter |
| Initial abstraction depth - long term | `D03` | scalar | RTK parameter |

#### Storage Curve (`sw_curve_storage`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `id` | scalar | Storage curve identifier |
| Storage array | `data` | blob | Sub-fields: `data.depth`, `data.surface_area` |

#### Tidal Curve (`sw_curve_tidal`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `id` | scalar | Tidal curve identifier |
| Tidal array | `data` | blob | Sub-fields: `data.hour`, `data.elevation` |

### Links

#### Conduit (`sw_conduit`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Link ID | `id` | scalar | SWMM conduit identifier; InfoWorks uses `link_suffix` |
| Start node | `us_node_id` | scalar | |
| End node | `ds_node_id` | scalar | |
| Length | `length` | scalar | SWMM conduit length; InfoWorks uses `conduit_length` |
| Shape | `shape` | scalar | 'Custom', 'Irregular', 'Circular', 'Force_main', 'Filled_Circular', 'Rect_closed', 'Rect_open', 'Trapezoidal', 'Triangular', 'Horiz_ellipse', 'Vert_ellipse', 'Arch', 'Parabolic', 'Power', 'Rect_triangular', 'Rect_round', 'ModBasketHandle', 'Egg', 'Horseshoe', 'Gothic', 'Catenary', 'Semielliptical', 'Baskethandle', 'Semicircular', 'Dummy' |
| Conduit width | `conduit_width` | scalar | Confirmed in SWMM SQL scripts; NOT `geom1` |
| Conduit height | `conduit_height` | scalar | Confirmed in SWMM SQL scripts; NOT `geom2` |
| Number of barrels | `number_of_barrels` | scalar | NOT `barrels` |
| Upstream elevation | `us_invert` | scalar | |
| Downstream elevation | `ds_invert` | scalar | |
| Manning's N | `Mannings_N` | scalar | Note case: capital M and N; confirmed from SWMM SQL scripts |
| Low depth Manning's N | `bottom_mannings_N` | scalar | composite roughness |
| Depth threshold | `roughness_depth_threshold` | scalar |  |
| Roughness D-W | `roughness_DW` | scalar |  |
| Roughness H-W | `roughness_HW` | scalar |  |
| US headloss coefficient | `us_headloss_coeff` | scalar | |
| DS headloss coefficient | `ds_headloss_coeff` | scalar | |
| Average headloss coefficient | `av_headloss_coeff` | scalar |  |
| Initial flow | `initial_flow` | scalar | initial condition |
| Maximum flow | `max_flow` | scalar | flow limit |
| Sediment depth | `sediment_depth` | scalar |  |
| Seepage rate | `seepage_rate` | scalar |  |
| Culvert code | `culvert_code` | scalar |  |
| Flap valve | `flap_gate` | scalar |  |
| Branch ID | `branch_id` | scalar |  |
| Transect | `transect` | scalar | for IRREGULAR shape |
| Top radius | `top_radius` | scalar | for ARCH shapes |
| Left slope | `left_slope` | scalar | for TRAPEZOIDAL shape |
| Right slope | `right_slope` | scalar | for TRAPEZOIDAL shape |
| Triangle height | `triangle_height` | scalar | for TRIANGULAR shape |
| Bottom radius | `bottom_radius` | scalar |  |
| Shape curve | `shape_curve` | scalar | custom shape curve ID |
| Shape exponent | `shape_exponent` | scalar |  |
| Horizontal ellipse size code | `horiz_ellipse_size_code` | scalar | EPA SWMM standard size code |
| Vertical ellipse size code | `vert_ellipse_size_code` | scalar |  |
| Standard size material | `arch_material` | scalar | for ARCH shapes |
| Concrete size code | `arch_concrete_size_code` | scalar | for ARCH shapes |
| Plate 18 size code | `arch_plate_18_size_code` | scalar | for ARCH shapes |
| Plate 31 size code | `arch_plate_31_size_code` | scalar | for ARCH shapes |
| Steel 1/2 inch size code | `arch_steel_half_size_code` | scalar | for ARCH shapes |
| Steel inch size code | `arch_steel_inch_size_code` | scalar | for ARCH shapes |

#### Shape Curve (`sw_curve_shape`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Curve ID | `id` | scalar | Shape curve identifier |
| Geometry | `data` | blob | Sub-fields: `data.normalized_depth`, `data.normalized_width` |

#### Orifice (`sw_orifice`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Link ID | `id` | scalar | SWMM object identifier |
| Start node | `us_node_id` | scalar | Common link identifier |
| End node | `ds_node_id` | scalar | Common link identifier |
| Type | `link_type` | scalar | Orifice type |
| Shape | `shape` | scalar | Orifice shape field |
| Orifice height | `orifice_height` | scalar | Physical geometry field |
| Orifice width | `orifice_width` | scalar | Physical geometry field |
| Invert level | `invert` | scalar | Hydraulic geometry field |
| Discharge coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Flap gate | `flap_gate` | scalar | Control field |
| Time to open | `time_to_open` | scalar | Control field |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Pump (`sw_pump`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Link ID | `id` | scalar | SWMM object identifier |
| Start node | `us_node_id` | scalar | Common link identifier |
| End node | `ds_node_id` | scalar | Common link identifier |
| Ideal pump | `ideal` | scalar | Ideal pump flag |
| Pump curve ID | `pump_curve` | scalar | Linked pump curve |
| Initial status | `initial_status` | scalar | SWMM control/status field |
| Startup depth | `start_up_depth` | scalar | SWMM control depth |
| Shutoff depth | `shut_off_depth` | scalar | SWMM control depth |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Pump Curve (`sw_curve_pump`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Curve ID | `id` | scalar | Pump curve identifier |
| Pump curve type | `type` | scalar | 'PUMP1', 'PUMP2', 'PUMP3', 'PUMP4' |
| Inlet volume increment array | `pump1_data` | blob | PUMP1; sub-fields: `pump1_data.volume_increment`, `pump1_data.outflow` |
| Inlet depth increment array | `pump2_data` | blob | PUMP2; sub-fields: `pump2_data.depth_increment`, `pump2_data.outflow` |
| Head difference array | `pump3_data` | blob | PUMP3; sub-fields: `pump3_data.head_difference`, `pump3_data.outflow` |
| Continuous depth array | `pump4_data` | blob | PUMP4; sub-fields: `pump4_data.continuous_depth`, `pump4_data.outflow` |

#### Weir (`sw_weir`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Link ID | `id` | scalar | SWMM object identifier |
| Start node | `us_node_id` | scalar | Common link identifier |
| End node | `ds_node_id` | scalar | Common link identifier |
| Weir type | `link_type` | scalar | 'Transverse', 'Sideflow', 'V-notch', 'Trapezoidal', 'Roadway' |
| Crest height | `crest` | scalar | Weir crest level |
| Roof height | `weir_height` | scalar | SWMM weir geometry |
| Weir width | `weir_width` | scalar | SWMM weir geometry |
| Left slope | `left_slope` | scalar | SWMM weir geometry |
| Right slope | `right_slope` | scalar | SWMM weir geometry |
| Variable discharge coefficient | `var_dis_coeff` | scalar | SWMM weir option |
| Discharge coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Sideflow discharge coefficient | `sideflow_discharge_coeff` | scalar | Hydraulic parameter |
| Weir curve ID | `weir_curve` | scalar | Link to `sw_curve_weir` |
| Flap gate | `flap_gate` | scalar | SWMM weir option |
| Number of end contractions | `end_contractions` | scalar | SWMM weir option |
| Trapezoidal discharge coefficient | `secondary_discharge_coeff` | scalar | Hydraulic parameter |
| Allows surcharge | `allows_surcharge` | scalar | SWMM weir option |
| Roadway width | `width` | scalar | Additional width field |
| Roadway surface | `surface` | scalar | SWMM surface selector |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Weir Curve (`sw_curve_weir`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Curve ID | `id` | scalar | Weir curve identifier |
| Weir curve type | `type` | scalar | 'Weir', 'Sideflow' |
| Weir array | `data` | blob | Sub-fields: `data.head`, `data.coefficient` |
| Sideflow array | `sideflow_data` | blob | Sub-fields: `sideflow_data.head`, `sideflow_data.coefficient` |

#### Outlet (`sw_outlet`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Link ID | `id` | scalar | SWMM object identifier |
| Start node | `us_node_id` | scalar | Common link identifier |
| End node | `ds_node_id` | scalar | Common link identifier |
| Outlet height | `start_level` | scalar | Outlet level field |
| Flap gate | `flap_gate` | scalar | Control field |
| Rating curve type | `rating_curve_type` | scalar | Curve selector |
| Rating curve | `head_discharge_id` | scalar | Linked curve table |
| Coef of outlet function | `discharge_coefficient` | scalar | Hydraulic parameter |
| Exp of outlet function | `discharge_exponent` | scalar | Hydraulic parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Rating Curve (`sw_curve_rating`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Rating curve ID | `id` | scalar | Rating curve identifier |
| Rating array | `data` | blob | Sub-fields: `data.head`, `data.outflow` |

#### Transect (`sw_transect`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Transect ID | `id` | scalar | Transect identifier |
| Left bank roughness | `left_roughness` | scalar | Transect roughness field |
| Right bank roughness | `right_roughness` | scalar | Transect roughness field |
| Channel roughness | `channel_roughness` | scalar | Transect roughness field |
| Left bank offset | `left_offset` | scalar | Transect geometry field |
| Right bank offset | `right_offset` | scalar | Transect geometry field |
| Stations factor | `width_factor` | scalar | Transect geometry field |
| Elevation modifier | `elevation_adjust` | scalar | Transect adjustment field |
| Meander factor | `meander_factor` | scalar | Transect adjustment field |
| Profile | `profile` | blob | Sub-fields: `profile.x`, `profile.z` |

#### Control Curve (`sw_curve_control`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Curve ID | `id` | scalar | Control curve identifier |
| Control array | `data` | blob | Sub-fields: `data.variable`, `data.setting` |

### Subcatchments

#### Subcatchment (`sw_subcatchment`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Subcatchment ID | `subcatchment_id` | scalar | |
| Land uses | `coverages` | blob | Sub-fields: `coverages.land_use`, `coverages.area` |
| Initial buildup | `loadings` | blob | Sub-fields: `loadings.pollutant`, `loadings.build_up` |
| Soils | `soil` | blob | Sub-fields: `soil.soil`, `soil.area` |
| Rain gage ID | `raingauge_id` | scalar | Linked rain gage |
| Drains to | `sw_drains_to` | scalar | 'sw_node', 'sw_subcatchment' |
| Outlet | `outlet_id` | scalar | |
| Area | `area` | scalar | SWMM area; InfoWorks uses `contributing_area` |
| Hydraulic length | `hydraulic_length` | scalar |  |
| x | `x` | scalar |  |
| y | `y` | scalar | note: capital X in results scripts, lowercase y |
| Subcatchment width | `width` | scalar | Characteristic width |
| Slope | `catchment_slope` | scalar |  |
| Use area-averaged rain | `area_average_rain` | scalar |  |
| Imperviousness (%) | `percent_impervious` | scalar |  |
| Impervious roughness | `roughness_impervious` | scalar | Manning's N for impervious surface |
| Pervious roughness | `roughness_pervious` | scalar | Manning's N for pervious surface |
| Impervious storage depth | `storage_impervious` | scalar | Depression storage impervious |
| Pervious storage depth | `storage_pervious` | scalar | Depression storage pervious |
| Percent no storage | `percent_no_storage` | scalar | Percentage with no depression storage |
| Routing | `route_to` | scalar | 'Outlet', 'Impervious', 'Pervious' |
| Infiltration model | `infiltration` | scalar | 'Default', 'Horton', 'Modified_Horton', 'Green_Ampt', 'Modified_Green_Ampt', 'Curve_number' |
| Percent routed | `percent_routed` | scalar | Percentage of flow routed |
| Initial infiltration | `initial_infiltration` | scalar | Horton/GA initial rate |
| Limiting infiltration | `limiting_infiltration` | scalar | Horton/GA limiting rate |
| Decay factor | `decay_factor` | scalar | Horton decay constant |
| Initial abstraction factor | `initial_abstraction_factor` | scalar |  |
| Drying time | `drying_time` | scalar | Horton drying time |
| Maximum infiltration volume | `max_infiltration_volume` | scalar | Volume limit for Horton method |
| Aquifer ID | `aquifer_id` | scalar | Linked aquifer |
| Aquifer node ID | `aquifer_node_id` | scalar | Groundwater discharge node |
| Aquifer elevation | `aquifer_elevation` | scalar | Aquifer/GW reference elevation |
| Aquifer Initial ground water elevation | `aquifer_initial_groundwater` | scalar | Initial GW level |
| Aquifer Initial ground water moisture content | `aquifer_initial_moisture_content` | scalar | Initial unsaturated zone moisture |
| Elevation | `elevation` | scalar | Surface elevation |
| Groundwater coefficient | `groundwater_coefficient` | scalar | Lateral GW flow coefficient |
| Groundwater exponent | `groundwater_exponent` | scalar | Lateral GW flow exponent |
| Groundwater threshold | `groundwater_threshold` | scalar | GW flow threshold depth |
| Initial moisture deficit | `initial_moisture_deficit` | scalar | Green-Ampt initial moisture deficit |
| Lateral groundwater flow equation | `lateral_gwf_equation` | scalar |  |
| Deep groundwater flow equation | `deep_gwf_equation` | scalar |  |
| Surface coefficient | `surface_coefficient` | scalar | Surface GW flow coefficient |
| Surface depth | `surface_depth` | scalar |  |
| Surface exponent | `surface_exponent` | scalar |  |
| Surface groundwater coefficient | `surface_groundwater_coefficient` | scalar |  |
| Curve number | `curve_number` | scalar | CN method curve number |
| Average capillary suction | `average_capillary_suction` | scalar | Green-Ampt suction head |
| Saturated hydraulic conductivity | `saturated_hydraulic_conductivity` | scalar | Green-Ampt saturated K |
| Initial abstraction type | `initial_abstraction_type` | scalar |  |
| Runoff model type | `runoff_model_type` | scalar | 'SWMM', 'SCS_curvilinear', 'SCS_triangular' |
| Shape factor | `shape_factor` | scalar |  |
| Initial abstraction | `initial_abstraction` | scalar |  |
| Time of concentration | `time_of_concentration` | scalar |  |
| Snow pack ID | `snow_pack_id` | scalar | Linked snow pack |
| Curb length | `curb_length` | scalar | Gutter/curb length for inlet capture |
| LID controls | `suds_controls` | blob | Placement rows on subcatchment; Sub-fields: `suds_controls.suds_structure`, `suds_controls.id`, `suds_controls.area`, `suds_controls.num_units`, `suds_controls.impervious_area_treated_pct`, `suds_controls.pervious_area_treated_pct`, `suds_controls.outflow_to`, `suds_controls.surface` (control definition fields are `sw_suds_control` below) |
| Pervious surface roughness pattern | `n_perv_pattern` | scalar | Time-varying roughness |
| Depression storage pattern | `dstore_pattern` | scalar |  |
| Infiltration capacity pattern | `infil_pattern` | scalar |  |

#### LID control (`sw_suds_control`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Control ID | `control_id` | scalar | |
| Control type | `control_type` | scalar | 'Bio-retention cell', 'Rain garden', 'Green roof', 'Infiltration trench', 'Permeable pavement', 'Rain barrel', 'Rooftop disconnection', 'Vegetative swale' |
| Berm height | `surf_berm_height` | scalar | Surface layer |
| Storage depth | `surf_storage_depth` | scalar | Surface layer |
| Vegetation volume fraction | `surf_veg_vol_fraction` | scalar | Surface layer |
| Surface roughness (Manning's n) | `surf_roughness_n` | scalar | Surface layer |
| Surface slope | `surf_slope` | scalar | Surface layer |
| Swale side slope (run/rise) | `surf_xslope` | scalar | Surface layer |
| Pavement thickness | `pave_thickness` | scalar | Pavement layer |
| Pavement void ratio | `pave_void_ratio` | scalar | Pavement layer |
| Impervious surface fraction | `pave_impervious_surf_fraction` | scalar | Pavement layer |
| Permeability | `pave_permeability` | scalar | Pavement layer |
| Pavement clogging factor | `pave_clogging_factor` | scalar | Pavement layer |
| Regeneration interval | `pave_regen_interval` | scalar | Pavement layer |
| Regeneration fraction | `pave_regen_fraction` | scalar | Pavement layer |
| Soil class | `soil_class` | scalar | 'Sand', 'Loamy sand', 'Sandy loam', 'Loam', 'Silt loam', 'Sandy clay loam', 'Clay loam', 'Silty clay loam', 'Sandy clay', 'Silty clay', 'Clay' |
| Soil thickness | `soil_thickness` | scalar | Soil layer |
| Soil porosity | `soil_porosity` | scalar | Soil layer |
| Field capacity | `soil_field_capacity` | scalar | Soil layer |
| Wilting point | `soil_wilting_point` | scalar | Soil layer |
| Conductivity | `soil_conductivity` | scalar | Soil layer |
| Conductivity slope | `soil_conductivity_slope` | scalar | Soil layer |
| Suction head | `soil_suction_head` | scalar | Soil layer |
| Barrel height | `storage_barrel_height` | scalar | Storage layer |
| Storage thickness | `storage_thickness` | scalar | Storage layer |
| Storage void ratio | `storage_void_ratio` | scalar | Storage layer |
| Seepage rate | `storage_seepage_rate` | scalar | Storage layer |
| Storage clogging factor | `storage_clogging_factor` | scalar | Storage layer |
| Coefficient for flow in flow units | `underdrain_flow_coefficient` | scalar | Underdrain |
| Flow exponent | `underdrain_flow_exponent` | scalar | Underdrain |
| Offset height | `underdrain_offset_height` | scalar | Underdrain |
| Delay | `underdrain_delay` | scalar | Underdrain |
| Flow capacity | `underdrain_flow_capacity` | scalar | Underdrain |
| Underdrain close depth | `underdrain_close_depth` | scalar | Underdrain |
| Underdrain open depth | `underdrain_open_depth` | scalar | Underdrain |
| Underdrain control curve | `underdrain_control_curve` | scalar | Underdrain |
| Underdrain pollutant removal | `underdrain_poll_removal` | blob | Sub-fields: `underdrain_poll_removal.pollutant`, `underdrain_poll_removal.removal_percent` |
| Mat thickness | `drainagemat_thickness` | scalar | Drainage mat |
| Mat void fraction | `drainagemat_void_fraction` | scalar | Drainage mat |
| Mat roughness (Manning's n) | `drainagemat_roughness` | scalar | Drainage mat |

#### Land Use (`sw_land_use`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Land use ID | `id` | scalar | SWMM land use identifier |
| Build-up | `build_up` | blob | Sub-fields: `build_up.pollutant`, `build_up.build_up_type`, `build_up.max_build_up`, `build_up.power_rate_constant`, `build_up.power_time_exponent`, `build_up.exp_rate_constant`, `build_up.saturation_constant`, `build_up.unit` |
| Washoff | `washoff` | blob | Sub-fields: `washoff.pollutant`, `washoff.washoff_type`, `washoff.exponential_washoff_coeff`, `washoff.rating_washoff_coeff`, `washoff.emc_washoff_coeff`, `washoff.washoff_exponent`, `washoff.sweep_removal`, `washoff.bmp_removal` |
| Sweep interval | `sweep_interval` | scalar | Street sweeping interval (days) |
| Sweep availability | `sweep_removal` | scalar | Fraction available after sweeping |
| Last swept | `last_sweep` | scalar | Days since last swept |

#### Pollutant (`sw_pollutant`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Name | `id` | scalar | Pollutant identifier |
| Units | `units` | scalar | 'mg/l', 'ug/l', '#/l' |
| Rainfall concentration | `rainfall_conc` | scalar | Concentration field |
| Groundwater concentration | `groundwater_conc` | scalar | Concentration field |
| I&I concentration | `rdii_conc` | scalar | Concentration field |
| DWF concentration | `dwf_conc` | scalar | Concentration field |
| Initial concentration | `init_conc` | scalar | Initial condition |
| Decay coefficient | `decay_coeff` | scalar | Decay field |
| Snow only | `snow_build_up` | scalar | Snow field |
| Co-pollutant | `co-pollutant` | scalar | Co-pollutant name field |
| Co-fraction | `co-fraction` | scalar | Co-pollutant fraction field |

#### Snow Pack (`sw_snow_pack`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Snow pack ID | `id` | scalar | SWMM snow pack identifier |
| Plowable min. melt coefficient | `plow_min_melt` | scalar | Melt parameter |
| Plowable max. melt coefficient | `plow_max_melt` | scalar | Melt parameter |
| Plowable base temperature | `plow_base_temp` | scalar | Temperature field |
| Plowable fraction free water capacity | `plow_free_water` | scalar | Water content parameter |
| Plowable initial snow depth | `plow_snow_depth` | scalar | Snow depth field |
| Plowable initial free water | `plow_initial_free_water` | scalar | Water content parameter |
| Fraction of impervious area plowable | `fraction_plowable` | scalar | Routing field |
| Impervious min. melt coefficient | `imp_min_melt` | scalar | Melt parameter |
| Impervious max. melt coefficient | `imp_max_melt` | scalar | Melt parameter |
| Impervious base temperature | `imp_base_temp` | scalar | Temperature field |
| Impervious fraction free water capacity | `imp_free_water` | scalar | Water content parameter |
| Impervious initial snow depth | `imp_snow_depth` | scalar | Snow depth field |
| Impervious initial free water | `imp_initial_free_water` | scalar | Water content parameter |
| Impervious depth at 100% cover | `imp_100_cover` | scalar | Snow depth field |
| Pervious min. melt coefficient | `perv_min_melt` | scalar | Melt parameter |
| Pervious max. melt coefficient | `perv_max_melt` | scalar | Melt parameter |
| Pervious base temperature | `perv_base_temp` | scalar | Temperature field |
| Pervious fraction free water capacity | `perv_free_water` | scalar | Water content parameter |
| Pervious initial snow depth | `perv_snow_depth` | scalar | Snow depth field |
| Pervious initial free water | `perv_initial_free_water` | scalar | Water content parameter |
| Pervious depth at 100% cover | `perv_100_cover` | scalar | Snow depth field |
| Depth at which snow removal begins | `plow_depth` | scalar | Snow depth/routing field |
| Fraction transferred out of the catchment | `out_of_watershed` | scalar | Routing field |
| Fraction transferred to the impervious area | `to_impervious` | scalar | Routing fraction |
| Fraction transferred to the pervious area | `to_pervious` | scalar | Routing fraction |
| Fraction converted into immediate melt | `to_immediate_melt` | scalar | Routing fraction |
| Fraction moved to another subcatchment | `to_subcatchment` | scalar | Routing fraction |
| Subcatchment ID | `subcatchment_id` | scalar | Linked subcatchment |

#### Underdrain Curve (`sw_curve_underdrain`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Curve ID | `id` | scalar | Underdrain curve identifier |
| Underdrain array | `data` | blob | Sub-fields: `data.depth`, `data.factor` |

#### Aquifer (`sw_aquifer`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Aquifer ID | `id` | scalar | Aquifer identifier |
| Soil porosity | `soil_porosity` | scalar | Soil property |
| Soil wilting point | `soil_wilting_point` | scalar | Soil property |
| Soil field capacity | `soil_field_capacity` | scalar | Soil property |
| Conductivity | `conductivity` | scalar | Aquifer property |
| Conductivity slope | `conductivity_slope` | scalar | Aquifer property |
| Tension slope | `tension_slope` | scalar | Aquifer property |
| Evapotranspiration fraction | `evapotranspiration_fraction` | scalar | ET property |
| Evapotranspiration depth | `evapotranspiration_depth` | scalar | ET property |
| Seepage rate | `seepage_rate` | scalar | Aquifer property |
| Elevation | `elevation` | scalar | Elevation field |
| Initial groundwater | `initial_groundwater` | scalar | Initial condition |
| Initial moisture content | `initial_moisture_content` | scalar | Initial condition |
| Time pattern ID | `time_pattern_id` | scalar | Linked time pattern |

#### Soil (`sw_soil`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Soil ID | `id` | scalar | Soil identifier |
| Initial infiltration | `initial_infiltration` | scalar | Horton field |
| Limiting infiltration | `limiting_infiltration` | scalar | Horton field |
| Decay factor | `decay_factor` | scalar | Horton field |
| Drying time | `drying_time` | scalar | Infiltration drying |
| Maximum infiltration volume | `max_infiltration_volume` | scalar | Horton field |
| Initial moisture deficit | `initial_moisture_deficit` | scalar | Green-Ampt field |
| Curve number | `curve_number` | scalar | CN field |
| Average capillary suction | `average_capillary_suction` | scalar | Green-Ampt field |
| Saturated hydraulic conductivity | `saturated_hydraulic_conductivity` | scalar | Green-Ampt field |

### Polygons and 2D Objects

#### Polygon (`sw_polygon`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `polygon_id` | scalar | |
| Category | `category_id` | scalar | |
| Area | `area` | scalar | |

#### TVD connector (`sw_tvd_connector`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `id` | scalar | |
| Category | `category_id` | scalar | |
| Input A units type | `input_a_units` | scalar | |
| Input A | `input_a` | scalar | |
| Input B units type | `input_b_units` | scalar | |
| Input B | `input_b` | scalar | |
| Input C units type | `input_c_units` | scalar | |
| Input C | `input_c` | scalar | |
| Output units type | `output_units` | scalar | |
| Connector units | `expression_units` | scalar | |
| Output expression | `output_expression` | scalar | |
| Resampling buffer (mins) | `resampling_buffer` | scalar | |
| Connected object type | `connected_object_type` | scalar | |
| Connected object id | `connected_object_id` | scalar | |
| Connection usage | `usage` | scalar | |
| Input attribute | `input_attribute` | scalar | |
| Comparison result | `comparison_result` | scalar | |
| Area | `area` | scalar | |
| X coord | `x` | scalar | |
| Y coord | `y` | scalar | |

#### Spatial rain zone (`sw_spatial_rain_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `id` | scalar | |
| Area | `area` | scalar | |

#### Spatial rain source (`sw_spatial_rain_source`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `id` | scalar | |
| Source type | `source_type` | scalar | |
| Stream name or category | `stream_or_category` | scalar | |
| Priority | `priority` | scalar | |
| Start seconds relative to origin | `start_time` | scalar | |
| End seconds relative to origin | `end_time` | scalar | |

#### 2D zone (`sw_2d_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `zone_id` | scalar | |
| Boundary type | `boundary_type` | scalar | |
| Area | `area` | scalar | |
| Maximum triangle area | `max_triangle_area` | scalar | |
| Minimum element area | `min_mesh_element_area` | scalar | |
| Maximum height variation | `max_height_variation` | scalar | |
| Mesh generation | `mesh_generation` | scalar | |
| Terrain-sensitive meshing | `terrain_sensitive_mesh` | scalar | |
| Minimum angle | `minimum_angle` | scalar | |
| Roughness (Manning's n) | `roughness` | scalar | |
| Roughness definition | `roughness_definition_id` | scalar | Links to `sw_roughness_definition` |
| Apply rainfall etc directly to mesh elements | `apply_rainfall_directly` | scalar | |
| Apply rainfall etc | `apply_rainfall_subcatch` | scalar | |
| Rainfall profile | `rainfall_profile` | scalar | |
| Rainfall percentage | `rainfall_percentage` | scalar | |
| Mesh summary | `mesh_summary` | scalar | |

#### Roughness zone (`sw_roughness_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `polygon_id` | scalar | |
| Area | `area` | scalar | |
| Exclude roughness zone boundary when creating 2D mesh | `exclude_from_2d_mesh` | scalar | |
| Roughness (Manning's n) | `roughness` | scalar | |
| Roughness definition | `roughness_definition_id` | scalar | Links to `sw_roughness_definition` |
| Priority | `priority` | scalar | |

#### Roughness definition (`sw_roughness_definition`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `definition_id` | scalar | |
| Number of depth bands | `number_of_bands` | scalar | '1', '2', '3' |
| Roughness 1 (Manning's n) | `roughness_1` | scalar | |
| Depth threshold 1 | `depth_thld_1` | scalar | |
| Roughness 2 (Manning's n) | `roughness_2` | scalar | |
| Depth threshold 2 | `depth_thld_2` | scalar | |
| Roughness 3 (Manning's n) | `roughness_3` | scalar | |

#### Mesh zone (`sw_mesh_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `polygon_id` | scalar | |
| Area | `area` | scalar | |
| Maximum triangle area | `max_triangle_area` | scalar | |
| Override 2D zone minimum element area setting | `apply_min_elt_size` | scalar | |
| Minimum element area | `min_mesh_element_area` | scalar | |

#### Mesh level zone (`sw_mesh_level_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `polygon_id` | scalar | |
| Area | `area` | scalar | |
| Type | `level_type` | scalar | |
| Use upper limit | `use_upper_limit` | scalar | |
| Upper limit level | `upper_limit_level` | scalar | |
| Use lower limit | `use_lower_limit` | scalar | |
| Lower limit level | `lower_limit_level` | scalar | |
| Vertices | `level_sections` | blob | Sub-fields: `level_sections.elevation` |
| Level | `level` | scalar | |
| Raise by | `raise_by` | scalar | |

#### Porous polygon (`sw_porous_polygon`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Porous polygon | `polygon_id` | scalar | |
| Asset ID | `asset_id` | scalar | |
| Porosity | `porosity` | scalar | |
| Crest level | `crest_level` | scalar | |
| Height | `height` | scalar | |
| Level | `level` | scalar | |
| Remove wall during simulation | `remove_wall` | scalar | |
| Wall removal trigger | `wall_removal_trigger` | scalar | |
| Use difference across wall | `use_diff_across_wall` | scalar | |
| Depth threshold | `depth_threshold` | scalar | |
| Elevation threshold | `elevation_threshold` | scalar | |
| Velocity threshold | `velocity_threshold` | scalar | |
| Unit flow threshold | `unit_flow_threshold` | scalar | |
| Total head threshold | `total_head_threshold` | scalar | |
| Force threshold | `force_threshold` | scalar | |
| Hydrostatic pressure coefficient | `hydro_press_coeff` | scalar | |
| No rainfall | `no_rainfall` | scalar | |
| Area | `area` | scalar | |

### Lines

#### General line (`sw_general_line`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| General line | `line_id` | scalar | |
| Asset ID | `asset_id` | scalar | |
| Category | `category` | scalar | |
| Length | `length` | scalar | |

#### Porous wall (`sw_porous_wall`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Porous wall | `line_id` | scalar | |
| Asset ID | `asset_id` | scalar | |
| Porosity | `porosity` | scalar | |
| Crest level | `crest_level` | scalar | |
| Height | `height` | scalar | |
| Level | `level` | scalar | |
| Remove wall during simulation | `remove_wall` | scalar | |
| Wall removal trigger | `wall_removal_trigger` | scalar | |
| Use difference across wall | `use_diff_across_wall` | scalar | |
| Depth threshold | `depth_threshold` | scalar | |
| Elevation threshold | `elevation_threshold` | scalar | |
| Velocity threshold | `velocity_threshold` | scalar | |
| Unit flow threshold | `unit_flow_threshold` | scalar | |
| Total head threshold | `total_head_threshold` | scalar | |
| Force threshold | `force_threshold` | scalar | |
| Hydrostatic pressure coefficient | `hydro_press_coeff` | scalar | |
| Length | `length` | scalar | |

#### 2D boundary (`sw_2d_boundary_line`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Name | `line_id` | scalar | |
| Boundary line type | `line_type` | scalar | 'Vertical wall', 'Critical depth', 'Supercritical', 'Dry', 'Normal depth', 'Inflow', 'Level', 'Level & head/discharge' |
| Bed load boundary type | `bed_load_boundary` | scalar | |
| Suspended load boundary type | `suspended_load_boundary` | scalar | |
| Head unit flow table | `head_unit_discharge_id` | scalar | |
| Length | `length` | scalar | |

#### Head unit flow (`sw_head_unit_discharge`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Head unit flow ID | `head_unit_discharge_id` | scalar | |
| Description | `head_unit_discharge_description` | scalar | |
| Head unit flow table | `HUDP_table` | blob | Sub-fields: `HUDP_table.head`, `HUDP_table.unit_discharge` |

### Points

#### Rain Gage (`sw_raingage`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Rain gage ID | `raingage_id` | scalar | Rain gage identifier |
| x | `x` | scalar | Geometry field |
| y | `y` | scalar | Geometry field |
| Rainfall profile | `rainfall_profile` | scalar | Linked rainfall profile |
| Snow catch factor | `scf` | scalar | |

---

## Simulation Results

Result fields use `tsr.ATTRIBUTE` syntax. See `InfoWorks_ICM_SQL_Schema_Common.md` for `tsr.*` metadata fields.

### Summary Results (`sim.*`)

The `sim.*` prefix returns summary results at the current timestep or maximum. No aggregate function is needed.

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Maximum Depth | `sim.max_depth` | result | SWMM node/conduit result |
| Maximum Flow | `sim.max_flow` | result | SWMM link result |

**Do not assume a `sim.*` suffix from one network type will work in the other.** InfoWorks-specific `sim.*` fields are in `Schema_InfoWorks.md`.

### Node Results (`sw_node`, `sw_outfall`, `sw_storage_node`)

#### Hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Water depth | `tsr.DEPTH` | result | Time-varying |
| Hydraulic head | `tsr.HEAD` | result | Time-varying |
| Stored volume | `tsr.VOLUME` | result | Time-varying |
| Lateral inflow | `tsr.LATERAL_INFLOW` | result | Time-varying |
| Total inflow | `tsr.TOTAL_INFLOW` | result | Time-varying |
| Surface flooding | `tsr.FLOODING` | result | Time-varying |
| Pressure | `tsr.PRESSURE` | result | Time-varying |
| Inlet elevation | `tsr.INVERT_ELEVATION` | result | Time-varying |
| Head class | `tsr.HEAD_CLASS` | result | Time-varying; 0=below invert, 1=below crown, 2=below max depth, 3=surcharged |

#### Hydraulic maxima results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max water depth | `tsr.MAX_DEPTH` | result | Maxima |
| Max hydraulic head | `tsr.MAX_HEAD` | result | Maxima |
| Max total inflow | `tsr.MAX_TOTAL_INFLOW` | result | Maxima |

#### Hydraulic summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Total flood volume | `tsr.TOTAL_FLOOD_VOLUME` | result | Summary |
| Total flood time | `tsr.TOTAL_FLOOD_TIME` | result | Summary |
| Flow volume difference | `tsr.FLOW_VOLUME_DIFFERENCE` | result | Summary |
| Total inflow volume | `tsr.TOTAL_INFLOW_VOLUME` | result | Summary; outfall nodes only |

#### Water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| \<pollutant name\> | `tsr.<pollutant name>` | result | Time-varying; attribute is the pollutant name |

### Link Results (`sw_conduit`, `sw_pump`, `sw_orifice`, `sw_weir`, `sw_outlet`)

#### Conduit hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Flow | `tsr.FLOW` | result | Time-varying |
| Depth | `tsr.DEPTH` | result | Time-varying |
| Velocity | `tsr.VELOCITY` | result | Time-varying |
| HGL | `tsr.HGL` | result | Time-varying; average of upstream and downstream node heads |
| Flow volume | `tsr.FLOW_VOLUME` | result | Time-varying |
| Flow class | `tsr.FLOW_CLASS` | result | Time-varying |
| Capacity (depth/max depth) | `tsr.CAPACITY` | result | Time-varying |
| Surcharged | `tsr.SURCHARGED` | result | Time-varying |
| Entry loss | `tsr.ENTRY_LOSS` | result | Time-varying |
| Exit loss | `tsr.EXIT_LOSS` | result | Time-varying |

#### Pump hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Flow | `tsr.FLOW` | result | Time-varying |
| Depth | `tsr.DEPTH` | result | Time-varying |
| Upstream head | `tsr.UPSTREAM_HEAD` | result | Time-varying |
| Downstream head | `tsr.DOWNSTREAM_HEAD` | result | Time-varying |
| Head gain | `tsr.HEAD_GAIN` | result | Time-varying |
| Speed ratio | `tsr.SPEED_RATIO` | result | Time-varying |
| Useful power | `tsr.USEFUL_POWER` | result | Time-varying |

#### Orifice/Weir/Outlet hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Flow | `tsr.FLOW` | result | Time-varying |
| Depth | `tsr.DEPTH` | result | Time-varying |

#### Conduit hydraulic maxima results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max flow | `tsr.MAX_FLOW` | result | Maxima |
| Max depth | `tsr.MAX_DEPTH` | result | Maxima |
| Max capacity | `tsr.MAX_CAPACITY` | result | Maxima |
| Max velocity | `tsr.MAX_VELOCITY` | result | Maxima |

#### Pump/orifice/weir/outlet hydraulic maxima results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max flow | `tsr.MAX_FLOW` | result | Maxima |
| Max depth | `tsr.MAX_DEPTH` | result | Maxima |

#### Pump hydraulic summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Min flow | `tsr.MIN_FLOW` | result | Summary |
| Percentage utilised | `tsr.PERCENT_UTILISED` | result | Summary |
| Power usage | `tsr.POWER_USAGE` | result | Summary |

#### Water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| \<pollutant name\> | `tsr.<pollutant name>` | result | Time-varying; attribute is the pollutant name |
| Max \<pollutant name\> | `tsr.<pollutant name>` | result | Maxima; attribute is the pollutant name |

### Subcatchment Results (`sw_subcatchment`)

#### Hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Rainfall | `tsr.RAINFALL` | result | Time-varying |
| Snow depth | `tsr.SNOW_DEPTH` | result | Time-varying |
| Evaporation loss | `tsr.EVAPORATION_LOSS` | result | Time-varying |
| Infiltration loss | `tsr.INFILTRATION_LOSS` | result | Time-varying |
| Runoff | `tsr.RUNOFF` | result | Time-varying |
| Groundwater flow | `tsr.GROUNDWATER_FLOW` | result | Time-varying |
| Groundwater elevation | `tsr.GROUNDWATER_ELEVATION` | result | Time-varying |
| Impervious runoff | `tsr.IMPERV_RUNOFF` | result | Time-varying |
| Pervious runoff | `tsr.PERV_RUNOFF` | result | Time-varying |

#### Hydraulic summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Total precipitation | `tsr.TOTAL_PRECIPITATION` | result | Summary |
| Total runon | `tsr.TOTAL_RUNON` | result | Summary |
| Total evaporation | `tsr.TOTAL_EVAPORATION` | result | Summary |
| Total infiltration | `tsr.TOTAL_INFILTRATION` | result | Summary |
| Total runoff depth | `tsr.TOTAL_RUNOFF_DEPTH` | result | Summary |
| Total runoff volume | `tsr.TOTAL_RUNOFF_VOLUME` | result | Summary |
| Peak runoff | `tsr.PEAK_RUNOFF` | result | Summary |
| Peak runoff time | `tsr.PEAK_RUNOFF_TIME` | result | Summary |
| Runoff coefficient | `tsr.RUNOFF_COEFFICIENT` | result | Summary |

#### Water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| \<pollutant name\> | `tsr.<pollutant name>` | result | Time-varying; attribute is the pollutant name |
| Max \<pollutant name\> | `tsr.<pollutant name>` | result | Maxima; attribute is the pollutant name |

### Rain Gauge Results (`sw_raingage`)

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Cumulative rainfall | `tsr.RAINDPTH` | result | Time-varying; cumulative rainfall depth |
| Rainfall | `tsr.RAINFALL` | result | Time-varying; rainfall intensity |

### 2D Zone Results (`sw_2d_zone`)

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Direction | `tsr.ANGLE2D` | result | Time-varying; flow direction in radians from due East |
| Mean depth | `tsr.AVEDEPTH2D` | result | Time-varying; wet-portion average depth; subgrid models only |
| Depth | `tsr.DEPTH2D` | result | Time-varying; highest depth for subgrid elements |
| Eddy viscosity | `tsr.EDDYVISCOSITY2D` | result | Time-varying |
| Elevation | `tsr.elevation2d` | result | Time-varying; null when element is dry |
| Froude number | `tsr.froude2d` | result | Time-varying |
| Speed | `tsr.SPEED2D` | result | Time-varying; water velocity |
| Unit flow | `tsr.unitflow2d` | result | Time-varying; flow per unit length |
| Volume | `tsr.SGVOLUME2D` | result | Time-varying; subgrid models only |

#### Summary (non time-varying) results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Subgrid flag | `tsr.SUBGRID2D` | result | Summary; 1=subgrid, 2=non-subgrid |
| Direction at first max velocity | `tsr.MAXANGLE2D` | result | Summary |
| Direction at first min velocity | `tsr.MINANGLE2D` | result | Summary; undefined if min velocity is zero |
| Direction at first max hazard | `tsr.MAXHAZANGLE2D` | result | Summary |
| Depth at first max hazard | `tsr.MAXHAZDEPTH2D` | result | Summary |
| Speed at first max hazard | `tsr.MAXHAZSPEED2D` | result | Summary |
| Direction at first max depth | `tsr.MAXDEPTHANGLE2D` | result | Summary |
| Direction at first max velocity above threshold | `tsr.MAXVELDEPTHANGLE2D` | result | Summary |
| Mesh element area | `tsr.AREA2D` | result | Summary |
| Element level (ground level) | `tsr.GNDLEV2D` | result | Summary |
| Max hazard | `tsr.HAZARD2D` | result | Summary; DEFRA HR = d×(v+0.5)+DF |
| Max depth | `tsr.MAX_DEPTH2D` | result | Summary |
| Max elevation | `tsr.MAX_ELEVATION2D` | result | Summary |
| Max speed | `tsr.MAX_SPEED2D` | result | Summary |
| Max unit flow | `tsr.MAXUNITFLOW2D` | result | Summary |
| Min depth | `tsr.MINDEPTH2D` | result | Summary |
| Min speed | `tsr.MINSPEED2D` | result | Summary |
| Min unit flow | `tsr.MINUNITFLOW2D` | result | Summary |
| Rainfall profile | `tsr.RAINPROF2D` | result | Summary |
| Time to last inundation | `tsr.T_END_INUNDATION_2D` | result | Summary; -1 if threshold not met |
| Total inundation duration | `tsr.T_FLOOD_DURATION_2D` | result | Summary; -1 if threshold not met |
| Time to first inundation | `tsr.T_INUNDATION_2D` | result | Summary; -1 if threshold not met |
| Time to peak inundation | `tsr.T_PEAK_2D` | result | Summary; -1 if element dry throughout |
| Volume error | `tsr.VOLERROR2D` | result | Summary |

### Network Results Point Results (2D) (`sw_2d_results_point`)

#### Time-varying hydraulic results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Direction | `tsr.ANGLE2D` | result | Time-varying; flow direction in radians from due East |
| Mean depth | `tsr.AVEDEPTH2D` | result | Time-varying; subgrid models only |
| Depth | `tsr.DEPTH2D` | result | Time-varying; highest depth for subgrid elements |
| Eddy viscosity | `tsr.EDDYVISCOSITY2D` | result | Time-varying |
| Elevation | `tsr.ELEVATION2D` | result | Time-varying |
| Froude number | `tsr.FROUDE2D` | result | Time-varying |
| Speed | `tsr.SPEED2D` | result | Time-varying |
| Unit flow | `tsr.UNITFLOW2D` | result | Time-varying |
| Volume | `tsr.SGVOLUME2D` | result | Time-varying; subgrid models only |

#### Summary (non time-varying) hydraulic results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Element level (ground level) | `tsr.GNDLEV2D` | result | Summary |
| Max mean depth | `tsr.MAXAVEDEPTH2D` | result | Summary; subgrid models only |
| Max depth | `tsr.MAXDEPTH2D` | result | Summary |
| Max eddy viscosity | `tsr.MAXEDDYVISCOSITY2D` | result | Summary |
| Max elevation | `tsr.MAXELEVATION2D` | result | Summary |
| Max speed | `tsr.MAXSPEED2D` | result | Summary |
| Max unit flow | `tsr.MAXUNITFLOW2D` | result | Summary |
| Max volume | `tsr.MAXSGVOLUME2D` | result | Summary; subgrid models only |
| Min mean depth | `tsr.MINAVEDEPTH2D` | result | Summary; subgrid models only |
| Min depth | `tsr.MINDEPTH2D` | result | Summary |
| Min elevation | `tsr.MINELEVATION2D` | result | Summary |
| Min speed | `tsr.MINSPEED2D` | result | Summary |
| Min unit flow | `tsr.MINUNITFLOW2D` | result | Summary |
| Min volume | `tsr.MINSGVOLUME2D` | result | Summary; subgrid models only |
| Direction at first max velocity | `tsr.MAXANGLE2D` | result | Summary |
| Direction at first min velocity | `tsr.MINANGLE2D` | result | Summary; undefined if min velocity is zero |
| Direction at first max hazard | `tsr.MAXHAZANGLE2D` | result | Summary |
| Depth at first max hazard | `tsr.MAXHAZDEPTH2D` | result | Summary |
| Speed at first max hazard | `tsr.MAXHAZSPEED2D` | result | Summary |
| Direction at first max depth | `tsr.MAXDEPTHANGLE2D` | result | Summary |
| Direction at first max velocity above threshold | `tsr.MAXVELDEPTHANGLE2D` | result | Summary |

### Network Results Line Results (2D) (`sw_2d_results_line`)

#### Time-varying hydraulic results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Flow | `tsr.FLOW2D` | result | Time-varying |
| Highest depth on line | `tsr.HIGHDEPTH2D` | result | Time-varying |
| Highest elevation on line | `tsr.HIGHELEVATION2D` | result | Time-varying; null when elements are dry |
| Highest speed normal to line | `tsr.HIGHSPEEDNORMAL2D` | result | Time-varying; absolute value |
| Lowest depth on line | `tsr.LOWDEPTH2D` | result | Time-varying |
| Lowest elevation on line | `tsr.LOWELEVATION2D` | result | Time-varying; null when elements are dry |
| Lowest speed normal to line | `tsr.LOWSPEEDNORMAL2D` | result | Time-varying; absolute value |

#### Summary (non time-varying) hydraulic results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max flow | `tsr.MAXFLOW2D` | result | Summary |
| Max highest depth on line | `tsr.MAXHIGHDEPTH2D` | result | Summary |
| Max highest elevation on line | `tsr.MAXHIGHELEVATION2D` | result | Summary; null if elements dry throughout |
| Max highest speed normal to line | `tsr.MAXHIGHSPEEDNORMAL2D` | result | Summary |
| Max ground level | `tsr.MAXGNDLEV2D` | result | Summary |
| Min flow | `tsr.MINFLOW2D` | result | Summary |
| Min lowest depth on line | `tsr.MINLOWDEPTH2D` | result | Summary |
| Min lowest elevation on line | `tsr.MINLOWELEVATION2D` | result | Summary |
| Min lowest speed normal to line | `tsr.MINLOWSPEEDNORMAL2D` | result | Summary |
| Min ground level | `tsr.MINGNDLEV2D` | result | Summary |
| Mean ground level | `tsr.AVEGNDLEV2D` | result | Summary |

### Network Results Polygon Results (2D) (`sw_2d_results_polygon`)

#### Time-varying hydraulic results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Flow into polygon | `tsr.FLOW2D` | result | Time-varying; positive = into polygon |
| Highest depth | `tsr.HIGHDEPTH2D` | result | Time-varying |
| Highest elevation | `tsr.HIGHELEVATION2D` | result | Time-varying; null when elements are dry |
| Highest speed | `tsr.HIGHSPEED2D` | result | Time-varying |
| Lowest depth | `tsr.LOWDEPTH2D` | result | Time-varying |
| Lowest elevation | `tsr.LOWELEVATION2D` | result | Time-varying; null when elements are dry |
| Lowest speed | `tsr.LOWSPEED2D` | result | Time-varying |
| Cumulative rainfall | `tsr.RAINDPTH` | result | Time-varying |
| Rainfall | `tsr.RAINFALL` | result | Time-varying; rainfall intensity |
| Enclosed volume | `tsr.VOLUME2D` | result | Time-varying |
| Area flooded to inundation depth | `tsr.FLOODED_AREA2D` | result | Time-varying |

#### Summary (non time-varying) hydraulic results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max flow into polygon | `tsr.MAXFLOW2D` | result | Summary |
| Max highest depth | `tsr.MAXHIGHDEPTH2D` | result | Summary |
| Max highest elevation | `tsr.MAXHIGHELEVATION2D` | result | Summary; null if elements dry throughout |
| Max highest speed | `tsr.MAXHIGHSPEED2D` | result | Summary |
| Max enclosed volume | `tsr.MAXVOLUME2D` | result | Summary |
| Max ground level | `tsr.MAXGNDLEV2D` | result | Summary |
| Max area flooded to inundation depth | `tsr.MAXFLOODED_AREA2D` | result | Summary |
| Min flow into polygon | `tsr.MINFLOW2D` | result | Summary |
| Min lowest depth | `tsr.MINLOWDEPTH2D` | result | Summary |
| Min lowest elevation | `tsr.MINLOWELEVATION2D` | result | Summary |
| Min lowest speed | `tsr.MINLOWSPEED2D` | result | Summary |
| Min enclosed volume | `tsr.MINVOLUME2D` | result | Summary |
| Min ground level | `tsr.MINGNDLEV2D` | result | Summary |
| Min area flooded to inundation depth | `tsr.MINFLOODED_AREA2D` | result | Summary |
| Mean ground level | `tsr.AVEGNDLEV2D` | result | Summary |
| Total area flooded to inundation depth | `tsr.TOTAL_FLOODED_AREA2D` | result | Summary |
