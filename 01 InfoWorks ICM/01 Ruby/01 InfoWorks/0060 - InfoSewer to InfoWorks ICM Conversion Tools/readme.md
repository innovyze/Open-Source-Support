# InfoSewer to InfoWorks ICM Import Tool

**Import InfoSewer models into InfoWorks ICM with multi-scenario support**

**Last Updated**: November 2025

---

## About This Tool

This tool is a **completely refreshed version** of the InfoSewer import workflow. The original workflow, last updated in October 2024, required multiple manual steps across several tools. This new tool streamlines everything into a single script.

### Key Improvements Over Previous Workflow

| Previous Workflow (Oct 2024) | This Tool |
|------------------------------|-----------|
| Manual DBF → CSV conversion in Excel | ✅ Direct DBF reading (no Excel needed) |
| Manual shapefile export via ArcCatalog | ✅ Direct geometry import from DBF files |
| Run 4 separate scenario import scripts | ✅ Multi-scenario import built-in |
| Track which scenarios to create | ✅ Interactive scenario selection dialog |
| Multiple manual steps, slow | ✅ Significantly faster |

---

## Quick Start

1. **Download the tool** and save these files/folders to the same location:
   - `InfoSewer_Import_UI.rb` (main script)
   - `lib/` folder (required helper modules)
   - `field_mappings/` folder (required configuration files)
   - Optional: `import_active_network_selection_lists.rb` and `import_query_set_selection_lists.rb` (standalone scripts)
2. **Open InfoWorks ICM**
3. **Create a new blank InfoWorks network**
4. **Network → Run Ruby Script**
5. **Select:** `InfoSewer_Import_UI.rb`
6. **Follow the dialogs:**
   - Choose your `.IEDB` folder
   - Select field mappings folder
   - Choose scenarios to import
   - Confirm import

---

## What It Does

### Automated ✅
- Imports complete BASE network geometry (nodes, links, vertices)
- Imports all node and link properties from InfoSewer
- Creates subcatchments for all manholes
- Converts pumps from conduits with curves and control levels
- Sets node types (Manhole, WetWell, Outfall, Break)
- Imports multiple scenarios with scenario-specific data (MHHYD, PIPEHYD, PUMPHYD, WWELLHYD)
- Handles scenario parent inheritance automatically
- Fixes data quality issues (invalid links, case mismatches, non-compliant IDs, conduit lengths)
- Creates selection lists:
  - Root active network (`AN_Root`)
  - Active network per scenario (`AN_*`)
  - Query sets (`QS_*`)
  - User selection sets (`SS_*`)
- Applies post-import SQL transformations (node types, flooding, roughness, etc.)

### Requires Manual Review ⚠️
- **Wetwell curves**: If your InfoSewer model uses wetwell CURVES (not fixed diameter), manually set `chamber_area` and `shaft_area` in ICM after import
- **Inactive elements**: Selection lists identify active elements, but inactive elements remain in the network. Manually delete if needed.
- **FAC_TYPE 3 & 4 scenarios**: Intelli-Selection and Inherited facility types not yet supported

---

## Results

**Network** - Complete BASE network with all nodes, links, and subcatchments

**Scenarios** - Each imported scenario contains:
- Scenario-specific manhole loads (MHHYD)
- Scenario-specific pipe hydraulics (PIPEHYD)
- Scenario-specific pump data (PUMPHYD)
- Scenario-specific wetwell data (WWELLHYD)
- Parent inheritance handled automatically

**Selection Lists** - Help identify active elements:
- `AN_Root` - What was active when InfoSewer was last saved
- `AN_{scenario}` - Active elements for FAC_TYPE=0 scenarios
- `QS_{queryset}` - Query set results for FAC_TYPE=2 scenarios
- `SS_{selset}` - User-defined InfoSewer selection sets

**Post-Import:** Validate the network - should show no errors or warnings.

---

## Data Quality Handling

The tool automatically handles common data quality issues:

| Issue | How It's Handled |
|-------|------------------|
| Invalid link connectivity | Links referencing non-existent nodes removed with detailed warning |
| Case mismatches | Link node references matched case-insensitively (e.g., `Plant` → `PLANT`) |
| Missing vertex data | Links imported as straight lines with batch warning |
| Non-compliant node IDs | Dots replaced with underscores (e.g., `403-21.01` → `403-21_01`) |
| Short conduits (<3.3 ft) | Extended to InfoWorks minimum length |
| Long conduits (>16404 ft) | Reduced to InfoWorks maximum length |
| Pump control defaults | TYPE=0 pumps with no CONTROL data get defaults (OFF=1 ft, ON=3 ft) |

