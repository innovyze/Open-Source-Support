# Automate ICM Sims – Daily Simulation Pipeline

This folder contains **anonymized, shareable copies** of the daily simulation workflow scripts. All usernames, passwords, model IDs, database paths, and organization-specific values have been removed and replaced with placeholders. Use these scripts as templates for your own ICM + ArcGIS Online deployments.

## Workflow Overview

The pipeline runs four scripts in sequence:

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `Download_NWS_Rainfall.rb` | Download NWS rainfall data and optionally import to ICM |
| 2 | `Create and Run Simulations.rb` | Create and run 24h and 48h ICM simulations |
| 3 | `Export 2D ICM Results.rb` | Export simulation results to shapefiles (24h.zip, 48h.zip) |
| 4 | `Publish_Shapefiles_to_AGOL.py` | Publish shapefiles to ArcGIS Online as hosted feature layers |

## Quick Start

### 1. Prerequisites

- **InfoWorks ICM** with ICMExchange.exe (e.g. 2026 or 2027)
- **Python 3.9–3.12** with `pip install arcgis` (Python 3.14 may not work)
- **ArcGIS Online** account with publish permissions
- **US locations** only (NWS covers US territories)

### 2. Configure Each Script

Edit the **CONFIGURATION** or **CUSTOMIZATION** section in each script:

| Script | Values to Set |
|--------|----------------|
| **Download_NWS_Rainfall.rb** | `LATITUDE`, `LONGITUDE`, `USER_AGENT`, `HISTORICAL_FILENAME`, `FORECAST_FILENAME`, optionally `ICM_DB_PATH`, `MODEL_GROUP_ID` |
| **Create and Run Simulations.rb** | `db_path`, `MODEL_GROUP_ID`, `RUN_TEMPLATE_24H_ID`, `RUN_TEMPLATE_48H_ID`, optionally `NETWORK_ID` |
| **Export 2D ICM Results.rb** | `db_path`, `MODEL_GROUP_ID`, `OUTPUT_BASE` |
| **Publish_Shapefiles_to_AGOL.py** | `AGOL_URL`, `AGOL_USERNAME`, `AGOL_PASSWORD`, `SHAPEFILE_EXPORT_DIR`, `AGOL_FOLDER_ID` |

### 3. Finding IDs and Paths

- **ICM database path**: Format `cloud://DatabaseName@orgId/region`. Get from ICM Connect to Database or connection string.
- **Model Group ID**: Right-click Model Group in ICM Explorer → Properties → Object ID.
- **Run template IDs**: Right-click each template run (24h and 48h) → Properties → Object ID.
- **AGOL folder ID**: Open the folder in ArcGIS Online; the URL contains `folder=xxxxxxxx`.

### 4. Running the Pipeline

**Option A – Run all scripts in order**

```batch
ICMExchange.exe "D:\Ruby Scripts\Automate ICM Sims\Download_NWS_Rainfall.rb" /ICM
ICMExchange.exe "D:\Ruby Scripts\Automate ICM Sims\Create and Run Simulations.rb" /ICM
ICMExchange.exe "D:\Ruby Scripts\Automate ICM Sims\Export 2D ICM Results.rb" /ICM
py -3.12 "D:\Ruby Scripts\Automate ICM Sims\Publish_Shapefiles_to_AGOL.py"
```

**Option B – Use the included batch file**

Double-click `Run_All_Daily_Workflow.bat` (included in this folder) or schedule it with Windows Task Scheduler. Edit the CONFIGURATION section at the top of the batch file to set your `EXCHANGE` path, Python version, and AGOL credentials.

## Path Consistency

- `OUTPUT_BASE` in Export 2D ICM Results.rb must match `SHAPEFILE_EXPORT_DIR` in Publish_Shapefiles_to_AGOL.py.
- Default: `shapefile_exports` subfolder in the same directory as the scripts.

## Security Notes

- Do **not** commit real passwords. Use environment variables (e.g. `AGOL_PASSWORD`) when possible.
- These anonymized scripts are safe to share or version-control; originals with real credentials should remain local or in a secure repo.

## Script-Specific Notes

- **Download_NWS_Rainfall.rb**: Set `ICM_DB_PATH = nil` to skip automatic ICM import.
- **Create and Run Simulations.rb**: Requires two template runs (24 Hour Yesterday Template, 48 Hour Forecast Template) in the Model Group.
- **Export 2D ICM Results.rb**: Exchange-only; must run via ICMExchange.exe, not from the ICM UI.
- **Publish_Shapefiles_to_AGOL.py**: Uses overwrite when a layer exists; otherwise deletes and republishes after a 2‑minute delay.
