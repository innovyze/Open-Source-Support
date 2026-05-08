# InfoWorks ICM SQL Schema — InfoWorks Networks

**Last Updated:** March 20, 2026

**Load Priority:** LOOKUP — Load for any InfoWorks network SQL query requiring field names
**Load Condition:** CONDITIONAL — When user asks about InfoWorks fields, schemas, or object inventory

**Related Files:**
- `InfoWorks_ICM_SQL_Schema_Common.md` — Common fields (`user_text_*`, `user_number_*`), results schema (`sim.*`, `tsr.*`), relationship paths, Autodesk Help workflow
- `InfoWorks_ICM_SQL_Schema_SWMM.md` — SWMM network field names (separate file; do NOT mix with InfoWorks fields)
- `InfoWorks_ICM_SQL_Lessons_Learned.md` — Read FIRST — Critical field name gotchas

## Purpose

This file is the **authoritative field-name and object-manifest reference for InfoWorks networks**.

Use it when:
- A user is working with an InfoWorks network (default when `(SWMM)` is not specified)
- The query involves field names from `hw_*` tables
- An object manifest or coverage check is needed for InfoWorks objects

**SWMM fields are in `InfoWorks_ICM_SQL_Schema_SWMM.md`. Do not mix field sets.**

## Retrieval Rules for LLMs

1. Confirm the network type is **InfoWorks** before using this file.
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

## InfoWorks Network Object Manifest

Source: Autodesk Help `Network Data Fields` index page.

### Nodes Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Node | Node Data Fields (InfoWorks) | `hw_node` |

### Links Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Blockage | Blockage Data Fields | `hw_blockage` |
| Bridge Blockage | Bridge Blockage Data Fields | `hw_bridge_blockage` |
| Bridge | Bridge Data Fields | `hw_bridge` |
| Bridge inlet | Bridge Inlet Data Fields | `hw_bridge_inlet` |
| Bridge opening | Bridge Opening Data Fields | `hw_bridge_opening` |
| Bridge outlet | Bridge Outlet Data Fields | `hw_bridge_outlet` |
| Channel | Channel Data Fields | `hw_channel` |
| Channel shape | Channel Shape Data Fields | `hw_channel_shape` |
| Conduit | Conduit Data Fields (InfoWorks) | `hw_conduit` |
| Culvert inlet | Culvert Inlet Data Fields | `hw_culvert_inlet` |
| Culvert outlet | Culvert Outlet Data Fields | `hw_culvert_outlet` |
| Flap valve | Flap Valve Data Fields (InfoWorks) | `hw_flap_valve` |
| Flow efficiency | Flow Efficiency Table Data Fields | `hw_flow_efficiency` |
| Flume | Flume Data Fields | `hw_flume` |
| Head discharge | Head Discharge Tables | `hw_head_discharge` |
| Headloss curve | Headloss Curve Data Fields | `hw_headloss` |
| Inline bank | Inline Bank Data Fields | `hw_inline_bank` |
| Irregular weir | Irregular Weir Data Fields | `hw_irregular_weir` |
| Orifice | Orifice Data Fields (InfoWorks) | `hw_orifice` |
| Pump | Pump Data Fields (InfoWorks) | `hw_pump` |
| River Reach | River Reach Data Fields (InfoWorks) | `hw_river_reach` |
| Screen | Screen Data Fields | `hw_screen` |
| Sediment grading | Sediment Grading Data Fields | `hw_sediment_grading` |
| Shape | Shape Data Fields | `hw_shape` |
| Siphon | Siphon Data Fields | `hw_siphon` |
| Sluice | Sluice Data Fields | `hw_sluice` |
| User control | User-Defined Control Data Fields | `hw_user_control` |
| Weir | Weir Data Fields (InfoWorks) | `hw_weir` |

### Subcatchments Grid

| Object | Data Fields Topic | Internal Table | Notes |
|--------|-------------------|----------------|-------|
| Build-up/washoff land use | Build-up/Washoff Land Use Data Fields | `hw_swmm_land_use` | InfoWorks network object — 'swmm' in internal table name does NOT indicate a SWMM network object |
| Land use | Land Use Data Fields (InfoWorks) | `hw_land_use` | |
| Ground infiltration | Ground Infiltration Data Fields | `hw_ground_infiltration` | |
| PDM Descriptor | PDM Descriptor Data Fields | `hw_pdm_descriptor` | |
| Monthly RTK hydrograph | Monthly RTK Hydrograph Data Fields | `hw_unit_hydrograph_month` | |
| RTK hydrograph | RTK Hydrograph Data Fields | `hw_unit_hydrograph` | |
| Runoff surfaces | Runoff Surfaces Data Fields | `hw_runoff_surface` | |
| Snow pack | Snow Pack Data Fields (InfoWorks) | `hw_snow_pack` | |
| Subcatchment | Subcatchment Data Fields (InfoWorks) | `hw_subcatchment` | |
| SUDS controls | SUDS Controls Data Fields | `hw_suds_control` | |

### Polygons Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| Polygon | Polygon Data Fields (InfoWorks) | `hw_polygon` |
| Storage area | Storage Area Data Fields | `hw_storage_area` |
| 2D zone | 2D Zone Data Fields (InfoWorks) | `hw_2d_zone` |
| Mesh zone | Mesh Zone Data Fields (InfoWorks) | `hw_mesh_zone` |
| Mesh level zone | Mesh Level Zone Data Fields (InfoWorks) | `hw_mesh_level_zone` |
| Roughness zone | Roughness Zone Data Fields (InfoWorks) | `hw_roughness_zone` |
| Roughness definitions | Roughness Definition Data Fields | `hw_roughness_definition` |
| IC zone - hydraulics (2D) | IC Zone - hydraulics (2D) Data Fields | `hw_2d_ic_polygon` |
| IC zone - water quality (2D) | IC Zone - water quality (2D) Data Fields | `hw_2d_wq_ic_polygon` |
| IC zone - infiltration (2D) | IC Zone - infiltration (2D) Data Fields | `hw_2d_inf_ic_polygon` |
| IC zone - sedimentation (2D) | IC Zone - Sediment (2D) Data Fields | `hw_2d_sed_ic_polygon` |
| Porous polygon | Porous Polygon Data Fields (InfoWorks) | `hw_porous_polygon` |
| Infiltration zone (2D) | Infiltration Zone (2D) Data Fields | `hw_2d_infiltration_zone` |
| Infiltration surface (2D) | Infiltration Surface (2D) Data Fields | `hw_2d_infil_surface` |
| Turbulence zone (2D) | Turbulence Zone (2D) Data Fields | `hw_2d_turbulence_zone` |
| Turbulence model (2D) | Turbulence Model (2D) Data Fields | `hw_2d_turbulence_model` |
| Permeable zone (2D) | Permeable Zone (2D) Data Fields | `hw_2d_permeable_zone` |
| TVD connector | TVD Connector Data Fields (InfoWorks) | `hw_tvd_connector` |
| Spatial rain zone | Spatial Rain Zone Data Fields (InfoWorks) | `hw_spatial_rain_zone` |
| Spatial rain source | Spatial Rain Source Data Fields (InfoWorks) | `hw_spatial_rain_source` |
| Network results polygon (2D) | Network Results Polygon (2D) Data Fields | `hw_2d_results_polygon` |
| Risk impact zone | Risk Impact Zone Data Fields | `hw_risk_impact_zone` |
| ARMA | ARMA Data Fields | `hw_arma` |
| Building | Building Data Fields (InfoWorks) | `hw_building` |

### Lines Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| General line | General Line Data Fields (InfoWorks) | `hw_general_line` |
| Cross section line | Cross Section Line Data Fields | `hw_cross_section_survey` |
| Bank line | Bank Line Data Fields | `hw_bank_survey` |
| Porous wall | Porous Wall Data Fields (InfoWorks) | `hw_porous_wall` |
| Base linear structure (2D) | Base Linear Structure (2D) Data Fields | `hw_2d_linear_structure` |
| Sluice linear structure (2D) | Sluice Linear Structure (2D) Data Fields | `hw_2d_sluice` |
| Bridge linear structure (2D) | Bridge Linear Structure (2D) Data Fields | `hw_2d_bridge` |
| 2D boundary | 2D Boundary Line Data Fields | `hw_2d_boundary_line` |
| Network results line (2D) | Network Results Line (2D) Data Fields | `hw_2d_results_line` |
| 2D line source | 2D Line Source Data Fields | `hw_2d_line_source` |
| 2D line connect | 2D Line Connect Data Fields | `hw_2d_connect_line` |
| Head unit flow | Head Unit Flow Data Fields | `hw_head_unit_discharge` |

### Points Grid

| Object | Data Fields Topic | Internal Table |
|--------|-------------------|----------------|
| General point | General Point Data Fields | `hw_general_point` |
| 2D point source | 2D Point Source Data Fields | `hw_2d_point_source` |
| Network results point (1D) | Network Results Point (1D) Data Fields | `hw_1d_results_point` | `` |
| Network results point (2D) | Network Results Point (2D) Data Fields | `hw_2d_results_point` | `` |
| Damage receptor | Damage Receptor Data Fields | `hw_damage_receptor` | `` |

---

## InfoWorks Field Tables

All InfoWorks field tables are indexed here. For common fields (`user_text_*`, `user_number_*`, `hyperlinks`, `notes`) and results fields (`sim.*`, `tsr.*`) see `InfoWorks_ICM_SQL_Schema_Common.md`.

### Nodes

#### Node (`hw_node`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Node ID | `node_id` | scalar | |
| Node Type | `node_type` | scalar | 'manhole', 'outfall', 'storage', 'break', 'closed_storage', 'gully' |
| System Type | `system_type` | scalar | 'foul', 'storm', 'combined', 'dual_foul', 'dual_storm' |
| Connection Type | `connection_type` | scalar |  |
| Asset ID | `asset_id` | scalar |  |
| 2D Connect Line | `2d_connect_line` | scalar | linked 2D connection line object |
| Lateral Node ID | `lateral_node_id` | scalar | lateral inflow node link |
| Lateral Link Suffix | `lateral_link_suffix` | scalar |  |
| X Coordinate | `x` | scalar | |
| Y Coordinate | `y` | scalar | |
| Ground Level | `ground_level` | scalar | |
| Flood Level | `flood_level` | scalar | surcharge/flood engagement level |
| Chamber Roof | `chamber_roof` | scalar | soffit level of chamber |
| Chamber Floor Level | `chamber_floor_level` | scalar | Node invert level |
| Chamber Area | `chamber_area` | scalar |  |
| Shaft Area | `shaft_area` | scalar | Cross-sectional area of shaft |
| Shaft Area Additional | `shaft_area_additional` | scalar | extra shaft area above node |
| Chamber Area Additional | `chamber_area_additional` | scalar | extra chamber area above node |
| Base Area | `base_area` | scalar |  |
| Perimeter | `perimeter` | scalar |  |
| Flood Type | `flood_type` | scalar | 'surface', 'sealed', 'lost', 'stored', 'gully', 'inlet', 'linked2d' |
| Element Area Factor 2D | `element_area_factor_2d` | scalar | 2D mesh factor |
| Flooding Discharge Coefficient | `flooding_discharge_coeff` | scalar |  |
| Benching Method | `benching_method` | scalar | channel benching method |
| 2D Link Type | `2d_link_type` | scalar |  |
| Floodable Area | `floodable_area` | scalar | surface ponding area |
| Flood Depth 1 | `flood_depth_1` | scalar | ponding zone 1 depth |
| Flood Depth 2 | `flood_depth_2` | scalar | ponding zone 2 depth |
| Flood Area 1 | `flood_area_1` | scalar | ponding zone 1 area |
| Flood Area 2 | `flood_area_2` | scalar | ponding zone 2 area |
| Infiltration Coefficient | `infiltration_coeff` | scalar | SuDS/permeable node |
| Porosity | `porosity` | scalar |  |
| Vegetation Level | `vegetation_level` | scalar | SuDS node vegetation depth |
| Liner Level | `liner_level` | scalar | SuDS node liner depth |
| Infilt Coeff Above Vegetation | `infiltratn_coeff_abv_vegn` | scalar |  |
| Infilt Coeff Above Liner | `infiltratn_coeff_abv_liner` | scalar |  |
| Infilt Coeff Below Liner | `infiltratn_coeff_blw_liner` | scalar |  |
| Relative Stages | `relative_stages` | scalar |  |
| Storage Array | `storage_array` | blob | Sub-fields: `storage_array.level`, `storage_array.area`, `storage_array.perimeter` |
| Inlet Input Type | `inlet_input_type` | scalar | gully/inlet node |
| Inlet Type | `inlet_type` | scalar | gully/inlet node |
| Cross Slope | `cross_slope` | scalar | gully/inlet node road slope |
| Grate Width | `grate_width` | scalar | gully/inlet node |
| Grate Length | `grate_length` | scalar | gully/inlet node |
| Opening Length | `opening_length` | scalar | gully/inlet node |
| Opening Height | `opening_height` | scalar | gully/inlet node |
| Gutter Depression | `gutter_depression` | scalar | gully/inlet node |
| Lateral Depression | `lateral_depression` | scalar | gully/inlet node |
| Velocity Splash Over | `velocity_splashover` | scalar | gully/inlet node |
| Debris Factor | `debris` | scalar | gully/inlet node |
| Depth Weir | `depth_weir` | scalar | gully/inlet node |
| Clear Opening | `clear_opening` | scalar | gully/inlet node |
| Head Discharge ID | `head_discharge_id` | scalar | links to `hw_head_discharge` table |
| Flow Efficiency ID | `flow_efficiency_id` | scalar | links to `hw_flow_efficiency` table |
| Inlet UE a | `inlet_UE_a` | scalar | gully efficiency coefficient a |
| Inlet UE b | `inlet_UE_b` | scalar | gully efficiency coefficient b |
| Number of Gullies | `n_gullies` | scalar | gully/inlet node |
| Num Transverse Bars | `num_transverse_bars` | scalar | grate type specification |
| Num Longitudinal Bars | `num_longitudinal_bars` | scalar | grate type specification |
| Num Diagonal Bars | `num_diagonal_bars` | scalar | grate type specification |
| Min Area Including Voids | `min_area_inc_voids` | scalar |  |
| Area of Voids | `area_of_voids` | scalar |  |
| Half Road Width | `half_road_width` | scalar | gully/inlet node |

> Common data fields (`user_text_1`–`10`, `user_number_1`–`10`, `notes`, `hyperlinks`) apply to this object — see `Schema_Common.md`.

### Links

