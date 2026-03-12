# Export and Import Rainfall Events with Hierarchy Preservation

Two Ruby scripts for bulk exporting and importing Rainfall Event objects in InfoWorks ICM, preserving the **full container hierarchy** (Model Groups, Transportable Database Groups, and other parent types).

**IMPORTANT:** These scripts must be run from **ICMExchange** command line, not the InfoWorks ICM UI.

## Overview

- **Export** all Rainfall Events from a database to native `.red` files with a folder structure mirroring the full parent hierarchy, plus a `manifest.csv` mapping files to their original locations
- **Import** from the manifest, recreating the original folder structure under a configurable root Model Group (default: **Imported Rainfall**)
- Handle multi-profile rainfall events that the API splits into separate files (e.g., M5-30, M5-60, M10-30)

## Scripts

### run_rainfall_scripts.bat

Batch file launcher — double-click, then select Export (1), Import (2), or Exit (3). Edit the folder paths in the Ruby scripts first (see configuration below).

### hw_export_rainfall_events_to_red.rb

**Configuration (edit at top of script):**
```ruby
EXPORT_FOLDER = 'D:/TEMP'           # Where to export files
DATABASE_PATH = ''                   # Empty = database picker dialog
```

**Run:**
```
"C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange.exe" "path\to\hw_export_rainfall_events_to_red.rb"
```

**What it does:**
- Parses `model_object.path` for **all** container types (MODG, TDBG, etc.) to build the hierarchy
- Exports each event to `.red` format in a nested folder structure
- Multi-profile events → grouped in a subfolder named after the original event
- Creates `manifest.csv` with columns: `file_path`, `event_name`, `group_path`, `is_multi_file`, `original_event`
- Sanitizes filenames (`\ / : * ? " < > |` → `_`), deduplicates paths with `_2`, `_3` suffixes (case-insensitive)

**Output Structure:**
```
D:/TEMP/
├── manifest.csv
├── Project A/
│   ├── Branch 1/
│   │   └── Model Groups/
│   │       └── Rainfall Events/
│   │           └── Time Series/
│   │               ├── Storm_2hr.red
│   │               └── Storm_6hr.red
│   └── Branch 2/
│       └── ...
├── Project B/
│   └── Sub-Project/
│       └── Design Rainfall/
│           └── Multi Profile Event/         ← subfolder for split profiles
│               ├── Rainfall event_M5-30.red
│               ├── Rainfall event_M5-60.red
│               └── Rainfall event_M10-30.red
```

### hw_import_rainfall_events_from_red.rb

**Configuration (edit at top of script):**
```ruby
IMPORT_FOLDER = 'D:/TEMP'           # Where to import files from
IMPORT_ROOT_GROUP = 'Imported Rainfall'  # Root group for all imports
DATABASE_PATH = ''                   # Empty = database picker dialog
```

**Run:**
```
"C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange.exe" "path\to\hw_import_rainfall_events_from_red.rb"
```

**What it does:**
- Reads `manifest.csv` and recreates the full hierarchy as nested Model Groups under the root group
- Imports each `.red` file into its correct location
- Tracks names locally per group (works around stale `parent.children` API behavior)
- On name conflict: creates a **sibling Model Group** with `_2` suffix rather than renaming the event — preserving original names for use in simulations

**Name Conflict Example:**
```
Time Series/
├── Storm_2hr                      ← first import
Time Series_2/
├── Storm_2hr                      ← conflict → placed in sibling group
```

## Common Workflows

### Migrate Between Databases
```batch
REM 1. Export from source database
"C:\...\ICMExchange.exe" "C:\Scripts\hw_export_rainfall_events_to_red.rb"

REM 2. Import to target database
"C:\...\ICMExchange.exe" "C:\Scripts\hw_import_rainfall_events_from_red.rb"
```

### Share Specific Events
1. Export all from your database
2. Copy specific event folders + `manifest.csv` to a new folder
3. Edit `manifest.csv` to keep only the desired entries
4. Share folder with colleagues for import

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Must be run from ICMExchange" | Run via ICMExchange.exe, not the InfoWorks ICM UI |
| "No database open" | Leave `DATABASE_PATH` empty for picker dialog |
| "Folder does not exist" | Edit folder path in script — export creates it automatically |
| "manifest.csv not found" | Run export first to generate the manifest |
| "No Rainfall Events found" | Verify events exist in the database |
| Unicode / encoding errors | Handled by `safe_puts()` with CP850/IBM437 fallback |
| File path collisions | Export appends `_2`, `_3` automatically (case-insensitive) |
| Event name already in use | Import creates sibling group with `_2` suffix |

## Technical Notes

- **Exchange-only:** Scripts use API methods available only in ICMExchange
- **Path parsing:** `model_object.path` is parsed for all non-leaf segment types (MODG, TDBG, etc.), handling escaped characters (`\~`, `\>`, `\\`)
- **Multi-profile events:** The ICM API splits multi-profile events into separate `.red` files — this is API behavior, not a script limitation. Export detects this and groups split files in a subfolder marked `is_multi_file: true` in the manifest. Import reads these back as separate profile files.
- **Name registry:** `$name_registry` hash tracks names per group to work around stale `parent.children` after `import_new_model_object()`
- **Conflict strategy:** Sibling group duplication (`_2`, `_3`) preferred over event renaming

**Key API Methods:**
- `db.model_object_collection('Rainfall Event')` — bulk retrieval of all events
- `model_object.path` — full scripting path (e.g., `>TDBG~Branch>MODG~Group>RAIN~Event`)
- `model_object.export(path, '')` — export to native `.red` format
- `parent.new_model_object('Model Group', name)` — create child group
- `parent.import_new_model_object('Rainfall Event', name, '', path)` — import `.red` file

## License

This project is licensed under the MIT License — see the LICENSE file for details.
