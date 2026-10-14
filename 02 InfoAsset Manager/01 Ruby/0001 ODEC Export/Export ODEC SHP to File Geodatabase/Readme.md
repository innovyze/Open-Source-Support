# ODEC shapefile staging → new File Geodatabase (workaround)

Automates a **full sync** to a **new** `.gdb` when **File Geodatabase** / **Enterprise Geodatabase** ODEC export is only available in the IAM UI, not via Ruby to GDB directly.

### Client options (pick one ingest path)

| Goal | UI script | Exchange script | Batch helper |
|------|-----------|-----------------|--------------|
| **ArcGIS Pro** — ODEC → SHP → `.gdb` | [UI-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb](./UI-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb) (optional Pro ingest in prompt) | [IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb](./IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb) + [run_full_sync_arcgis.bat](./run_full_sync_arcgis.bat) | [run_ingest_shp_to_file_gdb_arcgis.bat](./run_ingest_shp_to_file_gdb_arcgis.bat) |
| **QGIS / GDAL** — ODEC → SHP → `.gdb` (no Esri licence) | [UI-odec_export_ex-SHP-for-GDB-sync-QGIS.rb](./UI-odec_export_ex-SHP-for-GDB-sync-QGIS.rb) (QGIS ingest on by default) | [IE-odec_export_ex-SHP-for-GDB-sync-QGIS.rb](./IE-odec_export_ex-SHP-for-GDB-sync-QGIS.rb) + [run_full_sync_qgis.bat](./run_full_sync_qgis.bat) | [run_ingest_shp_to_file_gdb_ogr.bat](./run_ingest_shp_to_file_gdb_ogr.bat) |

Ingest-only scripts (after a manual or scripted SHP export):

| File | Purpose |
|------|---------|
| [ingest_shp_to_file_gdb_arcgis.py](./ingest_shp_to_file_gdb_arcgis.py) | ArcGIS Pro (`arcpy`) |
| [ingest_shp_to_file_gdb_ogr.py](./ingest_shp_to_file_gdb_ogr.py) | QGIS / GDAL `ogr2ogr` |
| [invoke_qgis_ingest.bat](./invoke_qgis_ingest.bat) | QGIS ingest from Ruby (logs to `staging_shp\qgis_ingest.log`) |

Parent folder: [ODEC Export examples](../Readme.md).

---

## Overview

1. **IAM** — `odec_export_ex('SHP', ...)` using the same **export** `.cfg` you use in ODEC for File Geodatabase (`DBX002` on line 1).
2. **ArcGIS Pro** — delete/create target `.gdb`, copy each staging `.shp` into a feature class.

Use the **same field mapping** you validated in **Open Data Export Centre → File Geodatabase**; only the destination format changes to shapefile.

---

## Setup

1. Copy this folder to a short path on your PC.
2. Save an ODEC export config from the UI (**Save Config**) into this folder as `odec_export_ex-SHP.cfg` (start from [example_odec_export_ex-SHP.cfg](./example_odec_export_ex-SHP.cfg) if helpful), or edit `CONFIG_FILE` in the Ruby scripts.
3. Edit **`EXPORT_LAYERS`** in the Ruby script(s): IAM table names (e.g. `node`, `pipe`) and output `.shp` base names.
4. Edit **`STAGING_FOLDER`** in the Ruby scripts and the paths in the Python script / batch file so they match.
5. Install **ArcGIS Pro** on the machine that runs the ingest step (can be the same PC as IAM or another server).

Default staging folder in the examples: `staging_shp` next to the scripts.

---

## Test run (UI export + Pro ingest)

1. Open the target **Collection** (or Asset) network in InfoAsset Manager.
2. **Network → Run Ruby Script…** → [UI-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb](./UI-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb).
3. In the **ODEC export to shapefile** dialog, choose the **export config** (`.cfg`), staging folder, units, export selection / WGS84 if needed, and optionally **Run ArcGIS Pro ingest** with the target `.gdb` path.
4. Confirm shapefiles (and `.prj` if present) appear under the staging folder you chose. If you did not run ingest from the dialog, run [run_ingest_shp_to_file_gdb_arcgis.bat](./run_ingest_shp_to_file_gdb_arcgis.bat) or `propy.bat ingest_shp_to_file_gdb_arcgis.py` against that folder.
5. Add the output `.gdb` in ArcGIS Pro and check feature classes.

If the output `.gdb` already exists, the Python script **deletes it** before creating a new one.

To chain ingest from the UI script in one step, check **Run ArcGIS Pro ingest after export** in the ArcGIS prompt, or **Build File Geodatabase with QGIS after export** in the QGIS prompt. QGIS ingest runs `o4w_env.bat` then `ogr2ogr` (same as the `.bat` helper); do not rely on launching QGIS `python.exe` directly from IAM. The UI **can** call `propy.bat` via `system()`; it is often **more likely to succeed** than Exchange, because IAM and Pro run under your interactive Windows user (Pro licence checkout). It still fails if Pro is not installed, paths are wrong, or policy blocks child processes. IAM may appear frozen until ingest finishes.

