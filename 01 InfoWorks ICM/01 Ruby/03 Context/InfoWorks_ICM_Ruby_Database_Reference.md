# InfoWorks ICM Ruby Database Reference Guide for LLM Agents

**Last Updated:** January 16, 2026

**Load Priority:** LOOKUP - Load when querying table names or object types  
**Load Condition:** CONDITIONAL - When script accesses row_objects() or model_object_from_type_and_id()

## Purpose

This guide provides **database and network object reference** for InfoWorks ICM Ruby scripting.

**For LLMs:** Use this file to:
- Look up table names for `row_objects('TABLE_NAME')` calls
- Find Model Object Type names for `model_object_from_type_and_id('TYPE', id)`
- Distinguish between InfoWorks (hw_*) and SWMM (sw_*) table names
- Understand ShortCode notation used in scripting paths

**Prerequisite:** Read `Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_Ruby_Lessons_Learned.md` - Read FIRST - Critical gotchas
- `InfoWorks_ICM_Ruby_API_Reference.md` - WSModelObject, WSOpenNetwork methods
- `InfoWorks_ICM_Ruby_Pattern_Reference.md` - Patterns using table names (PAT_DATA_FETCH_004, etc.)
- `InfoWorks_ICM_Ruby_Tutorial_Context.md` - Complete examples using database objects
- `InfoWorks_ICM_Ruby_Glossary.md` - Model Object Type terminology

## Two Types of Objects

### 1. Database Model Objects
Accessed via database: `db.model_object_from_type_and_id(TYPE, id)`
- Model Groups, Networks, Rainfall Events, Runs, Sims, etc.
- See **Model Object Types Reference** section below

### 2. Network Objects
Accessed via network: `net.row_objects(TABLE_NAME)`
- Nodes, Links, Subcatchments within a network
- See **Network Table Names Reference** section below

---

## Model Object Types Reference

**Purpose:** Use these when working with database model objects (Model Groups, Networks, Rainfall, etc.)

### Critical Distinction

- **Type** - Used with `db.model_object_from_type_and_id(TYPE, id)`
- **ShortCode** - Used in scripting paths like `'>MODG~Model group>NNET~Model network'`
- **Description** - What you see in the UI (sometimes different from Type)

### Type Names are Case-Sensitive!

```ruby
# CORRECT
db.model_object_from_type_and_id('Model Group', 1)
db.model_object_from_type_and_id('Rainfall Event', 5)

# WRONG - will fail
db.model_object_from_type_and_id('model group', 1)      # wrong case
db.model_object_from_type_and_id('Model network', 5)    # wrong case
```

### Usage Examples

```ruby
# Access by path
group = db.model_object('>MODG~Model group')
network = db.model_object('>MODG~My Group>NNET~My Network')
rainfall = db.model_object('>MODG~My Group>RAIN~Storm Event')

# Access by Type and ID
group = db.model_object_from_type_and_id('Model Group', 1)
network = db.model_object_from_type_and_id('Model Network', 5)
rainfall = db.model_object_from_type_and_id('Rainfall Event', 10)
sim = db.model_object_from_type_and_id('Sim', 100)

# Navigate to parent
parent_type = mo.parent_type
parent_id = mo.parent_id
parent = db.model_object_from_type_and_id(parent_type, parent_id)

# Export/Import model objects
rainfall_mo = db.model_object_from_type_and_id('Rainfall Event', 5)
rainfall_mo.export('C:/exports/rainfall.csv', 'CSV')

parent_group = db.model_object_from_type_and_id('Model Group', 1)
parent_group.import_new_model_object('Rainfall Event', 'New Rainfall', '', 'C:/imports/rainfall.csv')
```

### InfoWorks ICM Model Object Types

