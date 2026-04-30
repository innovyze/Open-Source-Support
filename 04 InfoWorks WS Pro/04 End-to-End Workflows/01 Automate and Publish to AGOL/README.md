# Automate WS Pro Simulations → ArcGIS Online

Automates a three-step weekly pipeline for InfoWorks WS Pro:

1. **Create & run** a new simulation in a Wesnet Run Group
2. **Export** maximum simulation results to a flat shapefile ZIP
3. **Publish** the ZIP to ArcGIS Online as a hosted feature layer (overwriting the previous week)

---

## Files

| File | Description |
|------|-------------|
| `WS_Pro_Create_and_Run_Weekly_Simulation.rb` | Step 1 — Exchange Ruby script |
| `WS_Pro_Export_Simulation_Results_to_Shapefile.rb` | Step 2 — Exchange Ruby script |
| `Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py` | Step 3 — Python script |
| `Run_All_Weekly_WS_Pro_Workflow.bat` | Runs all three steps in sequence |

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| InfoWorks WS Pro 2024+ | Exchange mode (`WSProExchange.exe`) |
| Python 3.8+ | `pip install arcgis` |
| ArcGIS Online account | With publishing privileges |

---

## Setup (5 steps)

### Step 1 — Configure the Ruby simulation script

Open `WS_Pro_Create_and_Run_Weekly_Simulation.rb` and fill in the `CONFIGURATION` block:

```ruby
DB_PATH         = 'cloud://Your Org@orgid/database'  # your WS Pro database path
RUN_GROUP_ID    = 1234   # Model Object ID of your Wesnet Run Group
TEMPLATE_RUN_ID = 5678   # Model Object ID of any existing run (used to confirm type)
NETWORK_ID      = 1001   # Model Object ID of the network geometry
CONTROL_ID      = 1002   # Model Object ID of the control
DEMAND_ID       = 1003   # Model Object ID of the demand diagram
SIMULATION_DAYS = 7      # simulation length in days
MARKER_FILE     = 'C:\WS Pro Results\last_export_run_id.txt'
```

> **Finding Model Object IDs**: In WS Pro Explorer, right-click any object → Properties → ID.

### Step 2 — Configure the Ruby export script

Open `WS_Pro_Export_Simulation_Results_to_Shapefile.rb` and fill in the `CONFIGURATION` block:

```ruby
DB_PATH      = 'cloud://Your Org@orgid/database'
RUN_GROUP_ID = 1234                   # same Run Group as Step 1
OUTPUT_BASE  = 'C:\WS Pro Results'    # folder for shapefiles and ZIP
EXPORT_SUBDIR = 'weekly_ws_pro'       # subfolder name for raw shapefiles
ZIP_NAME      = 'weekly_ws_pro.zip'   # ZIP filename (must match Step 3)
```

### Step 3 — Configure the Python publish script

Open `Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py` and fill in the `CONFIGURATION` block:

```python
EXPORT_DIR          = r"C:\WS Pro Results"               # must match OUTPUT_BASE in Step 2
ZIP_FILENAME        = "weekly_ws_pro.zip"                # must match ZIP_NAME in Step 2
AGOL_URL            = "https://www.arcgis.com"           # or your Enterprise Portal URL
AGOL_USERNAME       = "your.username"                    # or leave blank for env variable
AGOL_FOLDER_ID      = "abcdef1234567890abcdef1234567890" # from your AGOL folder URL
FEATURE_LAYER_TITLE = "Weekly WS Pro Simulation Results" # display name in AGOL
```

> **Finding your AGOL Folder ID**: Browse to the target folder in AGOL. The ID appears in the URL:  
> `https://org.maps.arcgis.com/home/content.html?folder=<FOLDER_ID>`

Also update the `_FEET_PRJ` and `_METRES_PRJ` constants with the correct named CRS WKT for your
project's coordinate system. Export a shapefile manually from WS Pro, open the `.prj` file in a
text editor, and use that WKT as a guide.

### Step 4 — Configure the batch file

Open `Run_All_Weekly_WS_Pro_Workflow.bat` and set:

```batch
set "AGOL_URL=https://www.arcgis.com"
set "AGOL_USERNAME=your.username"
set "AGOL_PASSWORD=your_password"
```

### Step 5 — Run

Double-click `Run_All_Weekly_WS_Pro_Workflow.bat` or schedule it with Windows Task Scheduler.

---

## How It Works

```
Run_All_Weekly_WS_Pro_Workflow.bat
  │
  ├─ Step 1: WSProExchange.exe runs WS_Pro_Create_and_Run_Weekly_Simulation.rb
  │    • Creates a new Wesnet Run with today's date
  │    • Fires the simulation and waits for completion
  │    • Writes the run ID to OUTPUT_BASE\last_export_run_id.txt
  │
  ├─ Step 2: WSProExchange.exe runs WS_Pro_Export_Simulation_Results_to_Shapefile.rb
  │    • Reads the marker file to find the correct run
  │    • Exports peak results for all available WS tables (wn_node, wn_pipe, etc.)
  │    • Strips invalid DBF field names
  │    • Zips all shapefiles flat into OUTPUT_BASE\weekly_ws_pro.zip
  │
  └─ Step 3: Python runs Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py
       • Builds a clean temporary ZIP with a named .prj (required by AGOL)
       • Tries to overwrite the existing hosted feature layer
       • If that fails, deletes conflicting items and publishes fresh
       • Moves the new layer to the configured AGOL folder
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `WSRunScheduler not available` | Script not run via Exchange | Use `WSProExchange.exe ... /WS` |
| `Run Group ID 0 not found` | CONFIGURATION not filled in | Set all IDs in the CONFIGURATION block |
| `ArcGIS auth error` during export | WS Pro 2026 ODEC pipeline requirement | Set `AGOL_PASSWORD` env var; shapefiles still export if the error occurs after write |
| `Job failed` in AGOL publish | Invalid PRJ or DBF | Update `_FEET_PRJ` / `_METRES_PRJ` constants with your project's named CRS WKT |
| Layer published to wrong location | Incorrect PRJ WKT | Export manually from WS Pro, copy the `.prj` content to the script |
| `AGOL_PASSWORD is not set` | Missing env variable | Add `set "AGOL_PASSWORD=..."` to the `.bat` file |