**UI-only:** `EXPORT_LAYERS` at the top of the UI script still defines which IAM tables are exported; ODEC field mapping comes from the config file you pick in the dialog.

---

## Exchange export (scheduled automation)

Edit database connection and network ID at the top of [IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb](./IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb), then for example:

```bat
"C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe" "C:\path\to\IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb" /ADSKASSET
```

Chain the same `propy.bat` ingest command in a second batch step.

### Chaining Exchange → ArcPy

**Option A — wrapper batch (recommended for Task Scheduler)**  
[run_full_sync_arcgis.bat](./run_full_sync_arcgis.bat) runs `iexchange.exe` on the IE Ruby script, then `propy.bat` on the Python ingest. No change inside Ruby; exit codes propagate if either step fails.

**Option B — from inside the IE Ruby script**  
In [IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb](./IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb), set `RUN_ARCPY_INGEST = true` and edit `PROPY_BAT`, `OUTPUT_GDB` if needed. After ODEC export, the script calls `system(propy.bat, ingest_shp_to_file_gdb_arcgis.py, ...)`.

Caveats for Option B:

- Exchange must run on a machine with **ArcGIS Pro installed** and licensed for the **same Windows user** (or context) that runs Exchange; unattended/service accounts often fail here.
- Use **full paths**; avoid relying on `PATH` for `propy.bat`.
- If ingest fails, the Ruby script exits with an error after shapefiles are already in `staging_shp`.

For production scheduling, Option A (or two scheduled tasks: export then ingest) is usually easier to troubleshoot.

---

## Customising layers

**Ruby** — `EXPORT_LAYERS` array: `[iam_table, 'output_name']` → `staging_shp\output_name.shp`.

**Python** — default layer list matches `node.shp` → feature class `Node`, `pipe.shp` → `Pipe`. Override with:

```bat
propy.bat ingest_shp_to_file_gdb_arcgis.py --staging "..." --gdb "..." --layer node.shp:Node --layer pipe.shp:Pipe
```

Feature class names must start with a letter and contain only letters, numbers, and underscore.

---

## Writing a File Geodatabase without ArcGIS Pro

IAM **Open Data Export Centre → File Geodatabase** (64-bit, no classic Esri licence) uses an in-application writer that is **not** exposed to Ruby/`odec_export_ex` the same way as shapefile export. The API lists `'FILEGDB'` as a format, but in practice that path often does not match the UI **File Geodatabase** option on Autodesk builds—there is no supported Ruby equivalent to “click Export in ODEC to File GDB.”

Practical alternatives for a **separate ingest script** after ODEC → SHP:

| Approach | Esri licence | Notes |
|----------|--------------|--------|
| [ingest_shp_to_file_gdb_arcgis.py](./ingest_shp_to_file_gdb_arcgis.py) (`arcpy`) | ArcGIS Pro | Best match to Esri tooling; same as your current chain. |
| [ingest_shp_to_file_gdb_ogr.py](./ingest_shp_to_file_gdb_ogr.py) (GDAL **OpenFileGDB**) | **None** on the ingest machine | Needs **GDAL 3.6+** with write support and `ogr2ogr` on PATH (OSGeo4W, QGIS, etc.). |
| ODEC UI **File Geodatabase** | None (IAM bundled writer) | Full field mapping and GDB behaviour, but **manual / not scriptable** today. |
| **GeoPackage** (`.gpkg`) instead of `.gdb` | None | Open standard; `ogr2ogr -f GPKG out.gpkg in.shp` — use if consumers accept GPKG. |

GDAL-created `.gdb` files usually open in ArcGIS Pro, but may differ from IAM’s UI export (domains, feature datasets, attachments, some field types, update/delete semantics). For a **full sync to a new `.gdb`**, OpenFileGDB is often enough for nodes/pipes with simple schemas.

```bat
run_ingest_shp_to_file_gdb_ogr.bat
```

The batch file looks for `ogr2ogr` on PATH or under `C:\OSGeo4W\bin\`, runs the ingest, and **pauses** so you can read errors. If you only have Python (not `ogr2ogr` on PATH), it falls back to `py -3` / OSGeo4W Python and [ingest_shp_to_file_gdb_ogr.py](./ingest_shp_to_file_gdb_ogr.py).

The batch defaults to **QGIS** at `C:\Program Files\QGIS 4.0.3` and runs `bin\o4w_env.bat` before `ogr2ogr` (required so GDAL can read shapefiles). Edit `QGIS_ROOT` at the top of the batch file if your install path differs.

If the window previously flashed and closed instantly, **`python` was likely not on PATH**; the current batch uses QGIS’s `ogr2ogr` directly and does not require Python.

You cannot call IAM’s internal File GDB exporter from a standalone script; the workable pattern remains **Ruby → SHP**, then **Pro** or **GDAL** for the `.gdb` step.

---

## Notes

- This is a **full replace** of the target `.gdb` each ingest run, not an in-place ODEC GDB update.
- Shapefile field names may be truncated vs your File GDB mapping; if ingest fails on schema, compare fields in ArcGIS Pro with your UI GDB export.
- Survey/point layers without geometry may not produce valid shapefiles; remove them from `EXPORT_LAYERS` if export errors.