| Type | ShortCode | Type | ShortCode |
|------|-----------|------|-----------|
| Action List | ACTL | Manifest | MAN |
| Alert Definition List | ADL | Manifest Deployment | MAND |
| Alert Instance List | AIL | Master Group | MASG |
| Asset Group | AG | Model Group | MODG |
| Asset Network | ASSETNET | Model Inference | INFR |
| Asset Network Template | ASSETTMP | Model Network | NNET |
| Asset Validation | ASSETVAL | Model Network Template | NNT |
| Assimilation | ASSIM | Model Validation | ENV |
| Calibration | PDMC | Observed Depth Event | OBD |
| Collection Cost Estimator | COST | Observed Flow Event | OBF |
| Collection Inference | CINF | Observed Velocity Event | OBV |
| Collection Network | CNN | Pipe Sediment Data | PSD |
| Collection Network Template | CNTMP | Point Selection | PTSEL |
| Collection Validation | VAL | Pollutant Graph | PGR |
| Custom Graph | CGDT | Print Layout | PTL |
| Custom Report | CR | Rainfall Event | RAIN |
| Damage Calculation Results | DMGCALC | Regulator | REG |
| Damage Function | DMGFUNC | Rehabilitation Planner | REHABP |
| Dashboard | DASH | Risk Analysis Run | RAR |
| Episode Collection | EPC | Risk Assessment | RISK |
| Flow Survey | FS | Risk Calculation Results | RISKCALC |
| Geo Explorer | NGX | Run | RUN |
| Graph | GDT | Selection List | SEL |
| Gridded Ground Model | GGM | Sim | SIM |
| Ground Infiltration | IFN | Sim Stats | STAT |
| Ground Model | GM | Statistics Template | ST |
| Infinity Configuration | INFINITY | Stored Query | SQL |
| Inflow | INF | Theme | THM |
| Initial Conditions 1D | IC1D | Time Varying Data | TVD |
| Initial Conditions 2D | IC2D | Trade Waste | TW |
| Initial Conditions Catchment | ICCA | TSDB | TSDB |
| Label List | LAB | TSDB Spatial | TSDBS |
| Layer List | LL | UPM River Data | UPMRD |
| Level | LEV | UPM Threshold | UPTHR |
| Lifetime Estimator | LIFEE | Waste Water | WW |
| Live Group | LG | Workspace | WKSP |

---

## Network Table Names Reference

**Purpose:** Use these when working with network objects (nodes, links, subcatchments within a network)

### Critical Distinction

Ruby requires **database table names**, NOT UI display names:

```ruby
# WRONG - Don't use UI names
net.row_objects('Conduit')        # Will fail!

# CORRECT - Use database table name  
net.row_objects('hw_conduit')     # Works!
```

### Network Types

- **InfoWorks Networks** - Table names start with `hw_` (e.g., `'hw_conduit'`)
- **SWMM Networks** - Table names start with `sw_` (e.g., `'sw_conduit'`)

### Lookup Methodology

**Step 1:** Identify object type from user query  
**Step 2:** Find **Database Table Name** in tables below  
**Step 3:** Search Help for "Data Fields Topic" to find field names  
**Step 4:** Use "Database field" column (NOT "Field Name") from Help

**Help Base URL:** https://help.autodesk.com/view/IWICMS/2026/ENU/

**Source:** https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-8F131349-1247-477B-97A5-62B9AF41D9E4

### InfoWorks Network (`hw_*` tables)

**Nodes Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Node | `hw_node` | Node Data Fields (InfoWorks) |