**All corrections are clearly reported in console output.**

---

## Files

- `InfoSewer_Import_UI.rb` - **Run this** (main import tool)
- `lib/*.rb` - Core modules (auto-loaded)
- `field_mappings/*.yaml` - Field mapping configurations
- `config.yaml` - Saved settings (auto-generated)

---

## Field Mappings

Field mappings are defined in YAML files (one per object type):

**Example: pipe.yaml**
```yaml
table: hw_conduit

defaults:
  conduit_type: 1         # Circular pipe
  roughness_type: 'N'     # Manning's N
  solution_model: Full

import:
  pipe:
    us_node_id: 'UPMANHOLE'
    ds_node_id: 'DNMANHOLE'
    conduit_width: 'DIAMETER'
  
  pipehyd:
    conduit_length: 'LENGTH'
    us_invert: 'UPSELEV'
    ds_invert: 'DNSELEV'
```

**Available mappings:** `manhole`, `outlet`, `wetwell`, `pipe`, `forcemain`, `pump`, `subcatchment`, `unit_hydrograph`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Wetwell limitation" notice | If using wetwell CURVES (not diameter), manually set `chamber_area` and `shaft_area` |
| Validation errors: pipe length | Should be auto-fixed - check console for "Fixed X short conduit(s)" messages |
| Validation errors: connectivity | Invalid links automatically removed - check console "DATA QUALITY WARNING" section |
| Scenario data not importing | Verify folder structure: `IEDB/Manhole/{MH_SET}/MHHYD.DBF`, check SCENARIO.DBF set names |
| DBF files won't load | Check files aren't locked, verify IEDB folder structure intact |
| Selection lists empty | Check FAC_TYPE in console output, verify ANODE/ALINK files exist in correct folders |
| Inactive elements still in network | **Expected** - selection lists identify active elements but don't delete inactive ones (manual deletion required) |

---

## Scenario Facility Types

InfoSewer uses different methods to define active elements per scenario:

| FAC_TYPE | Name | Import Behavior |
|----------|------|-----------------|
| **0** | Active Network | ✅ Creates `AN_{scenario}` selection lists from ANODE/ALINK files |
| **1** | Entire Network | ✅ All elements active (no selection list needed) |
| **2** | Query Set | ✅ Creates `QS_{queryset}` selection lists by evaluating queries |
| **3** | Intelli-Selection | ⚠️ Not yet supported |
| **4** | Inherited | ⚠️ Not yet supported |

**Console shows facility type summary for your model during import.**

---

## What Gets Imported

### BASE Scenario
**Important**: The tool imports the **complete BASE network** by reading all elements from `MANHOLE.DBF`, `PIPE.DBF`, `WWELL.DBF`, etc. It does NOT use `ANODE.DBF`/`ALINK.DBF` for BASE (those track active elements per scenario). This ensures BASE is always complete regardless of which scenario was last active in InfoSewer.

| Data Type | Source Files | Details |
|-----------|-------------|---------|
| Manholes | MANHOLE, MHHYD | Geometry, inverts, ground levels, loads, patterns |
| Outlets | NODE, MANHOLE | Outfall nodes |
| Wet Wells | WWELL, WWELLHYD | Pump stations with chamber geometry |
| Pipes | PIPE, PIPEHYD, VERTEX | Conduit geometry, roughness, vertices |
| Force Mains | PIPE, PIPEHYD | Forcemain solution model, HW roughness |
| Pumps | PUMP, PUMPHYD, CONTROL | Converted from conduits, curves, on/off levels |
| Subcatchments | Auto-created | 0.10 ac placeholder subcatchments for all manholes |
| RDII | HYDROGRH | Unit hydrographs for RDII analysis |

### Scenario-Specific Data
Each scenario imports data from scenario-specific folders with parent inheritance:

| Data Type | Source Folder/Files | Details |
|-----------|-------------------|---------|
| Manhole Loads | IEDB/Manhole/{MH_SET}/MHHYD | LOAD1-10, PATTERN1-10 per scenario |
| Pipe Hydraulics | IEDB/Pipe/{PIPE_SET}/PIPEHYD | Inverts, lengths, diameters, roughness |
| Pump Hydraulics | IEDB/Pump/{PUMP_SET}/PUMPHYD | Capacity, curves, pump-specific data |
| Wetwell Hydraulics | IEDB/Wetwell/{WELL_SET}/WWELLHYD | Chamber elevations, areas |

**Parent Inheritance**: If a set field is blank (e.g., `PIPE_SET = ""`), the tool traverses up the parent chain until it finds a value or defaults to "BASE".

### Post-Import Transformations
All transformations applied automatically via SQL:
- Node types set (Outfall, Break)
- Flooding set to 'Stored' (surface ponding)
- Subcatchments created with `system_type = 'sanitary'`
- Pipes < 3.3 ft extended, pipes > 16404 ft reduced
- Force main nodes set to 'Break' type
- Pump downstream nodes set to 'Break' type
- Wetwell areas calculated from diameter

---

## Limitations

### Tool Limitations
1. **Inactive Elements Not Deleted**: Selection lists identify active elements, but inactive elements remain in the network. Manual deletion required if you want to remove them.
2. **FAC_TYPE = 3 (Intelli-Selection)**: Not supported - these scenarios will import but without active element filtering. Manual selection required.
3. **FAC_TYPE = 4 (Inherited)**: Not supported - these scenarios will import but without active element filtering. Manual selection required.
4. **Wetwell Curves**: Tool assumes fixed diameter. If your model uses wetwell curves, `chamber_area` and `shaft_area` will calculate as 0 and must be set manually after import.
5. **Query Set Complexity**: Query sets with nested logic or field-specific operators may not evaluate correctly. Review selection lists after import.
6. **Node/Link ID Constraints**: IDs are sanitized for ICM compatibility (dots replaced with underscores). Original IDs with special characters may be modified.

### InfoSewer Data Limitations
1. **RDII Unit Hydrographs**: Imported but not automatically linked to subcatchments (InfoSewer stores linkage in GIS layer, not in DBF files).
2. **Time Patterns**: Not imported (ICM stores patterns in a format requiring Exchange script for import).
3. **Rainfall Events**: Not imported (ICM stores rainfall data in a format requiring Exchange script for import).
4. **Trade/Wastewater Profiles**: Not imported (similar to time patterns, requires Exchange script).
5. **Custom Pipe/Manhole Shapes**: Only standard circular pipes supported. Custom cross-sections from InfoSewer shape libraries not imported.
6. **Simulation Settings**: Run options (time steps, output settings) not transferred - must be configured manually in ICM.
7. **Model Calibration Data**: Observed data, calibration targets not imported.

---

## InfoSewer File Structure

The tool expects standard InfoSewer `.IEDB` folder structure:

```
YourModel.IEDB/
├── SCENARIO.DBF              # Scenario definitions
├── NODE.DBF, MANHOLE.DBF     # Nodes
├── LINK.DBF, PIPE.DBF        # Links
├── VERTEX.DBF                # Link vertices
├── MHHYD.DBF, PIPEHYD.DBF    # Hydraulics
├── WWELL.DBF, WWELLHYD.DBF   # Wetwells
├── PUMP.DBF, PUMPHYD.DBF     # Pumps
├── CONTROL.DBF               # Pump controls
├── HYDROGRH.DBF              # RDII unit hydrographs
├── SELSET.DBF                # Selection set definitions
├── QRYSET.DBF, QUERY.DBF     # Query set definitions
├── ANODE.DBF, ALINK.DBF      # Root active network (last active scenario)
├── Manhole/
│   └── {MH_SET}/MHHYD.DBF    # Scenario-specific manhole data
├── Pipe/
│   └── {PIPE_SET}/PIPEHYD.DBF
├── Pump/
│   └── {PUMP_SET}/PUMPHYD.DBF
├── Wetwell/
│   └── {WELL_SET}/WWELLHYD.DBF
├── Scenario/
│   └── {NAME}/
│       ├── ANODE.DBF         # Active nodes for FAC_TYPE=0
│       └── ALINK.DBF         # Active links for FAC_TYPE=0
└── SS/
    └── {SET_NAME}/
        ├── ANODE.DBF         # Selection set members
        └── ALINK.DBF
```

**The tool reads DBF files directly - no CSV conversion or Excel required.**

---

*Note: This documentation was AI-generated and reviewed by the script author.*