#### Conduit (`hw_conduit`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | |
| Downstream Node ID | `ds_node_id` | scalar | |
| Link Suffix | `link_suffix` | scalar | |
| Link Type | `link_type` | scalar | |
| System Type | `system_type` | scalar | 'foul', 'storm', 'combined', 'dual_foul', 'dual_storm' |
| Asset ID | `asset_id` | scalar |  |
| Sewer Reference | `sewer_reference` | scalar |  |
| Branch ID | `branch_id` | scalar |  |
| Conduit Material | `conduit_material` | scalar | CORRECTED from `material` |
| Conduit Type | `conduit_type` | scalar |  |
| Design Group | `design_group` | scalar |  |
| Site Condition | `site_condition` | scalar |  |
| Ground Condition | `ground_condition` | scalar |  |
| Shape | `shape` | scalar | Cross-section shape code |
| Width | `conduit_width` | scalar | Conduit width/diameter |
| Height | `conduit_height` | scalar | Conduit height |
| Springing Height | `springing_height` | scalar | horseshoe/special shapes |
| Number of Barrels | `number_of_barrels` | scalar |  |
| Length | `conduit_length` | scalar | InfoWorks pipe length |
| Upstream Invert | `us_invert` | scalar | |
| Downstream Invert | `ds_invert` | scalar | |
| Gradient | `gradient` | scalar | invert slope |
| Capacity | `capacity` | scalar |  |
| Inflow | `inflow` | scalar | base inflow |
| Slot Width | `slot_width` | scalar | Preissmann slot width |
| Connection Coefficient | `connection_coefficient` | scalar |  |
| Base Height | `base_height` | scalar |  |
| Sediment Depth | `sediment_depth` | scalar |  |
| Min Space Step | `min_space_step` | scalar |  |
| Roughness Type | `roughness_type` | scalar | |
| Bottom Roughness (CW) | `bottom_roughness_CW` | scalar | Chezy-White bottom roughness |
| Top Roughness (CW) | `top_roughness_CW` | scalar | Chezy-White top roughness |
| Bottom Roughness (Manning) | `bottom_roughness_Manning` | scalar | Manning's n bottom |
| Top Roughness (Manning) | `top_roughness_Manning` | scalar | Manning's n top |
| Bottom Roughness N | `bottom_roughness_N` | scalar |  |
| Top Roughness N | `top_roughness_N` | scalar |  |
| Bottom Roughness (HW) | `bottom_roughness_HW` | scalar | Hazen-Williams bottom |
| Top Roughness (HW) | `top_roughness_HW` | scalar | Hazen-Williams top |
| US Headloss Type | `us_headloss_type` | scalar | |
| DS Headloss Type | `ds_headloss_type` | scalar | |
| US Headloss Coefficient | `us_headloss_coeff` | scalar | |
| DS Headloss Coefficient | `ds_headloss_coeff` | scalar | |
| US Settlement Efficiency | `us_settlement_eff` | scalar |  |
| DS Settlement Efficiency | `ds_settlement_eff` | scalar |  |
| Critical Sewer Category | `critical_sewer_category` | scalar |  |
| Taking Off Reference | `taking_off_reference` | scalar |  |
| Solution Model | `solution_model` | scalar |  |
| Min Computational Nodes | `min_computational_nodes` | scalar |  |
| Infiltration Coeff Base | `infiltration_coeff_base` | scalar |  |
| Infiltration Coeff Side | `infiltration_coeff_side` | scalar |  |
| Fill Material Conductivity | `fill_material_conductivity` | scalar |  |
| Porosity | `porosity` | scalar |  |
| Diff1D Type | `diff1d_type` | scalar |  |
| Diff1D D0 | `diff1d_d0` | scalar |  |
| Diff1D D1 | `diff1d_d1` | scalar |  |
| Diff1D D2 | `diff1d_d2` | scalar |  |
| Inlet Type Code | `inlet_type_code` | scalar | HEC standard inlet type |
| Reverse Flow Model | `reverse_flow_model` | scalar |  |
| Equation | `equation` | scalar | culvert equation type |
| k | `k` | scalar | culvert equation coefficient |
| m | `m` | scalar | culvert equation coefficient |
| c | `c` | scalar | culvert equation coefficient |
| y | `y` | scalar | culvert equation coefficient |
| US Ki (inlet) | `us_ki` | scalar | culvert entry loss |
| US Ko (outlet) | `us_ko` | scalar | culvert exit loss |
| Outlet Type Code | `outlet_type_code` | scalar |  |
| Outlet Equation | `equation_o` | scalar |  |
| Outlet k | `k_o` | scalar |  |
| Outlet m | `m_o` | scalar |  |
| Outlet c | `c_o` | scalar |  |
| Outlet y | `y_o` | scalar |  |
| DS Ki | `ds_ki` | scalar |  |
| DS Ko | `ds_ko` | scalar |  |

> Common data fields (`user_text_1`–`10`, `user_number_1`–`10`, `notes`, `hyperlinks`) apply to this object — see `Schema_Common.md`.