**Links Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Blockage | `hw_blockage` | Blockage Data Fields |
| Bridge Blockage | `hw_bridge_blockage` | Bridge Blockage Data Fields |
| Bridge | `hw_bridge` | Bridge Data Fields |
| Bridge inlet | `hw_bridge_inlet` | Bridge Inlet Data Fields |
| Bridge opening | `hw_bridge_opening` | Bridge Opening Data Fields |
| Bridge outlet | `hw_bridge_outlet` | Bridge Outlet Data Fields |
| Channel | `hw_channel` | Channel Data Fields |
| Channel shape | `hw_channel_shape` | Channel Shape Data Fields |
| Conduit | `hw_conduit` | Conduit Data Fields (InfoWorks) |
| Culvert inlet | `hw_culvert_inlet` | Culvert Inlet Data Fields |
| Culvert outlet | `hw_culvert_outlet` | Culvert Outlet Data Fields |
| Flap valve | `hw_flap_valve` | Flap Valve Data Fields (InfoWorks) |
| Flow efficiency | `hw_flow_efficiency` | Flow Efficiency Table Data Fields |
| Flume | `hw_flume` | Flume Data Fields |
| Head discharge | `hw_head_discharge` | Head Discharge Tables |
| Headloss curve | `hw_headloss` | Headloss Curve Data Fields |
| Inline bank | `hw_inline_bank` | Inline Bank Data Fields |
| Irregular weir | `hw_irregular_weir` | Irregular Weir Data Fields |
| Orifice | `hw_orifice` | Orifice Data Fields (InfoWorks) |
| Pump | `hw_pump` | Pump Data Fields (InfoWorks) |
| River Reach | `hw_river_reach` | River Reach Data Fields (InfoWorks) |
| Screen | `hw_screen` | Screen Data Fields |
| Sediment grading | `hw_sediment_grading` | Sediment Grading Data Fields |
| Shape | `hw_shape` | Shape Data Fields |
| Siphon | `hw_siphon` | Siphon Data Fields |
| Sluice | `hw_sluice` | Sluice Data Fields |
| User control | `hw_user_control` | User-Defined Control Data Fields |
| Weir | `hw_weir` | Weir Data Fields (InfoWorks) |

**Subcatchments Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Build-up/washoff land use | `hw_swmm_land_use` | Build-up/Washoff Land Use Data Fields |
| Land use | `hw_land_use` | Land Use Data Fields (InfoWorks) |
| Ground infiltration | `hw_ground_infiltration` | Ground Infiltration Data Fields |
| PDM Descriptor | `hw_pdm_descriptor` | PDM Descriptor Data Fields |
| Monthly RTK hydrograph | `hw_unit_hydrograph_month` | Monthly RTK Hydrograph Data Fields |
| RTK hydrograph | `hw_unit_hydrograph` | RTK Hydrograph Data Fields |
| Runoff surfaces | `hw_runoff_surface` | Runoff Surfaces Data Fields |
| Snow pack | `hw_snow_pack` | Snow Pack Data Fields (InfoWorks) |
| Subcatchment | `hw_subcatchment` | Subcatchment Data Fields (InfoWorks) |
| SUDS controls | `hw_suds_control` | SUDS Controls Data Fields |

**Polygons Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Polygon | `hw_polygon` | Polygon Data Fields (InfoWorks) |
| Storage area | `hw_storage_area` | Storage Area Data Fields |
| 2D zone | `hw_2d_zone` | 2D Zone Data Fields (InfoWorks) |
| Mesh zone | `hw_mesh_zone` | Mesh Zone Data Fields (InfoWorks) |
| Mesh level zone | `hw_mesh_level_zone` | Mesh Level Zone Data Fields (InfoWorks) |
| Roughness zone | `hw_roughness_zone` | Roughness Zone Data Fields (InfoWorks) |
| Roughness definitions | `hw_roughness_definition` | Roughness Definition Data Fields |
| IC zone - hydraulics (2D) | `hw_2d_ic_polygon` | IC Zone - hydraulics (2D) Data Fields |
| IC zone - water quality (2D) | `hw_2d_wq_ic_polygon` | IC Zone - water quality (2D) Data Fields |
| IC zone - infiltration (2D) | `hw_2d_inf_ic_polygon` | IC Zone - infiltration (2D) Data Fields |
| IC zone - sedimentation (2D) | `hw_2d_sed_ic_polygon` | IC Zone - Sediment (2D) Data Fields |
| Porous polygon | `hw_porous_polygon` | Porous Polygon Data Fields (InfoWorks) |
| Infiltration zone (2D) | `hw_2d_infiltration_zone` | Infiltration Zone (2D) Data Fields |
| Infiltration surface (2D) | `hw_2d_infil_surface` | Infiltration Surface (2D) Data Fields |
| Turbulence zone (2D) | `hw_2d_turbulence_zone` | Turbulence Zone (2D) Data Fields |
| Turbulence model (2D) | `hw_2d_turbulence_model` | Turbulence Model (2D) Data Fields |
| Permeable zone (2D) | `hw_2d_permeable_zone` | Permeable Zone (2D) Data Fields |
| TVD connector | `hw_tvd_connector` | TVD Connector Data Fields (InfoWorks) |
| Spatial rain zone | `hw_spatial_rain_zone` | Spatial Rain Zone Data Fields (InfoWorks) |
| Spatial rain source | `hw_spatial_rain_source` | Spatial Rain Source Data Fields (InfoWorks) |
| Network results polygon (2D) | `hw_2d_results_polygon` | Network Results Polygon (2D) Data Fields |
| Risk impact zone | `hw_risk_impact_zone` | Risk Impact Zone Data Fields |
| ARMA | `hw_arma` | ARMA Data Fields |
| Building | `hw_building` | Building Data Fields (InfoWorks) |

**Lines Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| General line | `hw_general_line` | General Line Data Fields (InfoWorks) |
| Cross section line | `hw_cross_section_survey` | Cross Section Line Data Fields |
| Bank line | `hw_bank_survey` | Bank Line Data Fields |
| Porous wall | `hw_porous_wall` | Porous Wall Data Fields (InfoWorks) |
| Base linear structure (2D) | `hw_2d_linear_structure` | Base Linear Structure (2D) Data Fields |
| Sluice linear structure (2D) | `hw_2d_sluice` | Sluice Linear Structure (2D) Data Fields |
| Bridge linear structure (2D) | `hw_2d_bridge` | Bridge Linear Structure (2D) Data Fields |
| 2D boundary | `hw_2d_boundary_line` | 2D Boundary Line Data Fields |
| Network results line (2D) | `hw_2d_results_line` | Network Results Line (2D) Data Fields |
| 2D line source | `hw_2d_line_source` | 2D Line Source Data Fields |
| 2D line connect | `hv_2d_line_connect` | 2D Line Connect Data Fields |
| Head unit flow | `hw_head_unit_discharge` | Head Unit Flow Data Fields |

**Points Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| General point | `hw_general_point` | General Point Data Fields |
| 2D point source | `hw_2d_point_source` | 2D Point Source Data Fields |
| Network results point (1D) | `hw_1d_results_point` | Network Results Point (1D) Data Fields |
| Network results point (2D) | `hw_2d_results_point` | Network Results Point (2D) Data Fields |
| Damage receptor | `hw_damage_receptor` | Damage Receptor Data Fields |

### SWMM Network (`sw_*` tables)

**Nodes Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Node | `sw_node` | Node Data Fields (SWMM) |
| Unit hydrograph group | `sw_unit_hydrograph_group` | Unit Hydrograph Group Data Fields (SWMM) |
| Unit hydrograph | `sw_unit_hydrograph` | Unit Hydrograph Data Fields (SWMM) |
| Storage curve | `sw_storage_curve` | Storage Curve Data Fields (SWMM) |
| Tidal curve | `sw_tidal_curve` | Tidal Curve Data Fields (SWMM) |

**Links Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Conduit | `sw_conduit` | Conduit Data Fields (SWMM) |
| Control curve | `sw_control_curve` | Control Curve Data Fields (SWMM) |
| Shape curve | `sw_shape_curve` | Shape Curve Data Fields (SWMM) |
| Orifice | `sw_orifice` | Orifice Curve Data Fields (SWMM) |
| Outlet | `sw_outlet` | Outlet Curve Data Fields (SWMM) |
| Pump | `sw_pump` | Pump Data Fields (SWMM) |
| Pump curve | `sw_pump_curve` | Pump Curve Data Fields (SWMM) |
| Rating curve | `sw_rating_curve` | Rating Curve Data Fields (SWMM) |
| Transect | `sw_transect` | Transect Data Fields (SWMM) |
| Weir | `sw_weirs` | Weir Data Fields (SWMM) |
| Weir curve | `sw_curve_weir` | Weir Curve Data Fields (SWMM) |