#### Pump (`hw_pump`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Pump identification suffix |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Switch On Level | `switch_on_level` | scalar | Pump control field |
| Switch Off Level | `switch_off_level` | scalar | Pump control field |
| Delay | `delay` | scalar | Pump timing field |
| Off Delay | `off_delay` | scalar | Pump timing field |
| Discharge | `discharge` | scalar | Pump flow field |
| Base Level | `base_level` | scalar | Pump datum field |
| Head Discharge ID | `head_discharge_id` | scalar | Link to `hw_head_discharge` table |
| Minimum Flow | `minimum_flow` | scalar | Pump limit |
| Maximum Flow | `maximum_flow` | scalar | Pump limit |
| Maximum Speed | `maximum_speed` | scalar | Variable-speed pump field |
| Minimum Speed | `minimum_speed` | scalar | Variable-speed pump field |
| Nominal Speed | `nominal_speed` | scalar | Variable-speed pump field |
| Threshold Speed | `threshold_speed` | scalar | Variable-speed pump field |
| Nominal Flow | `nominal_flow` | scalar | Pump rating field |
| Electric Hydraulic Ratio | `electric_hydraulic_ratio` | scalar | Pump efficiency/power field |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Orifice (`hw_orifice`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Invert | `invert` | scalar | Hydraulic geometry field |
| Diameter | `diameter` | scalar | Physical geometry field |
| Discharge Coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Secondary Discharge Coefficient | `secondary_discharge_coeff` | scalar | Hydraulic parameter |
| Opening Type | `opening_type` | scalar | Control geometry/type field |
| Limiting Discharge | `limiting_discharge` | scalar | Flow limit field |
| Minimum Flow | `minimum_flow` | scalar | Operational limit |
| Maximum Flow | `maximum_flow` | scalar | Operational limit |
| Positive Change in Flow | `positive_change_in_flow` | scalar | Ramp field |
| Negative Change in Flow | `negative_change_in_flow` | scalar | Ramp field |
| Threshold | `threshold` | scalar | Operational threshold |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Flap Valve (`hw_flap_valve`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Valve Type | `valve_type` | scalar | Flap-valve classification |
| Invert | `invert` | scalar | Hydraulic geometry field |
| Diameter | `diameter` | scalar | Physical geometry field |
| Height | `height` | scalar | Physical geometry field |
| Width | `width` | scalar | Physical geometry field |
| Discharge Coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Flume (`hw_flume`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Invert | `invert` | scalar | Hydraulic geometry field |
| Width | `width` | scalar | Physical geometry field |
| Length | `length` | scalar | Physical geometry field |
| Side Slope | `side_slope` | scalar | Geometry field |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Siphon (`hw_siphon`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Crest | `crest` | scalar | Hydraulic crest field |
| Crown Level | `crown_level` | scalar | Geometry field |
| Priming Level | `priming_level` | scalar | Hydraulic control field |
| Outlet Level | `outlet_level` | scalar | Hydraulic geometry field |
| Soffit Level | `soffit_level` | scalar | Hydraulic geometry field |
| Width | `width` | scalar | Physical geometry field |
| Siphon Discharge Coefficient | `cd_siphon` | scalar | Hydraulic parameter |
| Weir Discharge Coefficient | `cd_weir` | scalar | Hydraulic parameter |
| Number of Siphons | `number_of_siphons` | scalar | Count field |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Channel (`hw_channel`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Number of Barrels | `number_of_barrels` | scalar | Geometry/count field |
| Length | `length` | scalar | Channel length |
| Shape | `shape` | scalar | Link to channel shape definition |
| Base Flow Depth | `base_flow_depth` | scalar | Hydraulic field |
| Sediment Depth | `sediment_depth` | scalar | Sediment field |
| Solution Model | `solution_model` | scalar | Solver option |
| Upstream Invert | `us_invert` | scalar | Hydraulic geometry field |
| Upstream Headloss Type | `us_headloss_type` | scalar | Hydraulic loss field |
| Upstream Headloss Coefficient | `us_headloss_coeff` | scalar | Hydraulic loss field |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Downstream Invert | `ds_invert` | scalar | Hydraulic geometry field |
| Downstream Headloss Type | `ds_headloss_type` | scalar | Hydraulic loss field |
| Downstream Headloss Coefficient | `ds_headloss_coeff` | scalar | Hydraulic loss field |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Minimum Computational Nodes | `min_computational_nodes` | scalar | Solver discretization field |
| Inflow | `inflow` | scalar | Hydraulic field |
| Gradient | `gradient` | scalar | Derived/geometry field |
| Capacity | `capacity` | scalar | Hydraulic field |
| Is Merged | `is_merged` | scalar | Merge/state field |
| Branch ID | `branch_id` | scalar | Branch/control field |
| Base Height | `base_height` | scalar | Geometry field |
| Infiltration Coefficient Base | `infiltration_coeff_base` | scalar | Infiltration field |
| Infiltration Coefficient Side | `infiltration_coeff_side` | scalar | Infiltration field |
| Diff1D Type | `diff1d_type` | scalar | Diffusion model field |
| Diff1D D0 | `diff1d_d0` | scalar | Diffusion parameter |
| Diff1D D1 | `diff1d_d1` | scalar | Diffusion parameter |
| Diff1D D2 | `diff1d_d2` | scalar | Diffusion parameter |

#### Channel Shape (`hw_channel_shape`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Shape ID | `shape_id` | scalar | Cross-section shape identifier |
| Profile X | `profile.X` | blob | Cross-section station/offset |
| Profile Z | `profile.Z` | blob | Cross-section elevation |
| Profile Roughness CW | `profile.roughness_CW` | blob | Roughness blob field |
| Profile Roughness Manning | `profile.roughness_Manning` | blob | Roughness blob field |
| Profile New Panel | `profile.new_panel` | blob | Cross-section segmentation flag |
| Profile Roughness N | `profile.roughness_N` | blob | Roughness blob field |
| Roughness Type | `roughness_type` | scalar | Shape roughness selector |

#### Shape (`hw_shape`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Shape ID | `shape_id` | scalar | Conduit shape identifier |
| Shape Type | `shape_type` | scalar | Shape type classification |
| Shape Description | `shape_description` | scalar | Descriptive field |
| Geometry Height | `geometry.height` | blob | Shape geometry blob field |
| Geometry Left | `geometry.left` | blob | Shape geometry blob field |
| Geometry Right | `geometry.right` | blob | Shape geometry blob field |
| Normalised | `normalised` | scalar | Shape normalization flag |

#### Headloss Curve (`hw_headloss`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Headloss Type | `headloss_type` | scalar | Headloss model type |
| Curve Type | `curve_type` | scalar | Curve type selector |
| Minimum Surcharge Ratio | `min_surcharge_ratio` | scalar | Headloss curve field |
| Surcharge Ratio Step | `surcharge_ratio_step` | scalar | Headloss curve field |
| Surcharge Ratio Factor Array | `surcharge_ratio_factor_array` | scalar | Headloss curve field |
| Minimum Velocity | `min_velocity` | scalar | Headloss curve field |
| Velocity Step | `velocity_step` | scalar | Headloss curve field |
| Velocity Factor Array | `velocity_factor_array` | scalar | Headloss curve field |

#### Irregular Weir (`hw_irregular_weir`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Chainage | `chainage_elevation.chainage` | blob | Irregular-weir plan profile field |
| Elevation | `chainage_elevation.elevation` | blob | Irregular-weir profile elevation |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Discharge Coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Modular Limit | `modular_limit` | scalar | Hydraulic parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Crest | `crest` | scalar | Hydraulic crest field |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Flow Efficiency (`hw_flow_efficiency`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Flow Efficiency ID | `flow_efficiency_id` | scalar | Flow efficiency table identifier |
| Flow Efficiency Description | `flow_efficiency_description` | scalar | Descriptive field |
| Flow | `FE_table.flow` | blob | Efficiency-curve blob field |
| Efficiency | `FE_table.efficiency` | blob | Efficiency-curve blob field |

#### Weir (`hw_weir`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Crest | `crest` | scalar | Weir crest level |
| Width | `width` | scalar | Weir width |
| Height | `height` | scalar | Weir height |
| Gate Height | `gate_height` | scalar | Gated weir field |
| Length | `length` | scalar | Broad-crested geometry field |
| Orientation | `orientation` | scalar | Geometry/orientation field |
| Discharge Coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Reverse Gate Discharge Coefficient | `reverse_gate_discharge_coeff` | scalar | Hydraulic parameter |
| Secondary Discharge Coefficient | `secondary_discharge_coeff` | scalar | Hydraulic parameter |
| Modular Limit | `modular_limit` | scalar | Hydraulic parameter |
| Notch Height | `notch_height` | scalar | Notch geometry |
| Notch Angle | `notch_angle` | scalar | Notch geometry |
| Notch Width | `notch_width` | scalar | Notch geometry |
| Number of Notches | `number_of_notches` | scalar | Notch count |
| Minimum Crest | `minimum_crest` | scalar | Control field |
| Maximum Crest | `maximum_crest` | scalar | Control field |
| Minimum Opening | `minimum_opening` | scalar | Control field |
| Maximum Opening | `maximum_opening` | scalar | Control field |
| Initial Opening | `initial_opening` | scalar | Control field |
| Positive Speed | `positive_speed` | scalar | Actuation rate field |
| Negative Speed | `negative_speed` | scalar | Actuation rate field |
| Threshold | `threshold` | scalar | Control threshold |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Bridge Family (`hw_bridge`, `hw_bridge_blockage`, `hw_bridge_inlet`, `hw_bridge_opening`, `hw_bridge_outlet`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | `hw_bridge` link identifier |
| Downstream Node ID | `ds_node_id` | scalar | `hw_bridge` link identifier |
| Link Suffix | `link_suffix` | scalar | `hw_bridge` identification suffix |
| Bridge Deck X | `bridge_deck.X` | blob | Bridge deck geometry |
| Bridge Deck Y | `bridge_deck.Y` | blob | Bridge deck geometry |
| Bridge Deck Z | `bridge_deck.Z` | blob | Bridge deck elevation |
| Bridge Deck Roughness N | `bridge_deck.roughness_N` | blob | Bridge deck roughness |
| Bridge Deck Opening ID | `bridge_deck.opening_id` | blob | Bridge deck opening reference |
| Bridge Deck Opening Side | `bridge_deck.opening_side` | blob | Bridge deck opening side |
| Downstream Bridge Section Z | `ds_bridge_section.Z` | blob | Section blob field |
| Upstream Bridge Section Z | `us_bridge_section.Z` | blob | Section blob field |
| Downstream Link Section Z | `ds_link_section.Z` | blob | Section blob field |
| Upstream Link Section Z | `us_link_section.Z` | blob | Section blob field |
| Bridge Upstream Node ID | `bridge_us_node_id` | scalar | Used by blockage/inlet/outlet/opening |
| Bridge Link Suffix | `bridge_link_suffix` | scalar | Used by blockage/inlet/outlet/opening |
| Blockage Proportion | `blockage_proportion` | scalar | `hw_bridge_blockage` flow field |
| Inlet Loss Coefficient | `inlet_loss_coefficient` | scalar | Bridge loss field |
| Outlet Loss Coefficient | `outlet_loss_coefficient` | scalar | Bridge loss field |
| Positive Proportion Change | `positive_prop_change` | scalar | Bridge blockage ramp field |
| Negative Proportion Change | `negative_prop_change` | scalar | Bridge blockage ramp field |
| Equation | `equation` | scalar | Bridge inlet/outlet equation selector |
| Headloss Coefficient | `headloss_coeff` | scalar | Bridge inlet/outlet loss field |
| Outlet Headloss Coefficient | `outlet_headloss_coeff` | scalar | `hw_bridge_inlet` field |
| Reverse Flow Model | `reverse_flow_model` | scalar | Bridge inlet/outlet option |
| Inlet ID | `inlet_id` | scalar | `hw_bridge_opening` field |
| Outlet ID | `outlet_id` | scalar | `hw_bridge_opening` field |
| Inlet Blockage ID | `inlet_blockage_id` | scalar | `hw_bridge_opening` field |
| Outlet Blockage ID | `outlet_blockage_id` | scalar | `hw_bridge_opening` field |
| Pier ID | `piers.id` | blob | `hw_bridge_opening` nested field |
| Pier Offset | `piers.offset` | blob | `hw_bridge_opening` nested field |
| Pier Elevation | `piers.elevation` | blob | `hw_bridge_opening` nested field |
| Pier Width | `piers.width` | blob | `hw_bridge_opening` nested field |
| Pier Roughness N | `piers.roughness_N` | blob | `hw_bridge_opening` nested field |

#### Culvert Inlet (`hw_culvert_inlet`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Invert | `invert` | scalar | Hydraulic geometry field |
| Equation | `equation` | scalar | Culvert equation selector |
| Inlet Type Code | `inlet_type_code` | scalar | Culvert inlet classification |
| K | `k` | scalar | Equation parameter |
| M | `m` | scalar | Equation parameter |
| C | `c` | scalar | Equation parameter |
| Y | `y` | scalar | Equation parameter |
| Headloss Coefficient | `headloss_coeff` | scalar | Hydraulic loss field |
| Reverse Flow Model | `reverse_flow_model` | scalar | Reverse-flow option |
| Outlet Headloss Coefficient | `outlet_headloss_coeff` | scalar | Outlet-side loss field |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Culvert Outlet (`hw_culvert_outlet`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Invert | `invert` | scalar | Hydraulic geometry field |
| Headloss Coefficient | `headloss_coeff` | scalar | Hydraulic loss field |
| Reverse Flow Model | `reverse_flow_model` | scalar | Reverse-flow option |
| Equation | `equation` | scalar | Culvert equation selector |
| Inlet Type Code | `inlet_type_code` | scalar | Culvert outlet classification field |
| K | `k` | scalar | Equation parameter |
| M | `m` | scalar | Equation parameter |
| C | `c` | scalar | Equation parameter |
| Y | `y` | scalar | Equation parameter |
| Inlet Headloss Coefficient | `inlet_headloss_coeff` | scalar | Inlet-side loss field |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Blockage (`hw_blockage`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Length | `length` | scalar | Blockage extent field |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |
| Blockage Type | `blockage_type` | scalar | Blockage classification |
| Blockage Proportion | `blockage_proportion` | scalar | Hydraulic blockage field |
| Inlet Loss Coefficient | `inlet_loss_coefficient` | scalar | Hydraulic loss field |
| Outlet Loss Coefficient | `outlet_loss_coefficient` | scalar | Hydraulic loss field |
| Positive Proportion Change | `positive_prop_change` | scalar | Control/ramp field |
| Negative Proportion Change | `negative_prop_change` | scalar | Control/ramp field |
| Threshold | `threshold` | scalar | Control threshold |
| Asset UID | `asset_uid` | scalar | Asset-management identifier |
| InfoNet ID | `infonet_id` | scalar | Legacy/interchange identifier |

#### Inline Bank (`hw_inline_bank`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Bank X | `bank.X` | blob | Nested bank geometry |
| Bank Y | `bank.Y` | blob | Nested bank geometry |
| Bank Z | `bank.Z` | blob | Nested bank elevation |
| Bank Discharge Coefficient | `bank.discharge_coeff` | blob | Nested bank hydraulic field |
| Bank Modular Ratio | `bank.modular_ratio` | blob | Nested bank hydraulic field |
| Bank RTC Definition | `bank.rtc_definition` | blob | Nested RTC field |
| Zone ID | `zone_id` | scalar | Linked zone |
| Crest | `crest` | scalar | Hydraulic crest field |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Screen (`hw_screen`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Crest | `crest` | scalar | Hydraulic crest field |
| Width | `width` | scalar | Physical geometry field |
| Height | `height` | scalar | Physical geometry field |
| Angle | `angle` | scalar | Screen angle |
| Kirschmer Coefficient | `kirschmer` | scalar | Hydraulic loss field |
| Bar Width | `bar_width` | scalar | Screen geometry field |
| Bar Spacing | `bar_spacing` | scalar | Screen geometry field |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |

#### Sluice (`hw_sluice`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Invert | `invert` | scalar | Hydraulic geometry field |
| Width | `width` | scalar | Physical geometry field |
| Discharge Coefficient | `discharge_coeff` | scalar | Hydraulic parameter |
| Overgate Discharge Coefficient | `overgate_discharge_coeff` | scalar | Hydraulic parameter |
| Secondary Discharge Coefficient | `secondary_discharge_coeff` | scalar | Hydraulic parameter |
| Opening | `opening` | scalar | Gate opening |
| Opening Degrees | `opening_degrees` | scalar | Angular opening field |
| Opening Type | `opening_type` | scalar | Gate control type |
| Minimum Opening | `minimum_opening` | scalar | Operational limit |
| Minimum Opening Degrees | `minimum_opening_deg` | scalar | Operational limit |
| Maximum Opening | `maximum_opening` | scalar | Operational limit |
| Maximum Opening Degrees | `maximum_opening_deg` | scalar | Operational limit |
| Gate Depth | `gate_depth` | scalar | Gate geometry |
| Positive Speed | `positive_speed` | scalar | Opening rate |
| Positive Speed Degrees | `positive_speed_deg` | scalar | Opening rate (degrees) |
| Negative Speed | `negative_speed` | scalar | Closing rate |
| Negative Speed Degrees | `negative_speed_deg` | scalar | Closing rate (degrees) |
| Gate Chord | `gate_chord` | scalar | Gate geometry |
| Gate Radius | `gate_radius` | scalar | Gate geometry |
| Pivot Height | `pivot_height` | scalar | Gate geometry |
| Threshold | `threshold` | scalar | Operational threshold |
| Threshold Degrees | `threshold_degrees` | scalar | Operational threshold (degrees) |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |
| Asset UID | `asset_uid` | scalar | Asset-management key |
| InfoNet ID | `infonet_id` | scalar | Legacy asset key |

#### User Control (`hw_user_control`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Upstream Node ID | `us_node_id` | scalar | Common link identifier |
| Downstream Node ID | `ds_node_id` | scalar | Common link identifier |
| Link Suffix | `link_suffix` | scalar | Identification suffix |
| Link Type | `link_type` | scalar | Link classification |
| System Type | `system_type` | scalar | System classification |
| Asset ID | `asset_id` | scalar | Asset reference field |
| Sewer Reference | `sewer_reference` | scalar | Asset/reference field |
| Start Level | `start_level` | scalar | Control field |
| Head Discharge ID | `head_discharge_id` | scalar | Linked head-discharge table |
| Modular Limit | `modular_limit` | scalar | Hydraulic parameter |
| Upstream Settlement Efficiency | `us_settlement_eff` | scalar | Settlement parameter |
| Downstream Settlement Efficiency | `ds_settlement_eff` | scalar | Settlement parameter |
| Branch ID | `branch_id` | scalar | Branch/control field |
| Asset UID | `asset_uid` | scalar | Asset-management key |
| InfoNet ID | `infonet_id` | scalar | Legacy asset key |

#### Sediment Grading (`hw_sediment_grading`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Grading ID | `grading_id` | scalar | Sediment grading identifier |
| Grading Type | `grading_type` | scalar | Sediment grading type |
| SF1 Weight | `sf1_weight` | scalar | Sediment fraction weight |
| SF2 Weight | `sf2_weight` | scalar | Sediment fraction weight |

#### River Reach (`hw_river_reach`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Left Bank Discharge Coefficient | `left_bank.discharge_coeff` | nested | Nested sub-object — use dot notation |
| Left Bank Modular Limit / Ratio | `left_bank.modular_ratio` | nested | Nested sub-object — use dot notation |
| Right Bank Discharge Coefficient | `right_bank.discharge_coeff` | nested | Nested sub-object — use dot notation |
| Right Bank Modular Limit / Ratio | `right_bank.modular_ratio` | nested | Nested sub-object — use dot notation |
| Section Key | `sections.key` | blob | River cross-section blob field |
| Section Level / Elevation | `sections.z` | blob | Used for river bed level summaries |
| Profile Roughness N | `profile.roughness_N` | blob | Channel/profile roughness field |
| Profile Roughness Manning | `profile.roughness_Manning` | blob | Channel/profile roughness field |

**High-risk object:** Never use `left_bank_discharge_coeff`. Use `left_bank.discharge_coeff` (dot notation required).

### Subcatchments

#### Subcatchment (`hw_subcatchment`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Subcatchment ID | `subcatchment_id` | scalar | |
| System Type | `system_type` | scalar | 'foul', 'storm', 'combined' |
| Node ID | `node_id` | scalar | Primary receiving node; use `drains_to` for routing selector |
| Link Suffix | `link_suffix` | scalar | Receiving link suffix |
| Drains To | `drains_to` | scalar | Routing selector: 'node', 'subcatchment', '2d' |
| To Subcatchment ID | `to_subcatchment_id` | scalar | Subcatchment-to-subcatchment routing |
| 2D Point ID | `2d_pt_id` | scalar | Linked 2D point for 2D routing |
| Contributing Area | `contributing_area` | scalar | InfoWorks area field; NOT `area` |
| Total Area | `total_area` | scalar |  |
| Capacity Limit | `capacity_limit` | scalar |  |
| Exceed Flow Type | `exceed_flow_type` | scalar | behaviour when capacity exceeded |
| X Coordinate | `x` | scalar |  |
| Y Coordinate | `y` | scalar |  |
| Catchment Slope | `catchment_slope` | scalar |  |
| Soil Class | `soil_class` | scalar |  |
| Soil Class Type | `soil_class_type` | scalar |  |
| Soil Class Host | `soil_class_host` | scalar |  |
| Max Soil Moisture Capacity | `max_soil_moisture_capacity` | scalar |  |
| Curve Number | `curve_number` | scalar | CN infiltration field |
| Drying Time | `drying_time` | scalar | Infiltration parameter |
| UKWIR Soil Runoff | `ukwir_soil_runoff` | scalar |  |
| Rainfall Profile | `rainfall_profile` | scalar | Linked rainfall profile |
| Evaporation Profile | `evaporation_profile` | scalar | Linked evaporation profile |
| Area Average Rain | `area_average_rain` | scalar |  |
| Catchment Dimension | `catchment_dimension` | scalar |  |
| Unit Hydrograph ID | `unit_hydrograph_id` | scalar | Linked RTK/UH table |
| Snow Pack ID | `snow_pack_id` | scalar | Linked snow pack |
| Baseflow Calculation | `baseflow_calc` | scalar |  |
| Soil Moisture Deficit | `soil_moist_def` | scalar |  |
| Wastewater Profile | `wastewater_profile` | scalar | DWF foul-flow profile |
| Population | `population` | scalar | Population-based foul flow |
| Trade Flow | `trade_flow` | scalar | Trade effluent flow |
| Additional Foul Flow | `additional_foul_flow` | scalar | Additional DWF |
| Base Flow | `base_flow` | scalar | Base/dry weather flow |
| Trade Profile | `trade_profile` | scalar | Linked trade profile |
| Ground ID | `ground_id` | scalar | Linked ground infiltration table |
| Ground Node | `ground_node` | scalar |  |
| Baseflow Lag | `baseflow_lag` | scalar |  |
| Baseflow Recharge | `baseflow_recharge` | scalar |  |
| Land Use ID | `land_use_id` | scalar | Linked land use table |
| PDM Descriptor ID | `pdm_descriptor_id` | scalar | Linked PDM descriptor |
| Area Measurement Type | `area_measurement_type` | scalar | Area type selector |
| Area Absolute 1–12 | `area_absolute_1` to `area_absolute_12` | scalar | Absolute surface area splits |
| Area Percent 1–12 | `area_percent_1` to `area_percent_12` | scalar | Percentage surface area splits |
| TC Method | `tc_method` | scalar | Time-of-concentration method |
| Time of Concentration | `time_of_concentration` | scalar | TC value |
| Overland Flow Time | `overland_flow_time` | scalar |  |
| Equivalent Roughness | `equivalent_roughness` | scalar |  |
| Hydraulic Radius | `hydraulic_radius` | scalar |  |
| PWRI Coefficient | `pwri_coefficient` | scalar |  |
| Time to Peak | `time_to_peak` | scalar |  |
| Base Time | `base_time` | scalar |  |
| Lag Time | `lag_time` | scalar |  |
| Peaking Coefficient | `peaking_coeff` | scalar |  |
| UH Peak | `uh_peak` | scalar |  |
| UH Kink | `uh_kink` | scalar |  |
| Storage Factor | `storage_factor` | scalar |  |
| Storage Exponent | `storage_exponent` | scalar |  |
| Internal Routing | `internal_routing` | scalar |  |
| Percent Routed | `percent_routed` | scalar |  |
| Degree Urbanisation | `degree_urbanisation` | scalar | RAFTS field |
| RAFTS Adaptation Factor | `rafts_adapt_factor` | scalar | RAFTS field |
| RAFTS b | `rafts_b` | scalar | RAFTS field |
| RAFTS n | `rafts_n` | scalar | RAFTS field |
| SRM Runoff Coefficient | `srm_runoff_coeff` | scalar |  |
| ARMA ID | `arma_id` | scalar | Linked ARMA object |
| Output Lag | `output_lag` | scalar |  |
| Bypass Runoff | `bypass_runoff` | scalar |  |
| UH Definition | `uh_definition` | scalar |  |
| Connectivity | `connectivity` | scalar | Land-use connectivity |
| Lateral Links | `lateral_links` | blob | Sub-fields: `.node_id`, `.link_suffix`, `.weight` |
| ReFH Descriptors | `refh_descriptors` | blob | ReFH2 calibration descriptors blob |
| SWMM Coverage | `swmm_coverage` | blob | Sub-fields: `.land_use`, `.area` |
| Boundary Array | `boundary_array` | blob | Subcatchment polygon geometry |

> Common data fields (`user_text_1`–`10`, `user_number_1`–`10`, `notes`, `hyperlinks`) apply to this object — see `Schema_Common.md`.

#### Subcatchment SuDS Controls (`hw_suds_control`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| SuDS Structure | `suds_controls.suds_structure` | blob | Nested SuDS control field |
| SuDS Control ID | `suds_controls.id` | blob | Nested SuDS control identifier |
| Area | `suds_controls.area` | blob | Nested SuDS area field |
| Number of Units | `suds_controls.num_units` | blob | Nested SuDS count field |
| Impervious Area Treated % | `suds_controls.impervious_area_treated_pct` | blob | Nested percentage field |
| Pervious Area Treated % | `suds_controls.pervious_area_treated_pct` | blob | Nested percentage field |
| Outflow To | `suds_controls.outflow_to` | blob | Nested routing field |
| Surface | `suds_controls.surface` | blob | Nested surface field |

#### Runoff Surface (`hw_runoff_surface`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Runoff Index | `runoff_index` | scalar | Runoff surface identifier |
| Surface Description | `surface_description` | scalar | Descriptive field |
| Runoff Routing Type | `runoff_routing_type` | scalar | Routing selector |
| Runoff Routing Value | `runoff_routing_value` | scalar | Routing parameter |
| Runoff Volume Type | `runoff_volume_type` | scalar | Volume calculation selector |
| Surface Type | `surface_type` | scalar | Surface classification |
| Ground Slope | `ground_slope` | scalar | Surface slope field |
| Initial Loss Type | `initial_loss_type` | scalar | Initial-loss selector |
| Initial Loss Value | `initial_loss_value` | scalar | Initial-loss parameter |
| Initial Abstraction Factor | `initial_abstraction_factor` | scalar | Initial abstraction parameter |
| Routing Model | `routing_model` | scalar | Routing-model selector |
| Runoff Coefficient | `runoff_coefficient` | scalar | Hydraulic parameter |
| Minimum Runoff | `minimum_runoff` | scalar | Hydraulic parameter |
| Maximum Runoff | `maximum_runoff` | scalar | Hydraulic parameter |
| Equivalent Roughness | `equivalent_roughness` | scalar | Roughness field |
| Runoff Distribution Factor | `runoff_distribution_factor` | scalar | Distribution field |
| Moisture Depth Parameter | `moisture_depth_parameter` | scalar | Soil moisture field |
| Storage Depth | `storage_depth` | scalar | Surface storage field |
| Initial Infiltration | `initial_infiltration` | scalar | Horton/soil infiltration field |
| Limiting Infiltration | `limiting_infiltration` | scalar | Horton/soil infiltration field |
| Decay Factor | `decay_factor` | scalar | Infiltration decay field |
| Drying Time | `drying_time` | scalar | Infiltration drying field |
| Max Infiltration Volume | `max_infiltration_volume` | scalar | Infiltration volume limit |
| Recovery Factor | `recovery_factor` | scalar | Recovery parameter |
| Depression Loss | `depression_loss` | scalar | Surface-loss parameter |
| Average Capillary Suction | `average_capillary_suction` | scalar | Green-Ampt field |
| Saturated Hydraulic Conductivity | `saturated_hydraulic_conductivity` | scalar | Green-Ampt field |
| Initial Moisture Deficit | `initial_moisture_deficit` | scalar | Green-Ampt field |
| Effective Impermeability | `effective_impermeability` | scalar | Surface field |
| Precipitation Decay | `precipitation_decay` | scalar | Rainfall-decay field |

#### Land Use (`hw_land_use`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Land Use ID | `land_use_id` | scalar | Land use identifier |
| Population Density | `population_density` | scalar | Population/wastewater field |
| Wastewater Profile | `wastewater_profile` | scalar | Profile link field |
| Connectivity | `connectivity` | scalar | Land-use connectivity |
| Pollution Index | `pollution_index` | scalar | Pollution field |
| Land Use Description | `land_use_description` | scalar | Descriptive field |
| Runoff Index 1 | `runoff_index_1` | scalar | Surface mapping field |
| Area Percentage 1 | `p_area_1` | scalar | Surface area split |
| Runoff Index 2 | `runoff_index_2` | scalar | Surface mapping field |
| Area Percentage 2 | `p_area_2` | scalar | Surface area split |
| Runoff Index 3 | `runoff_index_3` | scalar | Surface mapping field |
| Area Percentage 3 | `p_area_3` | scalar | Surface area split |
| Runoff Index 4 | `runoff_index_4` | scalar | Surface mapping field |
| Area Percentage 4 | `p_area_4` | scalar | Surface area split |
| Runoff Index 5 | `runoff_index_5` | scalar | Surface mapping field |
| Area Percentage 5 | `p_area_5` | scalar | Surface area split |
| Runoff Index 6 | `runoff_index_6` | scalar | Surface mapping field |
| Area Percentage 6 | `p_area_6` | scalar | Surface area split |
| Runoff Index 7 | `runoff_index_7` | scalar | Surface mapping field |
| Area Percentage 7 | `p_area_7` | scalar | Surface area split |
| Runoff Index 8 | `runoff_index_8` | scalar | Surface mapping field |
| Area Percentage 8 | `p_area_8` | scalar | Surface area split |
| Runoff Index 9 | `runoff_index_9` | scalar | Surface mapping field |
| Area Percentage 9 | `p_area_9` | scalar | Surface area split |
| Runoff Index 10 | `runoff_index_10` | scalar | Surface mapping field |
| Area Percentage 10 | `p_area_10` | scalar | Surface area split |
| Runoff Index 11 | `runoff_index_11` | scalar | Surface mapping field |
| Area Percentage 11 | `p_area_11` | scalar | Surface area split |
| Runoff Index 12 | `runoff_index_12` | scalar | Surface mapping field |
| Area Percentage 12 | `p_area_12` | scalar | Surface area split |

#### Snow Pack (`hw_snow_pack`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `ID` | scalar | Snow pack identifier — note uppercase |
| Fraction Ploughable | `fraction_ploughable` | scalar | Snow routing field |
| Plough Snow Depth | `plough_snow_depth` | scalar | Snow state field |
| Impervious Snow Depth | `imp_snow_depth` | scalar | Snow state field |
| Pervious Snow Depth | `perv_snow_depth` | scalar | Snow state field |
| Plough Minimum Melt | `plough_min_melt` | scalar | Melt parameter |
| Impervious Minimum Melt | `imp_min_melt` | scalar | Melt parameter |
| Pervious Minimum Melt | `perv_min_melt` | scalar | Melt parameter |
| Plough Maximum Melt | `plough_max_melt` | scalar | Melt parameter |
| Impervious Maximum Melt | `imp_max_melt` | scalar | Melt parameter |
| Pervious Maximum Melt | `perv_max_melt` | scalar | Melt parameter |
| Plough Base Temperature | `plough_base_temp` | scalar | Temperature parameter |
| Impervious Base Temperature | `imp_base_temp` | scalar | Temperature parameter |
| Pervious Base Temperature | `perv_base_temp` | scalar | Temperature parameter |
| Plough Free Water | `plough_free_water` | scalar | Water content parameter |
| Impervious Free Water | `imp_free_water` | scalar | Water content parameter |
| Pervious Free Water | `perv_free_water` | scalar | Water content parameter |
| Plough Depth | `plough_depth` | scalar | Snow depth/routing field |
| Out of Watershed | `out_of_watershed` | scalar | Routing field |
| To Impervious | `to_impervious` | scalar | Routing fraction |
| To Pervious | `to_pervious` | scalar | Routing fraction |
| To Immediate Melt | `to_immediate_melt` | scalar | Routing fraction |
| To Subcatchment | `to_subcatchment` | scalar | Routing fraction |
| Subcatchment ID | `subcatchment_id` | scalar | Linked subcatchment |

#### Ground Infiltration (`hw_ground_infiltration`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Ground ID | `ground_id` | scalar | Ground infiltration identifier |
| Soil Depth | `soil_depth` | scalar | Soil property |
| Percolation Coefficient | `percolation_coefficient` | scalar | Percolation field |
| Baseflow Coefficient | `baseflow_coefficient` | scalar | Baseflow field |
| Infiltration Coefficient | `infiltration_coefficient` | scalar | Infiltration field |
| Percolation Threshold | `percolation_threshold` | scalar | Threshold field |
| Percolation Percentage | `percolation_percentage` | scalar | Percentage field |
| Soil Porosity | `soil_porosity` | scalar | Soil property |
| Ground Porosity | `ground_porosity` | scalar | Ground property |
| Baseflow Threshold | `baseflow_threshold` | scalar | Threshold field |
| Baseflow Threshold Type | `baseflow_threshold_type` | scalar | Threshold type |
| Infiltration Threshold | `infiltration_threshold` | scalar | Threshold field |
| Infiltration Threshold Type | `infiltration_threshold_type` | scalar | Threshold type |
| Evapotranspiration Type | `evapotranspiration_type` | scalar | ET selector |
| Evapotranspiration Depth | `evapotranspiration_depth` | scalar | ET depth field |
| ET Factor January | `evapotranspiration_fac_Jan` | scalar | Monthly ET factor |
| ET Factor February | `evapotranspiration_fac_Feb` | scalar | Monthly ET factor |
| ET Factor March | `evapotranspiration_fac_Mar` | scalar | Monthly ET factor |
| ET Factor April | `evapotranspiration_fac_Apr` | scalar | Monthly ET factor |
| ET Factor May | `evapotranspiration_fac_May` | scalar | Monthly ET factor |
| ET Factor June | `evapotranspiration_fac_Jun` | scalar | Monthly ET factor |
| ET Factor July | `evapotranspiration_fac_Jul` | scalar | Monthly ET factor |
| ET Factor August | `evapotranspiration_fac_Aug` | scalar | Monthly ET factor |
| ET Factor September | `evapotranspiration_fac_Sep` | scalar | Monthly ET factor |
| ET Factor October | `evapotranspiration_fac_Oct` | scalar | Monthly ET factor |
| ET Factor November | `evapotranspiration_fac_Nov` | scalar | Monthly ET factor |
| ET Factor December | `evapotranspiration_fac_Dec` | scalar | Monthly ET factor |

#### RTK Hydrograph (`hw_unit_hydrograph`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `ID` | scalar | RTK hydrograph identifier — note uppercase |
| R1 | `R1` | scalar | Component 1 attenuation ratio |
| T1 | `T1` | scalar | Component 1 time to peak |
| K1 | `K1` | scalar | Component 1 recession constant |
| R2 | `R2` | scalar | Component 2 attenuation ratio |
| T2 | `T2` | scalar | Component 2 time to peak |
| K2 | `K2` | scalar | Component 2 recession constant |
| R3 | `R3` | scalar | Component 3 attenuation ratio |
| T3 | `T3` | scalar | Component 3 time to peak |
| K3 | `K3` | scalar | Component 3 recession constant |
| Dmax1 | `Dmax1` | scalar | Component 1 maximum depth |
| Drec1 | `Drec1` | scalar | Component 1 recovery depth |
| D01 | `D01` | scalar | Component 1 initial depth |
| Dmax2 | `Dmax2` | scalar | Component 2 maximum depth |
| Drec2 | `Drec2` | scalar | Component 2 recovery depth |
| D02 | `D02` | scalar | Component 2 initial depth |
| Dmax3 | `Dmax3` | scalar | Component 3 maximum depth |
| Drec3 | `Drec3` | scalar | Component 3 recovery depth |
| D03 | `D03` | scalar | Component 3 initial depth |

#### Monthly RTK Hydrograph (`hw_unit_hydrograph_month`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `ID` | scalar | Monthly RTK identifier — note uppercase |
| Month | `Month` | scalar | Month selector — note uppercase |
| R1 | `R1` | scalar | RTK parameter |
| T1 | `T1` | scalar | RTK parameter |
| K1 | `K1` | scalar | RTK parameter |
| R2 | `R2` | scalar | RTK parameter |
| T2 | `T2` | scalar | RTK parameter |
| K2 | `K2` | scalar | RTK parameter |
| R3 | `R3` | scalar | RTK parameter |
| T3 | `T3` | scalar | RTK parameter |
| K3 | `K3` | scalar | RTK parameter |

#### PDM Descriptor (`hw_pdm_descriptor`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Descriptor ID | `descriptor_id` | scalar | PDM descriptor identifier |
| RE Type | `re_type` | scalar | Descriptor field |
| Rainfall Factor | `rainfac` | scalar | Calibration field |
| Rainfall Factor Cal Step | `rainfac_cal_step` | scalar | Calibration field |
| Rainfall Factor Cal Tolerance | `rainfac_cal_tol` | scalar | Calibration field |
| Rainfall Factor Cal Min | `rainfac_cal_min` | scalar | Calibration field |
| Rainfall Factor Cal Max | `rainfac_cal_max` | scalar | Calibration field |
| Cmin | `cmin` | scalar | PDM calibration field |
| Cmax | `cmax` | scalar | PDM calibration field |
| B | `b` | scalar | PDM calibration field |
| BE | `be` | scalar | PDM calibration field |
| K1 | `k1` | scalar | PDM calibration field |
| K2 | `k2` | scalar | PDM calibration field |
| KB | `kb` | scalar | PDM calibration field |
| KG | `kg` | scalar | PDM calibration field |
| St | `St` | scalar | PDM calibration field |
| BG | `bg` | scalar | PDM calibration field |
| Alpha D | `alpha_d` | scalar | PDM calibration field |

#### Build-Up/Washoff Land Use (`hw_swmm_land_use`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| ID | `id` | scalar | Build-up/washoff land use identifier |
| Sweep Interval | `sweep_interval` | scalar | Surface sweeping interval |
| Sweep Removal | `sweep_removal` | scalar | Sweeping removal fraction |
| Build Up Determinant | `build_up.determinant` | blob | Build-up blob field |
| Build Up Type | `build_up.build_up_type` | blob | Build-up blob field |
| Build Up Max Build Up | `build_up.max_build_up` | blob | Build-up blob field |
| Build Up Power Rate Constant | `build_up.power_rate_constant` | blob | Build-up blob field |
| Build Up Power Time Exponent | `build_up.power_time_exponent` | blob | Build-up blob field |
| Build Up Exp Rate Constant | `build_up.exp_rate_constant` | blob | Build-up blob field |
| Build Up Saturation Constant | `build_up.saturation_constant` | blob | Build-up blob field |
| Washoff Determinant | `washoff.determinant` | blob | Washoff blob field |
| Washoff Type | `washoff.washoff_type` | blob | Washoff blob field |
| Washoff Exponential Coefficient | `washoff.exponential_washoff_coeff` | blob | Washoff blob field |
| Washoff Rating Coefficient | `washoff.rating_washoff_coeff` | blob | Washoff blob field |
| Washoff EMC Coefficient | `washoff.emc_washoff_coeff` | blob | Washoff blob field |
| Washoff Exponent | `washoff.washoff_exponent` | blob | Washoff blob field |
| Washoff Sweep Removal | `washoff.sweep_removal` | blob | Washoff blob field |
| Washoff BMP Removal | `washoff.bmp_removal` | blob | Washoff blob field |

### Polygons and 2D Objects

#### Polygon and Storage Area (`hw_polygon`, `hw_storage_area`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Polygon ID | `polygon_id` | scalar | Use with `hw_polygon` and `hw_storage_area` |
| Polygon Category ID | `category_id` | scalar | Use with `hw_polygon` |
| Polygon Area | `area` | scalar | Polygon/storage area field |
| Polygon Boundary | `boundary_array` | blob | Polygon geometry field |
| Storage Area Node ID | `node_id` | scalar | Linked storage node |

#### 2D Zone (`hw_2d_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Zone ID | `zone_id` | scalar | 2D zone identifier |
| Boundary Type | `boundary_type` | scalar | 2D boundary selector |
| Area | `area` | scalar | Zone area field |
| Maximum Triangle Area | `max_triangle_area` | scalar | Mesh control field |
| Minimum Mesh Element Area | `min_mesh_element_area` | scalar | Mesh control field |
| Roughness | `roughness` | scalar | 2D roughness value |
| Roughness Definition ID | `roughness_definition_id` | scalar | Links to `hw_roughness_definition` |
| Rainfall Profile | `rainfall_profile` | scalar | Rainfall assignment field |
| Infiltration Surface ID | `infiltration_surface_id` | scalar | Links to `hw_2d_infil_surface` |
| Turbulence Model ID | `turbulence_model_id` | scalar | Links to `hw_2d_turbulence_model` |
| Rainfall Percentage | `rainfall_percentage` | scalar | Rainfall scaling field |

#### Mesh and Roughness Support (`hw_mesh_zone`, `hw_mesh_level_zone`, `hw_roughness_zone`, `hw_roughness_definition`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Mesh Zone Polygon ID | `polygon_id` | scalar | Use with `hw_mesh_zone` |
| Mesh Zone Max Triangle Area | `max_triangle_area` | scalar | Mesh control field |
| Mesh Zone Min Mesh Element Area | `min_mesh_element_area` | scalar | Mesh control field |
| Mesh Level Type | `level_type` | scalar | Use with `hw_mesh_level_zone` |
| Mesh Upper Limit Level | `upper_limit_level` | scalar | Level cap |
| Mesh Lower Limit Level | `lower_limit_level` | scalar | Level floor |
| Mesh Level Section Elevation | `level_sections.elevation` | blob | Nested mesh-level section field |
| Roughness Zone Exclude From 2D Mesh | `exclude_from_2d_mesh` | scalar | Use with `hw_roughness_zone` |
| Roughness Zone Roughness | `roughness` | scalar | Roughness value |
| Roughness Zone Definition ID | `roughness_definition_id` | scalar | Linked definition |
| Roughness Zone Priority | `priority` | scalar | Override priority |
| Roughness Definition ID | `definition_id` | scalar | Use with `hw_roughness_definition` |
| Roughness Definition Bands | `number_of_bands` | scalar | Band count |
| Roughness Band 1 | `roughness_1` | scalar | Banded roughness field |
| Roughness Band 1 Depth Threshold | `depth_thld_1` | scalar | Band depth threshold |

#### 2D IC Polygons (`hw_2d_ic_polygon`, `hw_2d_wq_ic_polygon`, `hw_2d_inf_ic_polygon`, `hw_2d_sed_ic_polygon`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Polygon ID | `polygon_id` | scalar | Shared IC polygon identifier |
| Area | `area` | scalar | IC polygon area |
| Boundary | `boundary_array` | blob | Polygon geometry field |

#### Infiltration and Turbulence Support (`hw_2d_infil_surface`, `hw_2d_infiltration_zone`, `hw_2d_turbulence_model`, `hw_2d_turbulence_zone`, `hw_2d_permeable_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Infiltration Surface ID | `surface_id` | scalar | Use with `hw_2d_infil_surface` |
| Runoff Volume Type | `runoff_volume_type` | scalar | Infiltration method selector |
| Initial Infiltration | `initial_infiltration` | scalar | Horton/soil infiltration |
| Limiting Infiltration | `limiting_infiltration` | scalar | Horton/soil infiltration |
| Decay Factor | `decay_factor` | scalar | Horton decay field |
| Recovery Factor | `recovery_factor` | scalar | Recovery parameter |
| Saturated Hydraulic Conductivity | `saturated_hydraulic_conductivity` | scalar | Green-Ampt field |
| Infiltration Zone Surface ID | `infiltration_surface_id` | scalar | Use with `hw_2d_infiltration_zone` |
| Infiltration Zone Rainfall Percentage | `rainfall_percentage` | scalar | Rainfall scaling field |
| Turbulence Model ID | `model_id` | scalar | Use with `hw_2d_turbulence_model` |
| Constant Eddy Viscosity | `const_eddy_visc` | scalar | Turbulence parameter |
| Vertical Eddy Viscosity Equation | `vert_eddy_visc_equn` | scalar | Solver option |
| Turbulence Zone Model ID | `turbulence_model_id` | scalar | Use with `hw_2d_turbulence_zone` |
| Permeable Zone Drains To | `drains_to` | scalar | Use with `hw_2d_permeable_zone` |
| Permeable Zone Node ID | `node_id` | scalar | Linked node |
| Permeable Zone Lateral Link Weight | `lateral_links.weight` | blob | Nested routing field |

#### TVD, Spatial Rain, and ARMA (`hw_tvd_connector`, `hw_spatial_rain_zone`, `hw_spatial_rain_source`, `hw_arma`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| TVD Connector ID | `id` | scalar | Use with `hw_tvd_connector` |
| TVD Category ID | `category_id` | scalar | Category field |
| Input A | `input_a` | scalar | Expression input |
| Input B | `input_b` | scalar | Expression input |
| Input C | `input_c` | scalar | Expression input |
| Output Expression | `output_expression` | scalar | Expression text |
| Connected Object Type | `connected_object_type` | scalar | Link target type |
| Connected Object ID | `connected_object_id` | scalar | Link target ID |
| Spatial Rain Zone Boundary | `boundary_array` | blob | Use with `hw_spatial_rain_zone` |
| Spatial Rain Source Type | `source_type` | scalar | Use with `hw_spatial_rain_source` |
| Spatial Rain Source Category | `stream_or_category` | scalar | Data-stream/category field |
| Spatial Rain Source Start Time | `start_time` | scalar | Temporal field |
| Spatial Rain Source End Time | `end_time` | scalar | Temporal field |
| ARMA Type | `arma_type` | scalar | Use with `hw_arma` |
| ARMA Error Calculation | `error_calc` | scalar | ARMA option |

#### Porous and Building Objects (`hw_porous_polygon`, `hw_porous_wall`, `hw_building`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Porous Polygon Porosity | `porosity` | scalar | Use with `hw_porous_polygon` |
| Porous Polygon Crest Level | `crest_level` | scalar | Structure elevation |
| Porous Polygon Height | `height` | scalar | Structure height |
| Porous Polygon Remove Wall | `remove_wall` | scalar | Trigger flag |
| Porous Wall Wall Removal Trigger | `wall_removal_trigger` | scalar | Use with `hw_porous_wall` |
| Porous Wall Depth Threshold | `depth_threshold` | scalar | Trigger threshold |
| Porous Wall Velocity Threshold | `velocity_threshold` | scalar | Trigger threshold |
| Building ID | `building_id` | scalar | Use with `hw_building` |
| Building Drains To | `drains_to` | scalar | Routing selector |
| Building Node ID | `node_id` | scalar | Linked node |
| Building 2D Point ID | `2d_pt_id` | scalar | Linked 2D point |
| Building Capacity Limit | `capacity_limit` | scalar | Capacity field |
| Building Total Area | `total_area` | scalar | Building total area |
| Building Contributing Area | `contributing_area` | scalar | Contributing area |
| Building SuDS Control ID | `suds_controls.id` | blob | Nested SuDS field |
| Building Roughness Definition ID | `roughness_definition_id` | scalar | Linked roughness definition |

### Lines

#### General Line (`hw_general_line`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Line ID | `line_id` | scalar | General line identifier |
| Asset ID | `asset_id` | scalar | Asset reference |
| Line Geometry | `general_line_xy` | blob | Geometry blob field |
| Category | `category` | scalar | Category field |
| Length | `length` | scalar | Line length |

#### Cross Section Line (`hw_cross_section_survey`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Cross Section ID | `id` | scalar | Cross-section identifier |
| Length | `length` | scalar | Cross-section line length |
| Section X | `section_array.X` | blob | Nested section geometry |
| Section Y | `section_array.Y` | blob | Nested section geometry |
| Section Z | `section_array.Z` | blob | Nested section elevation |
| Section Roughness N | `section_array.roughness_N` | blob | Nested roughness field |
| Section New Panel | `section_array.new_panel` | blob | Nested panel-break field |

#### Bank Line (`hw_bank_survey`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Bank Survey ID | `id` | scalar | Bank survey identifier |
| Length | `length` | scalar | Bank line length |
| Bank X | `bank_array.X` | blob | Nested bank geometry |
| Bank Y | `bank_array.Y` | blob | Nested bank geometry |
| Bank Z | `bank_array.Z` | blob | Nested bank elevation |
| Bank Discharge Coefficient | `bank_array.discharge_coeff` | blob | Nested bank hydraulic field |
| Bank Modular Ratio | `bank_array.modular_ratio` | blob | Nested bank hydraulic field |
| Bank RTC Definition | `bank_array.rtc_definition` | blob | Nested RTC field |

#### 2D Line Connect (`hw_2d_connect_line`)

**Note:** The Autodesk Help manifest entry lists this as `hv_2d_line_connect`, but repository-local inventories and theme files consistently use `hw_2d_connect_line`. Use `hw_2d_connect_line` in queries.

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Line ID | `line_id` | scalar | 2D connect line identifier |
| Length | `length` | scalar | Connector line length |
| Line Geometry | `general_line_xy` | blob | Connector geometry blob |

#### 2D Linear Structures and Boundaries (`hw_2d_linear_structure`, `hw_2d_sluice`, `hw_2d_bridge`, `hw_2d_boundary_line`, `hw_head_unit_discharge`, `hw_2d_line_source`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| Linear Structure Line ID | `line_id` | scalar | Use with `hw_2d_linear_structure` |
| Linear Structure Type | `structure_type` | scalar | Structure classification |
| Linear Structure Crest Level | `crest_level` | scalar | Structure elevation |
| Linear Structure Head Unit Discharge ID | `head_unit_discharge_id` | scalar | Linked flow table |
| Linear Structure Blockage | `blockage` | scalar | Blockage field |
| Linear Structure Headloss Type | `headloss_type` | scalar | Loss model selector |
| Sluice Opening | `opening` | scalar | Use with `hw_2d_sluice` |
| Sluice Gate Depth | `gate_depth` | scalar | Gate geometry |
| Sluice Flow Type | `flow_type` | scalar | Flow regime selector |
| Bridge Linear Structure ID | `linear_structure_id` | scalar | Use with `hw_2d_bridge` |
| Bridge Offset Section Elevation | `off_sections.Z` | blob | Nested section field |
| Bridge Section Opening | `sections.opening` | blob | Nested section field |
| Boundary Line Type | `line_type` | scalar | Use with `hw_2d_boundary_line` |
| Boundary Head Unit Discharge ID | `head_unit_discharge_id` | scalar | Linked flow table |
| Head Unit Discharge Description | `head_unit_discharge_description` | scalar | Use with `hw_head_unit_discharge` |
| Head Unit Discharge Head | `HUDP_table.head` | blob | Nested table field |
| Head Unit Discharge Value | `HUDP_table.unit_discharge` | blob | Nested table field |

### Points

#### Results and Point Objects (`hw_general_point`, `hw_2d_point_source`, `hw_1d_results_point`, `hw_2d_results_point`, `hw_2d_results_line`, `hw_2d_results_polygon`, `hw_damage_receptor`, `hw_risk_impact_zone`)

| UI Label | Database Field | Type | Notes |
|----------|----------------|------|-------|
| General Point ID | `point_id` | scalar | Use with `hw_general_point` |
| General Point X | `general_point_x` | scalar | X coordinate |
| General Point Y | `general_point_y` | scalar | Y coordinate |
| 2D Point Source X | `x` | scalar | Use with `hw_2d_point_source` |
| 2D Point Source Y | `y` | scalar | Use with `hw_2d_point_source` |
| 1D Results Point Opening ID | `opening_id` | scalar | Use with `hw_1d_results_point` |
| 1D Results Point Start Length | `start_length` | scalar | Local chainage |
| 2D Results Point X | `point_x` | scalar | Use with `hw_2d_results_point` |
| 2D Results Point Y | `point_y` | scalar | Use with `hw_2d_results_point` |
| Results Line ID | `line_id` | scalar | Use with `hw_2d_results_line` |
| Results Line Geometry | `line_xy` | blob | Results line geometry |
| Results Polygon ID | `polygon_id` | scalar | Use with `hw_2d_results_polygon` |
| Results Polygon Area | `area` | scalar | Results polygon area |
| Damage Receptor Floor Level | `floor_level` | scalar | Use with `hw_damage_receptor` |
| Damage Receptor Value | `value` | scalar | Damage valuation field |
| Risk Impact Zone Category ID | `category_id` | scalar | Use with `hw_risk_impact_zone` |

---

## Simulation Results

Result fields use `tsr.ATTRIBUTE` syntax. See `InfoWorks_ICM_SQL_Schema_Common.md` for `tsr.*` metadata fields.

### Summary Results (`sim.*`)

The `sim.*` prefix returns summary results at the current timestep or maximum. No aggregate function is needed.

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Downstream Depth | `sim.ds_depth` | result | InfoWorks link result |
| Downstream Flow | `sim.ds_flow` | result | InfoWorks link result |
| Maximum Surcharge | `sim.max_Surcharge` | result | Case-sensitive as shown |
| Peak Catchment Flow | `sim.max_qcatch` | result | InfoWorks subcatchment |

**Do not assume a `sim.*` suffix from one network type will work in the other.** SWMM-specific `sim.*` fields are in `Schema_SWMM.md`.

---

### Water Quality Field Naming Conventions

WQ result fields throughout this section use substitution tokens in their names. Replace each token to form the actual field name.

#### Token: `<PPP>` — Determinant code

The three-letter determinant code, **uppercase** when constructing field names.

| Code | Name | Description | Dissolved | Attached (SF1/SF2) |
|------|------|-------------|-----------|---------------------|
| `BOD` | Biological Oxygen Demand | Oxygen consumed by organic decay | ✓ | ✓ |
| `COD` | Chemical Oxygen Demand | Oxygen equivalent for chemical oxidation; substitute for BOD | ✓ | ✓ |
| `TKN` | Total Kjeldahl Nitrogen | Organic N + NH3 + NH4; part of DO process | ✓ | ✓ |
| `NH4` | Ammoniacal Nitrogen | NH3 + NH4; part of DO process | ✓ | — |
| `TPH` | Total Phosphorus | All phosphorus forms; nutrient for algae/macrophytes | ✓ | ✓ |
| `PL1`–`PL4` | User Determinant 1–4 | User-defined determinants | ✓ | ✓ |
| `DO` | Dissolved Oxygen | Oxygen balance; requires BOD or COD | ✓ | — |
| `NO2` | Nitrite | Part of DO process | ✓ | — |
| `NO3` | Nitrate | Part of DO process | ✓ | — |
| `PH` | pH | Acidity/alkalinity; requires DO | ✓ | — |
| `SAL` | Salt | Salinity; conservative substance; used in DO process | ✓ | — |
| `TW` | Water Temperature | Temperature; used in DO process | ✓ | — |
| `COL` | Coliforms | E. coli / bacteria; first-order decay; no inter-variable interaction | ✓ | — |
| `CF1`–`CF4` | Coliforms 1–4 | E. coli and bacteria variants; interact with other variables | ✓ | ✓ |
| `ALG` | Algae | Dissolved (suspended) and attached algae; requires DO | ✓ | ✓ |
| `SI` | Silicate | Nutrient for algae; requires ALG | ✓ | — |
| `MAC` | Macrophytes | Rooted plants; requires ALG | ✓ | — |
| `SUL` | Hydrogen Sulphide | H2S concentration; requires BOD | ✓ | — |

> `PL1`–`PL4`, `CF1`–`CF4` generate individual field names per slot (e.g. `MCPL1DIS`, `MCCF2sf1`).

#### Token: `<SFX>` — Sediment fraction suffix

Represents the sediment fraction directly (not a determinant-sediment combination).

| Token | Meaning |
|-------|---------|
| `SF1` | Sediment fraction 1 (fine) |
| `SF2` | Sediment fraction 2 (coarse) — present only if a second sediment class is modelled |

> `<SFX>` fields track the mass concentration or flux of the suspended sediment itself, independently of any attached pollutant.

#### Field name construction

| Pattern | Meaning | Example |
|---------|---------|---------|
| `MC<PPP>DIS` | Concentration of `<PPP>`, dissolved phase | `MCBODDIS`, `MCNH4DIS` |
| `MC<PPP>TOT` | Concentration of `<PPP>`, total (dissolved + attached) | `MCBODTOT` |
| `MC<PPP>sf1` | Concentration of `<PPP>` attached to SF1 | `MCBODsf1` |
| `MC<SFX>` | Concentration of sediment fraction | `MCSF1` |
| `MF<PPP>DIS` | Mass flux of `<PPP>`, dissolved | `MFBODDIS` |
| `MF<PPP>TOT` | Mass flux of `<PPP>`, total | `MFBODTOT` |
| `MF<PPP>sf1` | Mass flux of `<PPP>` attached to SF1 | `MFBODsf1` |
| `MF<SFX>` | Mass flux of sediment fraction | `MFSF1` |
| `PF<PPP><SFX>` | Potency factor of `<PPP>` for `<SFX>` | `PFBODsf1` |
| `TM1<PPP>` | Total mass of `<PPP>` at start of simulation | `TM1BOD` |
| `TM2<PPP>` | Total mass of `<PPP>` entering system during simulation | `TM2BOD` |
| `TM3<PPP>` | Total mass of `<PPP>` at end of simulation | `TM3BOD` |
| `IN<PPP>TOT` | Mass inflow total | `INBODTOT` |
| `IN<SFX>` | Mass inflow of sediment fraction | `INSF1` |
| `MW<PPP>DIS` | Washoff mass, dissolved (subcatchments) | `MWBODDIS` |
| `MW<PPP>TOT` | Washoff mass, total (subcatchments) | `MWBODTOT` |

**Direction prefixes on link/node fields** (valid for both `sim.*` and `tsr.*` syntax):

| Prefix | Meaning |
|--------|---------|
| `us_MC<PPP>DIS` | Upstream end, concentration, dissolved |
| `ds_MC<PPP>DIS` | Downstream end, concentration, dissolved |
| `max_us_MC<PPP>DIS` | Maximum upstream concentration, dissolved |
| `max_ds_MC<PPP>DIS` | Maximum downstream concentration, dissolved |

The same directional prefix pattern applies to `MF*`, `PF*`, and `SEDDEP` fields.

#### Additional sediment / WQ fields (link objects)

| Field | Meaning |
|-------|---------|
| `SEDDEP` | Sediment deposition depth (instantaneous) |
| `SD1AVE` | Average sediment depth at start of initialisation |
| `SD2AVE` | Average sediment depth at end of simulation |
| `TAU` | Bed shear stress; river reaches |
| `STATE_L` | Regulator state — opening length |
| `MBED<SFX>` | Mass of sediment fraction in bed; river reaches |
| `MCPWBED<PPP>DIS` | Pore water concentration of `<PPP>` in bed; river reaches |
| `NETDEP` | Net deposition at section; river reaches |
| `BED_OFFSET` | Section bed offset; river reaches |
| `ACTIVE_LAYER_DEPTH` | Active layer depth; river reaches |

> **WQ results only appear when the corresponding determinant was enabled in the simulation's QM Parameters.** Fields for determinants not modelled in a given simulation will be absent.

---

### Node Results (`hw_node`)

#### Hydraulic summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max depth | `tsr.DMAXD` | result | Summary |
| Max flood depth | `tsr.Max_FloodDepth` | result | Summary |
| Max flood volume | `tsr.Max_FloodVolume` | result | Summary |
| Max flood volume (cumulative) | `tsr.MAX_FLVOL` | result | Summary |
| Flood volume (cumulative) | `tsr.FLVOL` | result | Summary |
| Max stored volume | `tsr.MAX_VOLUME` | result | Summary |
| Cumulative flow | `tsr.QCUM` | result | Summary |
| Cumulative inflow | `tsr.QINCUM` | result | Summary |
| Inlet efficiency | `tsr.INLETEFF` | result | Summary; gully/inlet nodes |
| Percentage volume balance | `tsr.PCVOLBAL` | result | Summary |
| Overland percentage volume balance | `tsr.OVPCVBAL` | result | Summary |
| Overland cumulative inflow | `tsr.OVQINCUM` | result | Summary |
| Overland volume balance | `tsr.OVVOLBAL` | result | Summary |
| Total flood volume | `tsr.VFLOOD` | result | Summary |
| Groundwater volume | `tsr.VGROUND` | result | Summary |
| Volume balance | `tsr.VOLBAL` | result | Summary |
| Max 2D depth at node | `tsr.MAX_TWODDEPNOD` | result | Summary; 2D simulations |
| Max flow from node to 2D zone | `tsr.MAX_TWODFLOODFLOW` | result | Summary; 2D simulations |
| Max flow from 2D zone to node | `tsr.MAX_TWODFLOW` | result | Summary; 2D simulations |
| Cumulative 2D zone to node flow | `tsr.TWODQCUM` | result | Summary; 2D simulations |
| Cumulative flood flow onto 2D zone | `tsr.TWODQCUMFLOOD` | result | Summary; 2D simulations |
| Cumulative gully flow | `tsr.GLLYQCUM` | result | Summary; gully nodes |
| Capacity-limited indicator | `tsr.Q_LIMITED` | result | Summary |
| Capacity-limited duration | `tsr.Q_LIMITED_DURATION` | result | Summary |
| Capacity-limited volume | `tsr.Q_LIMITED_VOLUME` | result | Summary |
| Capacity-limited volume rate | `tsr.Q_LIMITED_VOLUME_RATE` | result | Summary |
| Total capacity-limited volume | `tsr.Q_TOTAL_LIMITED_VOLUME` | result | Summary |

#### Hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Depth at node | `tsr.DEPNOD` | result | Time-varying |
| Flood depth | `tsr.FloodDepth` | result | Time-varying |
| Flood volume | `tsr.FloodVolume` | result | Time-varying |
| Flow | `tsr.FLOW` | result | Time-varying |
| Gully flow | `tsr.GLLYFLOW` | result | Time-varying; gully nodes |
| Gutter spread | `tsr.GTTRSPRD` | result | Time-varying; gully nodes |
| Overland depth | `tsr.OVDEPNOD` | result | Time-varying |
| Overland flow | `tsr.OVQNODE` | result | Time-varying |
| Overland volume | `tsr.OVVOLUME` | result | Time-varying |
| Infiltration flow | `tsr.QINFNOD` | result | Time-varying |
| Flow at node | `tsr.QNODE` | result | Time-varying |
| Rainfall inflow | `tsr.QRAIN` | result | Time-varying |
| 2D depth at node | `tsr.TWODDEPNOD` | result | Time-varying; 2D simulations |
| Flow from node to 2D zone | `tsr.TWODFLOODFLOW` | result | Time-varying; 2D simulations |
| Flow from 2D zone to node | `tsr.TWODFLOW` | result | Time-varying; 2D simulations |
| Stored volume | `tsr.VOLUME` | result | Time-varying |

#### Water quality results (full set uses parametric `<PPP>`/`<SFX>`/`<CFX>` naming)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS` | result | Summary |
| Max concentration \<PPP\> total | `tsr.MC<PPP>TOT` | result | Summary |
| Max concentration \<SFX\> | `tsr.MC<SFX>` | result | Summary |
| Max H2S concentration | `tsr.MCH2S` | result | Summary |
| Maximum pH | `tsr.PHMAX` | result | Summary |
| Minimum pH | `tsr.PHMIN` | result | Summary |
| Maximum water temperature | `tsr.TWMAX` | result | Summary |
| Minimum water temperature | `tsr.TWMIN` | result | Summary |
| Total mass \<PPP\> from DWF | `tsr.TM<PPP>DWF` | result | Summary |
| Total mass \<PPP\> at end of simulation | `tsr.TM3<PPP>` | result | Summary |
| Concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS` | result | Time-varying |
| Concentration \<PPP\> total | `tsr.MC<PPP>TOT` | result | Time-varying |
| Concentration \<SFX\> | `tsr.MC<SFX>` | result | Time-varying |
| Concentration H2S dissolved | `tsr.MCH2S` | result | Time-varying |
| pH | `tsr.PH` | result | Time-varying |
| Water temperature | `tsr.TW` | result | Time-varying |
| Unionised ammoniacal nitrogen | `tsr.UNNH3` | result | Time-varying |
| Saturated DO | `tsr.DO_SAT` | result | Time-varying |
| Mass inflow \<PPP\> total | `tsr.IN<PPP>TOT` | result | Time-varying |
| Mass inflow \<SFX\> | `tsr.IN<SFX>` | result | Time-varying |
| Potency factor \<PPP\> \<SFX\> | `tsr.PF<PPP><SFX>` | result | Time-varying |

### Link Results (`hw_conduit` and other link types)

Database table: `__IWR_Link`. The Help UI shows `us_`/`ds_` prefixes but fields are accessed without these in ICM SQL.

#### Hydraulic summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max depth | `tsr.DEPMAX` | result | Summary |
| Max velocity | `tsr.VELMAX` | result | Summary |
| Max Froude number | `tsr.FR_MAX` | result | Summary |
| Max flow | `tsr.QMAX` | result | Summary |
| Cumulative flow | `tsr.QCUM` | result | Summary |
| Pipe full capacity | `tsr.PFC` | result | Summary |
| Cumulative inflow | `tsr.QLICUM` | result | Summary; links with draining subcatchments |
| Link type | `tsr.TYPE` | result | Summary |
| Max surcharge state | `tsr.maxsurchargestate` | result | Summary; <1=not surcharged, 1=by depth, 2=by flow |
| Max infiltration loss | `tsr.QINFLNK` | result | Summary |
| Max lateral flow | `tsr.QLINK` | result | Summary; links with draining subcatchments |
| Section reach chainage | `tsr.RR_CHAINAGE` | result | Summary; river reaches |
| Max flow from 2D zone | `tsr.TWODFLOW` | result | Summary; 2D conduits |
| Cumulative flow from 2D zone | `tsr.TWODQCUM` | result | Summary; 2D conduits |
| Max flooding onto 2D zone | `tsr.TWODFLOODFLOW` | result | Summary; 2D conduits |
| Cumulative flooding onto 2D zone | `tsr.TWODQCUMFLOOD` | result | Summary; 2D conduits |

#### Hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Depth | `tsr.DEPTH` | result | Time-varying |
| Flow | `tsr.FLOW` | result | Time-varying |
| Velocity | `tsr.VEL` | result | Time-varying |
| Froude number | `tsr.FROUDE` | result | Time-varying |
| Total head | `tsr.totalhead` | result | Time-varying |
| Hydraulic gradient | `tsr.HYDGRAD` | result | Time-varying |
| Level | `tsr.Level` | result | Time-varying |
| Pump state | `tsr.PMPSTATE` | result | Time-varying; pumps |
| Infiltration loss | `tsr.QINFLNK` | result | Time-varying |
| Lateral inflow | `tsr.QLINK` | result | Time-varying; links with draining subcatchments |
| Regulator state | `tsr.STATE` | result | Time-varying |
| Regulator state (opening) | `tsr.STATE_D` | result | Time-varying |
| Regulator state (length) | `tsr.STATE_L` | result | Time-varying |
| Regulator state (flow) | `tsr.STATE_Q` | result | Time-varying |
| Regulator state (depth above min) | `tsr.STATE_Z` | result | Time-varying |
| Status | `tsr.STATUS` | result | Time-varying; timestep log simulations |
| Surcharge state | `tsr.Surcharge` | result | Time-varying |
| Variable speed | `tsr.VARSPEED` | result | Time-varying; VFD pumps |
| Volume | `tsr.VOLUME` | result | Time-varying |
| Flooding onto 2D zone | `tsr.TWODFLOODFLOW` | result | Time-varying; 2D conduits |
| Flow from 2D zone | `tsr.TWODFLOW` | result | Time-varying; 2D conduits |
| Variable bank level | `tsr.VIB_ELEVATION` | result | Time-varying; inline banks with breach |
| Variable bank offset | `tsr.VIB_OFFSET` | result | Time-varying; inline banks with breach |

#### Water quality results (selected key fields)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS` | result | Summary |
| Max concentration \<PPP\> total | `tsr.MC<PPP>TOT` | result | Summary |
| Max concentration \<SFX\> | `tsr.MC<SFX>` | result | Summary |
| Max mass flow \<PPP\> dissolved | `tsr.MF<PPP>DIS` | result | Summary |
| Max mass flow \<PPP\> total | `tsr.MF<PPP>TOT` | result | Summary |
| Max H2S concentration | `tsr.MCH2S` | result | Summary |
| Max pH | `tsr.PHMAX` | result | Summary |
| Min pH | `tsr.PHMIN` | result | Summary |
| Max water temperature | `tsr.TWMAX` | result | Summary |
| Min water temperature | `tsr.TWMIN` | result | Summary |
| Max sediment depth | `tsr.SEDDEP` | result | Summary |
| Average sediment depth at start of init | `tsr.SD1AVE` | result | Summary |
| Average sediment depth at end of sim | `tsr.SD2AVE` | result | Summary |
| Active layer depth | `tsr.ACTIVE_LAYER_DETPH` | result | Summary; river reaches |
| Concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS` | result | Time-varying |
| Concentration \<PPP\> total | `tsr.MC<PPP>TOT` | result | Time-varying |
| Concentration \<SFX\> | `tsr.MC<SFX>` | result | Time-varying |
| Concentration H2S dissolved | `tsr.MCH2S` | result | Time-varying |
| Mass flow \<PPP\> dissolved | `tsr.MF<PPP>DIS` | result | Time-varying |
| Mass flow \<PPP\> total | `tsr.MF<PPP>TOT` | result | Time-varying |
| Sediment depth | `tsr.SEDDEP` | result | Time-varying |
| Potency factor \<PPP\> \<SFX\> | `tsr.PF<PPP><SFX>` | result | Time-varying |
| pH | `tsr.PH` | result | Time-varying |
| Shear stress | `tsr.TAU` | result | Time-varying; river reaches |
| Water temperature | `tsr.TW` | result | Time-varying |
| Unionised ammoniacal nitrogen | `tsr.UNNH3` | result | Time-varying |
| Saturated DO | `tsr.DO_SAT` | result | Time-varying |
| Mass of \<SFX\> in bed | `tsr.MBED<SFX>` | result | Time-varying; river reaches |
| Pore water concentration \<PPP\> in bed | `tsr.MCPWBED<PPP>DIS` | result | Time-varying; river reaches |
| Section bed offset | `tsr.BED_OFFSET` | result | Time-varying; river reaches |
| Section net deposition | `tsr.NETDEP` | result | Time-varying; river reaches |

### Subcatchment Results (`hw_subcatchment`)

#### Hydraulic time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Total outflow | `tsr.QCATCH` | result | Time-varying |
| Runoff | `tsr.RUNOFF` | result | Time-varying |
| Runoff (raw) | `tsr.QRAW` | result | Time-varying |
| Runoff from surface | `tsr.QSURF<SS>` | result | Time-varying; \<SS\> = surface type suffix |
| Foul flow | `tsr.QFOUL` | result | Time-varying |
| Trade flow | `tsr.QTRADE` | result | Time-varying |
| Base flow | `tsr.QBASE` | result | Time-varying |
| RDII flow | `tsr.QRDII` | result | Time-varying |
| Rainfall | `tsr.RAINFALL` | result | Time-varying |
| Effective rainfall | `tsr.EFFRAIN` | result | Time-varying |
| Rainfall profile | `tsr.RAINPROF` | result | Time-varying |
| Evaporation profile | `tsr.EVAPPROF` | result | Time-varying |
| Evaporation rate | `tsr.EVAPRATE` | result | Time-varying |
| Impervious flow to SUDS | `tsr.Q_LID_IN` | result | Time-varying |
| SUDS surface outflow | `tsr.Q_LID_OUT` | result | Time-varying |
| SUDS drain outflow | `tsr.Q_LID_DRAIN` | result | Time-varying |
| Exceedance flow | `tsr.Q_EXCEEDANCE` | result | Time-varying; capacity-limited subcatchments |
| Exceedance volume | `tsr.V_EXCEEDANCE` | result | Time-varying; capacity-limited subcatchments |
| Net API30 | `tsr.NAPI` | result | Time-varying; New UK runoff surface |
| Precipitation index on surface | `tsr.PREC_IDX<SURF>` | result | Time-varying; UKWIR runoff model |
| Computed baseflow | `tsr.CMPBASEFLOW` | result | Time-varying; ReFH model |
| Soil moisture content | `tsr.REFH_C` | result | Time-varying; ReFH model |
| Rainfall-driven baseflow | `tsr.PDM_BASEFLOW` | result | Time-varying; PDM subcatchments |
| Interflow | `tsr.PDM_INTERFLOW` | result | Time-varying; PDM subcatchments |
| Surface flow | `tsr.PDM_SURFACEFLOW` | result | Time-varying; PDM subcatchments |
| Soil moisture deficit | `tsr.PDM_SMD` | result | Time-varying; PDM subcatchments |
| Inflow to surface store | `tsr.PDM_TOSURFACE` | result | Time-varying; PDM subcatchments |
| Inflow to interflow store | `tsr.PDM_TOINTERFLOW` | result | Time-varying; PDM subcatchments |
| Inflow to groundwater store | `tsr.PDM_TOBASEFLOW` | result | Time-varying; PDM subcatchments |
| Actual evaporation | `tsr.PDM_EVAPORATION` | result | Time-varying; PDM subcatchments |
| Infiltration excess | `tsr.PDM_EXCESS` | result | Time-varying; PDM subcatchments |
| Ground store level | `tsr.GRNDSTOR` | result | Time-varying |
| Lost to groundwater | `tsr.LOSTTOGW` | result | Time-varying |
| Infiltration to soil | `tsr.QINFSOIL` | result | Time-varying |
| Soil store depth | `tsr.SOILSTOR` | result | Time-varying |
| Soil store inflow | `tsr.QSOIL` | result | Time-varying |
| Ground store inflow | `tsr.QGROUND` | result | Time-varying |
| Infiltration to groundwater | `tsr.QINFGRND` | result | Time-varying |
| Groundwater inflow | `tsr.QINFILT` | result | Time-varying |
| Pervious snow depth | `tsr.PERVSNOW` | result | Time-varying; snow pack subcatchments |
| Impervious snow depth | `tsr.IMPSNOW` | result | Time-varying; snow pack subcatchments |
| Ploughable snow depth | `tsr.PLOWSNOW` | result | Time-varying; snow pack subcatchments |
| Pervious melt rate | `tsr.PERVMELT` | result | Time-varying; snow pack subcatchments |
| Impervious melt rate | `tsr.IMPMELT` | result | Time-varying; snow pack subcatchments |
| Pervious free water | `tsr.PERVFW` | result | Time-varying; snow pack subcatchments |
| Impervious free water | `tsr.IMPFW` | result | Time-varying; snow pack subcatchments |
| Ploughable free water | `tsr.PLOWFW` | result | Time-varying; snow pack subcatchments |

#### Water quality / washoff results (selected key fields)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Washoff \<PPP\> dissolved | `tsr.MW<PPP>DIS` | result | Time-varying |
| Washoff \<PPP\> total | `tsr.MW<PPP>TOT` | result | Time-varying |
| Washoff \<SFX\> | `tsr.MWSFX` | result | Time-varying |
| Washoff coliforms | `tsr.MWCOLDIS` | result | Time-varying |
| Mass of \<PPP\> available at end of init | `tsr.MW0<PPP>` | result | Summary |
| Mass of \<PPP\> available for entire sim | `tsr.MW1<PPP>` | result | Summary |
| Mass of \<PPP\> remaining at end of sim | `tsr.MWR<PPP>` | result | Summary |
| Mass of \<SFX\> remaining at end of sim | `tsr.MWRSF1` | result | Summary |

### Building Results (`hw_building`)

#### Summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Effective rainfall | `tsr.EFFRAIN` | result | Summary; total depth on impervious surfaces minus evaporation |
| Rainfall profile | `tsr.RAINPROF` | result | Summary; profile applied during simulation |
| Evaporation profile | `tsr.EVAPPROF` | result | Summary; evaporation profile applied during simulation |
| Exceedance volume | `tsr.V_EXCEEDANCE` | result | Summary; capacity-limited buildings only |
| Runoff | `tsr.RUNOFF` | result | Summary; maximum flow from building roof |
| Total outflow | `tsr.QCATCH` | result | Summary; maximum total outflow including SuDS |
| Exceedance flow | `tsr.Q_EXCEEDANCE` | result | Summary; capacity-limited buildings only |
| Max enclosed volume | `tsr.MAXVOLUME2D` | result | Summary; maximum volume within building |
| Max flow into building | `tsr.MAXFLOW2D` | result | Summary |
| Max highest depth | `tsr.MAXHIGHDEPTH2D` | result | Summary |
| Max highest elevation | `tsr.MAXHIGHELEVATION2D` | result | Summary; null if elements are dry throughout |

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Total outflow | `tsr.QCATCH` | result | Time-varying; runoff plus SuDS control net outflow |
| Exceedance flow | `tsr.Q_EXCEEDANCE` | result | Time-varying; capacity-limited buildings only |
| Enclosed volume | `tsr.VOLUME2D` | result | Time-varying; sum of depth × area across 2D mesh elements inside building |
| Flow into building | `tsr.FLOW2D` | result | Time-varying; positive = into building |
| Highest depth | `tsr.HIGHDEPTH2D` | result | Time-varying; maximum depth of 2D elements inside building boundary |
| Highest elevation | `tsr.HIGHELEVATION2D` | result | Time-varying; null when all elements inside building are dry |

### TVD Connector Results (`hw_tvd_connector`)

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| ARMA flow | `tsr.ARMA_Q` | result | Time-varying; ARMA connectors |
| ARMA velocity | `tsr.ARMA_V` | result | Time-varying; ARMA connectors |
| ARMA depth | `tsr.ARMA_Y` | result | Time-varying; ARMA connectors |
| Height above datum (ARMA) | `tsr.ARMA_R` | result | Time-varying; ARMA connectors |
| Angle | `tsr.TVD_ANGLE` | result | Time-varying |
| Angle (radians) | `tsr.TVD_ANGLER` | result | Time-varying |
| Angular velocity | `tsr.TVD_ANGLEV` | result | Time-varying |
| Temperature | `tsr.TVD_CF` | result | Time-varying |
| Change in flow | `tsr.TVD_DQ` | result | Time-varying |
| Change in speed | `tsr.TVD_DRPM` | result | Time-varying |
| Change in depth | `tsr.TVD_DY` | result | Time-varying |
| Change in level | `tsr.TVD_DZ` | result | Time-varying |
| Evaporation | `tsr.TVD_EV` | result | Time-varying |
| Fraction | `tsr.TVD_FRAC` | result | Time-varying |
| Time interval | `tsr.TVD_HOURS` | result | Time-varying |
| Infiltration | `tsr.TVD_I` | result | Time-varying |
| Infiltration flow | `tsr.TVD_IF` | result | Time-varying |
| Length | `tsr.TVD_L` | result | Time-varying |
| Mass concentration (SI) | `tsr.TVD_MCSI` | result | Time-varying |
| Mass concentration (user) | `tsr.TVD_MCU` | result | Time-varying |
| Mass flow (SI) | `tsr.TVD_MFSI` | result | Time-varying |
| Mass flow (user) | `tsr.TVD_MFU` | result | Time-varying |
| Number | `tsr.TVD_NUMBER` | result | Time-varying |
| Pollutant potency | `tsr.TVD_PP` | result | Time-varying |
| Flow | `tsr.TVD_Q` | result | Time-varying |
| Rainfall intensity | `tsr.TVD_R` | result | Time-varying |
| Rainfall depth | `tsr.TVD_RD` | result | Time-varying |
| Sediment depth | `tsr.TVD_RSD` | result | Time-varying |
| Soil moisture deficit | `tsr.TVD_SMD` | result | Time-varying |
| Solar radiation | `tsr.TVD_SR` | result | Time-varying |
| Time | `tsr.TVD_TS` | result | Time-varying |
| Force per unit length | `tsr.TVD_UF` | result | Time-varying |
| Unit flow | `tsr.TVD_UQ` | result | Time-varying |
| Velocity | `tsr.TVD_V` | result | Time-varying |
| Volume | `tsr.TVD_VO` | result | Time-varying |
| Rotation speed | `tsr.TVD_WN_AV` | result | Time-varying |
| Wind speed | `tsr.TVD_WS` | result | Time-varying |
| Depth | `tsr.TVD_Y` | result | Time-varying |
| Height above datum | `tsr.TVD_Z` | result | Time-varying |

### 2D Zone Results (`hw_2d_zone`)

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Direction | `tsr.ANGLE2D` | result | Time-varying; flow direction in radians from due East |
| Mean depth | `tsr.AVEDEPTH2D` | result | Time-varying; wet-portion average depth; subgrid models only |
| Depth | `tsr.DEPTH2D` | result | Time-varying; highest depth for subgrid elements |
| Cumulative infiltration | `tsr.CUMINF2D` | result | Time-varying; when infiltration surface assigned |
| Eddy viscosity | `tsr.EDDYVISCOSITY2D` | result | Time-varying |
| Effective infiltration | `tsr.EFFINF2D` | result | Time-varying; when infiltration surface assigned |
| Elevation | `tsr.elevation2d` | result | Time-varying; null when element is dry |
| Froude number | `tsr.froude2d` | result | Time-varying |
| Green-Ampt saturation flag | `tsr.GASFLAG2D` | result | Time-varying; Green-Ampt infiltration models only |
| Green-Ampt moisture content of upper zone | `tsr.GAMCUZ2D` | result | Time-varying; Green-Ampt infiltration models only |
| Green-Ampt soil moisture deficit (%) | `tsr.GASMD2D` | result | Time-varying; Green-Ampt infiltration models only |
| Green-Ampt time to drain upper zone | `tsr.GATDUZ2D` | result | Time-varying; Green-Ampt infiltration models only |
| Infiltration potential | `tsr.POTINF2D` | result | Time-varying; Horton infiltration models only |
| Speed | `tsr.SPEED2D` | result | Time-varying; water velocity |
| Soil water content percentage | `tsr.SWCP2D` | result | Time-varying; Horton infiltration models only |
| Unit flow | `tsr.unitflow2d` | result | Time-varying; flow per unit length |
| Volume | `tsr.SGVOLUME2D` | result | Time-varying; subgrid models only |

#### Time-varying water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Concentration \<CFX\> dissolved 2D | `tsr.MC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> dissolved 2D | `tsr.MC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> detrital 2D | `tsr.MC<PPD>DET2D` | result | Time-varying; WQ simulations |
| Concentration \<CFX\> \<SFX\> 2D | `tsr.MC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> \<SFX\> 2D | `tsr.MC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Concentration \<SFX\> 2D | `tsr.MC<SFX>2D` | result | Time-varying; WQ simulations |
| Saturated DO 2D | `tsr.DO_SAT2D` | result | Time-varying; dissolved oxygen WQ simulations |
| Coliforms 2D | `tsr.MCCOLDDIS2D` | result | Time-varying; WQ simulations |
| pH 2D | `tsr.PH2D` | result | Time-varying; WQ simulations |
| Water temperature 2D | `tsr.TW2D` | result | Time-varying; WQ simulations |
| Unionised NH3 2D | `tsr.UNNH32D` | result | Time-varying; WQ simulations |
| Dimensionless \<SFX\> concentration | `tsr.AC<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Dimensionless sediment concentration | `tsr.AC2D` | result | Time-varying; 2D WQ simulations |
| Combined carrying capacity | `tsr.CC2D` | result | Time-varying; dependent sediment fractions |
| Carrying capacity \<SFX\> | `tsr.CC<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Compacted depth \<BSL\> layer | `tsr.COMPDEP<BSL>2D` | result | Time-varying; 2D WQ simulations |
| Sediment depth | `tsr.DPT2D` | result | Time-varying; 2D WQ simulations |
| Sediment depth \<SFX\> | `tsr.DPT<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Deposited sediment depth | `tsr.INCD2D` | result | Time-varying; 2D WQ simulations |
| Deposited sediment depth \<SFX\> | `tsr.INCD<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total deposited sediment depth (bed load) | `tsr.INCDBL2D` | result | Time-varying; 2D WQ simulations |
| Deposited sediment depth \<SFX\> (bed load) | `tsr.INCDBL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total deposited sediment depth (suspended load) | `tsr.INCDSL2D` | result | Time-varying; 2D WQ simulations |
| Deposited sediment depth \<SFX\> (suspended load) | `tsr.INCDSL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total net erosion rate (bed load) | `tsr.ERBL2D` | result | Time-varying; 2D WQ simulations |
| Net erosion rate \<SFX\> (bed load) | `tsr.ERBL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total net erosion rate (suspended load) | `tsr.ERSL2D` | result | Time-varying; 2D WQ simulations |
| Net erosion rate \<SFX\> (suspended load) | `tsr.ERSL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total net erosion rate | `tsr.ER2D` | result | Time-varying; 2D WQ simulations |
| Net erosion rate \<SFX\> | `tsr.ER<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Level \<BSL\> layer | `tsr.LEVEL<BSL>2D` | result | Time-varying; 2D WQ simulations |
| Rouse number \<SFX\> | `tsr.RN<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Rouse number | `tsr.RN2D` | result | Time-varying; 2D WQ simulations |
| Shear stress \<SFX\> | `tsr.TAU<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Shear stress | `tsr.TAU2D` | result | Time-varying; 2D WQ simulations |
| Transport parameter \<SFX\> | `tsr.TP<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Transport parameter | `tsr.TP2D` | result | Time-varying; 2D WQ simulations |
| Volume concentration \<SFX\> \<BSL\> layer | `tsr.VC<SFX><BSL>2D` | result | Time-varying; 2D WQ simulations |

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
| Element level (ground level) | `tsr.GNDLEV2D` | result | Summary; adjusted level if mesh zone modification applied |
| Max hazard | `tsr.HAZARD2D` | result | Summary; DEFRA HR = d×(v+0.5)+DF |
| Rainfall profile | `tsr.RAINPROF2D` | result | Summary |
| Time to last inundation | `tsr.T_END_INUNDATION_2D` | result | Summary; -1 if threshold not met |
| Total inundation duration | `tsr.T_FLOOD_DURATION_2D` | result | Summary; -1 if threshold not met |
| Time to first inundation | `tsr.T_INUNDATION_2D` | result | Summary; -1 if threshold not met |
| Time to peak inundation | `tsr.T_PEAK_2D` | result | Summary; -1 if element dry throughout |
| Non-erodible level | `tsr.LEVEL_NE2D` | result | Summary; 2D WQ simulations |
| Volume error | `tsr.VOLERROR2D` | result | Summary |

### Network Results Point Results (`hw_1d_results_point`)

#### Summary results (non time-varying)

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max depth | `tsr.DEPMAX` | result | Summary |
| Max Froude number | `tsr.FR_MAX` | result | Summary |
| Max velocity | `tsr.VELMAX` | result | Summary |
| Max flow | `tsr.QMAX` | result | Summary |
| Max total head | `tsr.TOTALHEAD_MAX` | result | Summary |
| Cumulative flow | `tsr.QCUM` | result | Summary |
| Max concentration \<CFX\> \<SFX\> | `tsr.MC<CFX><SFX>` | result | Summary; WQ simulations |
| Max concentration \<PPP\> \<SFX\> | `tsr.MC<PPP><SFX>` | result | Summary; WQ simulations |
| Max concentration \<PPP\> detrital | `tsr.MC<PPP>DET` | result | Summary; WQ simulations |
| Max concentration \<CFX\> dissolved | `tsr.MC<CFX>DIS` | result | Summary; WQ simulations |
| Max concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS` | result | Summary; WQ simulations |
| Max concentration \<CFX\> total | `tsr.MC<CFX>TOT` | result | Summary; WQ simulations |
| Max concentration \<PPP\> total | `tsr.MC<PPP>TOT` | result | Summary; WQ simulations |
| Max concentration \<SFX\> | `tsr.MC<SFX>` | result | Summary; WQ simulations |
| Max mass flow \<CFX\> \<SFX\> | `tsr.MF<CFX><SFX>` | result | Summary; WQ simulations |
| Max mass flow \<PPP\> \<SFX\> | `tsr.MF<PPP><SFX>` | result | Summary; WQ simulations |
| Max mass flow \<PPP\> detrital | `tsr.MF<PPP>DET` | result | Summary; WQ simulations |
| Max mass flow \<CFX\> dissolved | `tsr.MF<CFX>DIS` | result | Summary; WQ simulations |
| Max mass flow \<PPP\> dissolved | `tsr.MF<PPP>DIS` | result | Summary; WQ simulations |
| Max mass flow \<CFX\> total | `tsr.MF<CFX>TOT` | result | Summary; WQ simulations |
| Max mass flow \<PPP\> total | `tsr.MF<PPP>TOT` | result | Summary; WQ simulations |
| Max mass flow \<SFX\> | `tsr.MF<SFX>` | result | Summary; WQ simulations |
| Max concentration H2S dissolved | `tsr.MCH2S` | result | Summary; WQ simulations |
| Maximum pH | `tsr.PHMAX` | result | Summary; WQ simulations |
| Minimum pH | `tsr.PHMIN` | result | Summary; WQ simulations |
| Max sediment depth | `tsr.SEDDEP` | result | Summary; WQ simulations |
| Maximum water temperature | `tsr.TWMAX` | result | Summary; WQ simulations |
| Minimum water temperature | `tsr.TWMIN` | result | Summary; WQ simulations |

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Depth | `tsr.DEPTH` | result | Time-varying |
| Flow | `tsr.FLOW` | result | Time-varying |
| Froude number | `tsr.FROUDE` | result | Time-varying |
| Velocity | `tsr.VEL` | result | Time-varying |
| Total head | `tsr.TOTALHEAD` | result | Time-varying |
| Concentration \<CFX\> \<SFX\> | `tsr.MC<CFX><SFX>` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> \<SFX\> | `tsr.MC<PPP><SFX>` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> detrital | `tsr.MC<PPP>DET` | result | Time-varying; WQ simulations |
| Concentration \<CFX\> dissolved | `tsr.MC<CFX>DIS` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS` | result | Time-varying; WQ simulations |
| Concentration \<SFX\> | `tsr.MC<SFX>` | result | Time-varying; WQ simulations |
| Mass flow \<CFX\> \<SFX\> | `tsr.MF<CFX><SFX>` | result | Time-varying; WQ simulations |
| Mass flow \<PPP\> \<SFX\> | `tsr.MF<PPP><SFX>` | result | Time-varying; WQ simulations |
| Mass flow \<PPP\> detrital | `tsr.MF<PPP>DET` | result | Time-varying; WQ simulations |
| Mass flow \<CFX\> dissolved | `tsr.MF<CFX>DIS` | result | Time-varying; WQ simulations |
| Mass flow \<PPP\> dissolved | `tsr.MF<PPP>DIS` | result | Time-varying; WQ simulations |
| Mass flow \<CFX\> total | `tsr.MF<CFX>TOT` | result | Time-varying; WQ simulations |
| Mass flow \<PPP\> total | `tsr.MF<PPP>TOT` | result | Time-varying; WQ simulations |
| Mass flow \<SFX\> | `tsr.MF<SFX>` | result | Time-varying; WQ simulations |
| Concentration H2S dissolved | `tsr.MCH2S` | result | Time-varying; WQ simulations |
| Potency factor \<CFX\> \<SFX\> | `tsr.PF<CFX><SFX>` | result | Time-varying; WQ simulations |
| Potency factor \<PPP\> \<SFX\> | `tsr.PF<PPP><SFX>` | result | Time-varying; WQ simulations |
| pH | `tsr.PH` | result | Time-varying; WQ simulations |
| Sediment depth | `tsr.SEDDEP` | result | Time-varying; WQ simulations |
| Shear stress | `tsr.TAU` | result | Time-varying; WQ simulations |
| Water temperature | `tsr.TW` | result | Time-varying; WQ simulations |
| Unionised ammoniacal nitrogen | `tsr.UNNH3` | result | Time-varying; WQ simulations |
| Saturated DO | `tsr.DO_SAT` | result | Time-varying; WQ simulations |

### Network Results Point Results (2D) (`hw_2d_results_point`)

Database table: `_IWR_2DResultsPoint`

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
| Green-Ampt saturation flag | `tsr.GASFLAG2D` | result | Time-varying; Green-Ampt infiltration models only |
| Green-Ampt moisture content of upper zone | `tsr.GAMCUZ2D` | result | Time-varying; Green-Ampt infiltration models only |
| Green-Ampt soil moisture deficit (%) | `tsr.GASMD2D` | result | Time-varying; Green-Ampt infiltration models only |
| Green-Ampt time to drain upper zone | `tsr.GATDUZ2D` | result | Time-varying; Green-Ampt infiltration models only |
| Infiltration potential | `tsr.POTINF2D` | result | Time-varying; Horton infiltration models only |
| Cumulative infiltration | `tsr.CUMINF2D` | result | Time-varying; when infiltration surface assigned to 2D zone |
| Effective infiltration | `tsr.EFFINF2D` | result | Time-varying; when infiltration surface assigned to 2D zone |
| Soil water content percentage | `tsr.SWCP2D` | result | Time-varying; Horton infiltration models only |

#### Time-varying water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Concentration \<SFX\> | `tsr.MC<SFX>2D` | result | Time-varying; WQ simulations |
| Concentration \<CFX\> dissolved | `tsr.MC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| Concentration \<PPP\> dissolved | `tsr.MC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| Concentration \<CFX\>\<SFX\> | `tsr.MC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| Concentration \<PPP\>\<SFX\> | `tsr.MC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Saturated DO | `tsr.DO_SAT2D` | result | Time-varying; dissolved oxygen WQ simulations |
| Coliforms | `tsr.MCCOLDDIS2D` | result | Time-varying; WQ simulations |
| pH | `tsr.PH2D` | result | Time-varying; WQ simulations |
| Water temperature | `tsr.TW2D` | result | Time-varying; WQ simulations |
| Unionised ammoniacal nitrogen | `tsr.UNNH32D` | result | Time-varying; WQ simulations |
| Dimensionless sediment concentration | `tsr.AC2D` | result | Time-varying; 2D WQ simulations |
| Dimensionless \<SFX\> concentration | `tsr.AC<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Carrying capacity \<SFX\> | `tsr.CC<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Combined carrying capacity | `tsr.CC2D` | result | Time-varying; dependent sediment fractions |
| Compacted depth \<BSL\> layer | `tsr.COMPDEP<BSL>2D` | result | Time-varying; 2D WQ simulations |
| Sediment depth \<SFX\> | `tsr.DPT<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Sediment depth | `tsr.DPT2D` | result | Time-varying; 2D WQ simulations |
| Net erosion rate \<SFX\> | `tsr.ER<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total net erosion rate | `tsr.ER2D` | result | Time-varying; 2D WQ simulations |
| Net erosion rate \<SFX\> (bed load) | `tsr.ERBL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total net erosion rate (bed load) | `tsr.ERBL2D` | result | Time-varying; 2D WQ simulations |
| Net erosion rate \<SFX\> (suspended load) | `tsr.ERSL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total net erosion rate (suspended load) | `tsr.ERSL2D` | result | Time-varying; 2D WQ simulations |
| Deposited sediment depth \<SFX\> (bed load) | `tsr.INCDBL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total deposited sediment depth (bed load) | `tsr.INCDBL2D` | result | Time-varying; 2D WQ simulations |
| Deposited sediment depth \<SFX\> (suspended load) | `tsr.INCDSL<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Total deposited sediment depth (suspended load) | `tsr.INCDSL2D` | result | Time-varying; 2D WQ simulations |
| Level \<BSL\> layer | `tsr.LEVEL<BSL>2D` | result | Time-varying; 2D WQ simulations |
| Rouse number \<SFX\> | `tsr.RN<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Rouse number | `tsr.RN2D` | result | Time-varying; 2D WQ simulations |
| Shear stress \<SFX\> | `tsr.TAU<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Shear stress | `tsr.TAU2D` | result | Time-varying; 2D WQ simulations |
| Transport parameter \<SFX\> | `tsr.TP<SFX>2D` | result | Time-varying; 2D WQ simulations |
| Transport parameter | `tsr.TP2D` | result | Time-varying; 2D WQ simulations |
| Volume concentration \<SFX\> \<BSL\> layer | `tsr.VC<SFX><BSL>2D` | result | Time-varying; 2D WQ simulations |

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
| Min eddy viscosity | `tsr.MINEDDYVISCOSITY2D` | result | Summary |
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

#### Summary water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max concentration \<SFX\> | `tsr.MAXMC<SFX>2D` | result | Summary; WQ simulations |
| Max concentration \<CFX\> dissolved | `tsr.MAXMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Max concentration \<PPP\> dissolved | `tsr.MAXMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Max concentration \<CFX\>\<SFX\> | `tsr.MAX<CFX><SFX>2D` | result | Summary; WQ simulations |
| Max concentration \<PPP\>\<SFX\> | `tsr.MAX<PPP><SFX>2D` | result | Summary; WQ simulations |
| Max coliforms | `tsr.MAXMCCOLDIS2D` | result | Summary; WQ simulations |
| Max pH | `tsr.MAXPH2D` | result | Summary; WQ simulations |
| Max water temperature | `tsr.MAXTW2D` | result | Summary; WQ simulations |
| Min concentration \<SFX\> | `tsr.MINMC<SFX>2D` | result | Summary; WQ simulations |
| Min concentration \<CFX\> dissolved | `tsr.MINMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Min concentration \<PPP\> dissolved | `tsr.MINMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Min concentration \<CFX\>\<SFX\> | `tsr.MINMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Min concentration \<PPP\>\<SFX\> | `tsr.MINMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Min coliforms | `tsr.MINMCCOLDIS2D` | result | Summary; WQ simulations |
| Min pH | `tsr.MINPH2D` | result | Summary; WQ simulations |
| Min water temperature | `tsr.MINTW2D` | result | Summary; WQ simulations |
| Max sediment depth \<BSL\> layer | `tsr.MAXDPT<BSL>2D` | result | Summary; 2D WQ simulations |
| Max sediment depth | `tsr.MAXDPT2D` | result | Summary; 2D WQ simulations |
| Max net erosion rate \<SFX\> | `tsr.MAXER<SFX>2D` | result | Summary; 2D WQ simulations |
| Max total net erosion rate | `tsr.MAXER2D` | result | Summary; 2D WQ simulations |
| Max level \<BSL\> layer | `tsr.MAXLEVEL<BSL>2D` | result | Summary; 2D WQ simulations |
| Max shear stress \<SFX\> | `tsr.MAXTAU<SFX>2D` | result | Summary; 2D WQ simulations |
| Max shear stress | `tsr.MAXTAU2D` | result | Summary; 2D WQ simulations |
| Min sediment depth \<BSL\> layer | `tsr.MINDPT<BSL>2D` | result | Summary; 2D WQ simulations |
| Min sediment depth | `tsr.MINDPT2D` | result | Summary; 2D WQ simulations |
| Min net erosion rate \<SFX\> | `tsr.MINER<SFX>2D` | result | Summary; 2D WQ simulations |
| Min total net erosion rate | `tsr.MINER2D` | result | Summary; 2D WQ simulations |
| Min level \<BSL\> layer | `tsr.MINLEVEL<BSL>2D` | result | Summary; 2D WQ simulations |
| Min shear stress \<SFX\> | `tsr.MINTAU<SFX>2D` | result | Summary; 2D WQ simulations |
| Min shear stress | `tsr.MINTAU2D` | result | Summary; 2D WQ simulations |
| Non-erodible level | `tsr.LEVEL_NE2D` | result | Summary; 2D WQ simulations |

### Network Results Line Results (2D) (`hw_2d_results_line`)

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

#### Time-varying water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| \<SFX\> flow through line | `tsr.FLOWMC<SFX>2D` | result | Time-varying; WQ simulations |
| \<CFX\> dissolved flow through line | `tsr.FLOWMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| \<PPP\> dissolved flow through line | `tsr.FLOWMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| \<CFX\>\<SFX\> flow through line | `tsr.FLOWMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| \<PPP\>\<SFX\> flow through line | `tsr.FLOWMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Highest concentration \<SFX\> on line | `tsr.HIGHMC<SFX>2D` | result | Time-varying; WQ simulations |
| Highest concentration \<CFX\> dissolved on line | `tsr.HIGHMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| Highest concentration \<PPP\> dissolved on line | `tsr.HIGHMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| Highest concentration \<CFX\>\<SFX\> on line | `tsr.HIGHMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| Highest concentration \<PPP\>\<SFX\> on line | `tsr.HIGHMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Highest coliforms on line | `tsr.HIGHMCCOLDIS2D` | result | Time-varying; WQ simulations |
| Highest pH on line | `tsr.HIGHPH2D` | result | Time-varying; WQ simulations |
| Highest water temperature on line | `tsr.HIGHTW2D` | result | Time-varying; WQ simulations |
| Highest unionised ammoniacal nitrogen on line | `tsr.HIGHUNNH32D` | result | Time-varying; WQ simulations |
| Lowest concentration \<SFX\> on line | `tsr.LOWMC<SFX>2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<CFX\> dissolved on line | `tsr.LOWMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<PPP\> dissolved on line | `tsr.LOWMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<CFX\>\<SFX\> on line | `tsr.LOWMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<PPP\>\<SFX\> on line | `tsr.LOWMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Lowest coliforms on line | `tsr.LOWMCCODIS2D` | result | Time-varying; WQ simulations |
| Lowest pH on line | `tsr.LOWPH2D` | result | Time-varying; WQ simulations |
| Lowest water temperature on line | `tsr.LOWTW2D` | result | Time-varying; WQ simulations |
| Lowest unionised ammoniacal nitrogen on line | `tsr.LOWUNNH32D` | result | Time-varying; WQ simulations |

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

#### Summary water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max \<SFX\> flow through line | `tsr.MAXFLOWMC<SFX>2D` | result | Summary; WQ simulations |
| Max \<CFX\> dissolved flow through line | `tsr.MAXFLOWMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Max \<PPP\> dissolved flow through line | `tsr.MAXFLOWMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Max \<CFX\>\<SFX\> flow through line | `tsr.MAXFLOWMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Max \<PPP\>\<SFX\> flow through line | `tsr.MAXFLOWMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Min \<SFX\> flow through line | `tsr.MINFLOWMC<SFX>2D` | result | Summary; WQ simulations |
| Min \<CFX\> dissolved flow through line | `tsr.MINFLOWMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Min \<PPP\> dissolved flow through line | `tsr.MINFLOWMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Min \<CFX\>\<SFX\> flow through line | `tsr.MINFLOWMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Min \<PPP\>\<SFX\> flow through line | `tsr.MINFLOWMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Max highest concentration \<SFX\> on line | `tsr.MAXHIGHMC<SFX>2D` | result | Summary; WQ simulations |
| Max highest concentration \<CFX\> dissolved on line | `tsr.MAXHIGHMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Max highest concentration \<PPP\> dissolved on line | `tsr.MAXHIGHMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Max highest concentration \<CFX\>\<SFX\> on line | `tsr.MAXHIGHMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Max highest concentration \<PPP\>\<SFX\> on line | `tsr.MAXHIGHMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Max highest coliforms on line | `tsr.MAXHIGHMCCOLDIS2D` | result | Summary; WQ simulations |
| Max highest pH on line | `tsr.MAXHIGHPH2D` | result | Summary; WQ simulations |
| Max highest water temperature on line | `tsr.MAXHIGHTW2D` | result | Summary; WQ simulations |
| Min lowest concentration \<SFX\> on line | `tsr.MINLOWMC<SFX>2D` | result | Summary; WQ simulations |
| Min lowest concentration \<CFX\> dissolved on line | `tsr.MINLOWMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Min lowest concentration \<PPP\> dissolved on line | `tsr.MINLOWMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Min lowest concentration \<CFX\>\<SFX\> on line | `tsr.MINLOWMC<CFX>SFX>2D` | result | Summary; WQ simulations |
| Min lowest concentration \<PPP\>\<SFX\> on line | `tsr.MINLOWMC<PPP>SFX>2D` | result | Summary; WQ simulations |
| Min lowest coliforms on line | `tsr.MINLOWMCCOLDIS2D` | result | Summary; WQ simulations |
| Min lowest pH on line | `tsr.MINLOWPH2D` | result | Summary; WQ simulations |
| Min lowest water temperature on line | `tsr.MINLOWTW2D` | result | Summary; WQ simulations |

### Network Results Polygon Results (2D) (`hw_2d_results_polygon`)

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
| Cumulative infiltration | `tsr.CUMINF2D` | result | Time-varying; when infiltration surface assigned |
| Cumulative infiltration volume | `tsr.CUMINFVOL2D` | result | Time-varying; when infiltration surface assigned |

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
| Annual damage | `tsr.ANLDMG` | result | Summary; risk analysis results only |
| Critical duration | `tsr.CRITDUR` | result | Summary; risk analysis results only |
| Depth (risk analysis) | `tsr.DEPTH` | result | Summary; risk analysis results only |
| Expected annual damage | `tsr.EAD` | result | Summary; risk analysis results only |
| Damage | `tsr.DAMAGE` | result | Summary; risk analysis simulation results only |

#### Time-varying water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| \<SFX\> flow through polygon boundary | `tsr.FLOWMC<SFX>2D` | result | Time-varying; WQ simulations |
| \<CFX\> dissolved flow through polygon boundary | `tsr.FLOWMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| \<PPP\> dissolved flow through polygon boundary | `tsr.FLOWMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| \<CFX\>\<SFX\> flow through polygon boundary | `tsr.FLOWMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| \<PPP\>\<SFX\> flow through polygon boundary | `tsr.FLOWMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| \<SFX\> mass inside polygon | `tsr.MAXXMC<SFX>2D` | result | Time-varying; WQ simulations |
| \<CFX\> dissolved mass inside polygon | `tsr.MASSMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| \<PPP\> dissolved mass inside polygon | `tsr.MASSMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| \<CFX\>\<SFX\> mass inside polygon | `tsr.MASSMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| \<PPP\>\<SFX\> mass inside polygon | `tsr.MASSMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Highest concentration \<SFX\> inside polygon | `tsr.HIGHMC<SFX>2D` | result | Time-varying; WQ simulations |
| Highest concentration \<CFX\> dissolved inside polygon | `tsr.HIGHMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| Highest concentration \<PPP\> dissolved inside polygon | `tsr.HIGHMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| Highest concentration \<CFX\>\<SFX\> inside polygon | `tsr.HIGHMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| Highest concentration \<PPP\>\<SFX\> inside polygon | `tsr.HIGHMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Highest coliforms inside polygon | `tsr.HIGHMCCOLDIS2D` | result | Time-varying; WQ simulations |
| Highest pH inside polygon | `tsr.HIGHPH2D` | result | Time-varying; WQ simulations |
| Highest water temperature inside polygon | `tsr.HIGHTW2D` | result | Time-varying; WQ simulations |
| Highest unionised ammoniacal nitrogen inside polygon | `tsr.HIGHUNNH32D` | result | Time-varying; WQ simulations |
| Lowest concentration \<SFX\> inside polygon | `tsr.LOWMC<SFX>2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<CFX\> dissolved inside polygon | `tsr.LOWMC<CFX>DIS2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<PPP\> dissolved inside polygon | `tsr.LOWMC<PPP>DIS2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<CFX\>\<SFX\> inside polygon | `tsr.LOWMC<CFX><SFX>2D` | result | Time-varying; WQ simulations |
| Lowest concentration \<PPP\>\<SFX\> inside polygon | `tsr.LOWMC<PPP><SFX>2D` | result | Time-varying; WQ simulations |
| Lowest coliforms inside polygon | `tsr.LOWMCCOLDIS2D` | result | Time-varying; WQ simulations |
| Lowest pH inside polygon | `tsr.LOWPH2D` | result | Time-varying; WQ simulations |
| Lowest water temperature inside polygon | `tsr.LOWTW2D` | result | Time-varying; WQ simulations |
| Lowest unionised ammoniacal nitrogen inside polygon | `tsr.LOWUNNH32D` | result | Time-varying; WQ simulations |

#### Summary water quality results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Max \<SFX\> flow through polygon boundary | `tsr.MAXFLOWMC<SFX>2D` | result | Summary; WQ simulations |
| Max \<CFX\> dissolved flow through polygon boundary | `tsr.MAXFLOWMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Max \<PPP\> dissolved flow through polygon boundary | `tsr.MAXFLOWMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Max \<CFX\>\<SFX\> flow through polygon boundary | `tsr.MAXFLOWMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Max \<PPP\>\<SFX\> flow through polygon boundary | `tsr.MAXFLOWMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Min \<SFX\> flow through polygon boundary | `tsr.MINFLOWMC<SFX>2D` | result | Summary; WQ simulations |
| Min \<CFX\> dissolved flow through polygon boundary | `tsr.MINFLOWMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Min \<PPP\> dissolved flow through polygon boundary | `tsr.MINFLOWMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Min \<CFX\>\<SFX\> flow through polygon boundary | `tsr.MINFLOWMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Min \<PPP\>\<SFX\> flow through polygon boundary | `tsr.MINFLOWMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Max \<SFX\> mass inside polygon | `tsr.MAXMASSMC<SFX>2D` | result | Summary; WQ simulations |
| Max \<CFX\> dissolved mass inside polygon | `tsr.MAXMASSMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Max \<PPP\> dissolved mass inside polygon | `tsr.MAXMASSMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Max \<CFX\>\<SFX\> mass inside polygon | `tsr.MAXMASSMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Max \<PPP\>\<SFX\> mass inside polygon | `tsr.MAXMASSMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Min \<SFX\> mass inside polygon | `tsr.MINMASSMC<SFX>2D` | result | Summary; WQ simulations |
| Min \<CFX\> dissolved mass inside polygon | `tsr.MINMASSMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Min \<PPP\> dissolved mass inside polygon | `tsr.MINMASSMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Min \<CFX\>\<SFX\> mass inside polygon | `tsr.MINMASSMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Min \<PPP\>\<SFX\> mass inside polygon | `tsr.MINMASSMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Max highest concentration \<SFX\> inside polygon | `tsr.MAXHIGHMC<SFX>2D` | result | Summary; WQ simulations |
| Max highest concentration \<CFX\> dissolved inside polygon | `tsr.MAXHIGHMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Max highest concentration \<PPP\> dissolved inside polygon | `tsr.MAXHIGHMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Max highest concentration \<CFX\>\<SFX\> inside polygon | `tsr.MAXHIGHMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Max highest concentration \<PPP\>\<SFX\> inside polygon | `tsr.MAXHIGHMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Max highest coliforms inside polygon | `tsr.MAXHIGHMCCOLDIS2D` | result | Summary; WQ simulations |
| Max highest pH inside polygon | `tsr.MAXHIGHPH2D` | result | Summary; WQ simulations |
| Max highest water temperature inside polygon | `tsr.MAXHIGHTW2D` | result | Summary; WQ simulations |
| Min lowest concentration \<SFX\> inside polygon | `tsr.MINLOWMC<SFX>2D` | result | Summary; WQ simulations |
| Min lowest concentration \<CFX\> dissolved inside polygon | `tsr.MINLOWMC<CFX>DIS2D` | result | Summary; WQ simulations |
| Min lowest concentration \<PPP\> dissolved inside polygon | `tsr.MINLOWMC<PPP>DIS2D` | result | Summary; WQ simulations |
| Min lowest concentration \<CFX\>\<SFX\> inside polygon | `tsr.MINLOWMC<CFX><SFX>2D` | result | Summary; WQ simulations |
| Min lowest concentration \<PPP\>\<SFX\> inside polygon | `tsr.MINLOWMC<PPP><SFX>2D` | result | Summary; WQ simulations |
| Min lowest coliforms inside polygon | `tsr.MINLOWMCCOLDIS2D` | result | Summary; WQ simulations |
| Min lowest pH inside polygon | `tsr.MINLOWPH2D` | result | Summary; WQ simulations |
| Min lowest water temperature inside polygon | `tsr.MINLOWTW2D` | result | Summary; WQ simulations |

### Permeable Zone Results (2D) (`hw_2d_permeable_zone`)

#### Time-varying results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Average infiltration volume rate | `tsr.AVGINFRATE2D` | result | Time-varying |
| Cumulative infiltration | `tsr.CUMINF2D` | result | Time-varying; = CUMINFVOL2D divided by zone area |
| Cumulative infiltration volume | `tsr.CUMINFVOL2D` | result | Time-varying |
| Instantaneous infiltration rate | `tsr.INFVOLRATE2D` | result | Time-varying; may show spikes near save timesteps |

#### Summary (non time-varying) results

| UI / Meaning | Database Field | Type | Notes |
|--------------|----------------|------|-------|
| Maximum instantaneous infiltration rate | `tsr.MAXINFVOLRATE2D` | result | Summary |
| Minimum instantaneous infiltration rate | `tsr.MININFVOLRATE2D` | result | Summary |
| Area in 2D zone | `tsr.ZONE_AREA2D` | result | Summary; actual meshed area used in calculations |