**Subcatchments Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Subcatchment | `sw_subcatchment` | Subcatchment Data Fields (SWMM) |
| Land use | `sw_land_use` | Land Use Data Field (SWMM) |
| Pollutant | `sw_pollutant` | Pollutant Data Fields (SWMM) |
| Snow pack | `sw_snow_pack` | Snow Pack Data Fields (SWMM) |
| LID control | `sw_suds_control` | LID Controls Data Fields (SWMM) |
| Underdrain curve | `sw_curve_underdrain` | Underdrain Curve Data Fields (SWMM) |
| Aquifier | `sw_aquifer` | Aquifer Data Fields (SWMM) |
| Soil | `sw_soil` | Soil Data Fields (SWMM) |

**Polygons Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Polygon | `sw_polygon` | Polygon Data Fields (SWMM) |
| TVD connector | `sw_tvd_connector` | TVD Connector Data Fields (SWMM) |
| Spatial rain zone | `sw_spatial_rain_zone` | Spatial Rain Zone Data Fields (SWMM) |
| Spatial rain source | `sw_spatial_rain_source` | Spatial Rain Source Data Fields (SWMM) |
| 2D zone | `sw_2d_zone` | 2D Zone Data Fields (SWMM) |
| Roughness zone | `sw_roughness_zone` | Roughness Zone Data Fields (SWMM) |
| Roughness definitions | `sw_roughness_definition` | Roughness Definition Data Fields (SWMM) |
| Mesh zone | `sw_mesh_zone` | Mesh Zone Data Fields SWMM) |
| Mesh level zone | `sw_mesh_level_zone` | Mesh Level Zone Data Fields (SWMM) |
| Porous polygon | `sw_porous_polygon` | Porous Polygon Data Fields (SWMM) |

**Lines Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| General line | `sw_general_line` | General Line Data Fields (SWMM) |
| Porous wall | `sw_porous_wall` | Porous Wall Data Fields (SWMM) |
| 2D boundary | `sw_2d_boundary_line` | 2D Boundary Line Data Fields (SWMM) |
| Head unit flow | `sw_head_unit_discharge` | Head Unit Flow Data Fields (SWMM) |

**Points Grid:**
| Network Object | Database Table Name | Data Fields Topic |
|----------------|---------------------|-------------------|
| Rain gage | `sw_raingage` | Rain Gage Data Fields (SWMM) |

---

## Working Example

**User Query:** "Update the user control modular limit"

**LLM Process:**
1. Object type: User Control  
2. Network: InfoWorks (default)  
3. Lookup: Links Grid → `hw_user_control`  
4. Search Help: "User-Defined Control Data Fields"  
5. Find field: `modular_limit` (from Database field column)

**Result:**
```ruby
net.row_objects('hw_user_control').each do |control|
  puts control.modular_limit
end
```

---

## Universal Fields (All Objects)

**User Fields:**
- `user_text_1` through `user_text_10`
- `user_number_1` through `user_number_10`  

**System Fields:**
- `oid` - Object identifier
- `selected` - Selection state

**Flag Fields:**
- Most fields have a corresponding flag field with `_flag` suffix
- Example: `diameter` has `diameter_flag`
- Flags store annotation text for the field

```ruby
# Access field and its flag
conduit.diameter = 300
conduit.diameter_flag = 'Estimated'
```

---

## Results Field Codes

**Purpose:** Results methods require specific field codes (not UI display names)

**Common InfoWorks Results Fields:**
- `'depnod'` - Node depth
- `'level'` - Node level  
- `'flood'` - Node flooding
- `'qlink'` - Link flow
- `'vlink'` - Link velocity
- `'dlink'` - Link depth

**Discovery:**
```ruby
# List all available result field names
result_fields = net.list_result_field_names
result_fields.each { |name| puts name }
```

**See:** Autodesk Help > Results Field Reference for complete listings

---

**Note:** Always verify table and field names against latest Autodesk Help documentation.
