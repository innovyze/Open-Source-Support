# Working and Results Folder Report

Scans ICM **Working Folder** and **Results Folder** subfolders (one per database client GUID), reads `DBVER.dat` for database path and version, reports folder sizes, and optionally checks whether the source database still exists.

## What it reports

For each subfolder GUID:

| Output | Source |
|--------|--------|
| Database path | `DBVER.dat` → `Database:` |
| Version | `DBVER.dat` → `Version:` |
| DbType | `standalone`, `workgroup`, `cloud`, or `unknown` |
| Working / Results / Total size (MB) | Windows folder size via `Scripting.FileSystemObject` |
| DbFound | Result of optional checks (see below) |
| ResolvedDataPath | Filesystem path used for workgroup / standalone checks |

## Checks performed

| DbType | Automated check | DbFound values |
|--------|-----------------|----------------|
| **Standalone** (`.icmm` path) | Optional: verify the `.icmm` file exists | `found` / `missing` / `not_checked` |
| **Workgroup** (`snumbat://...`, `host:port/name`) | Optional: map connection string to SNumbatData **`.sndb` / `.d` folders** | `found` / `missing` / `not_checked` |
| **Cloud** (`cloud://...`) | None | always `manual_check_required` |

### Workgroup path mapping

Under the SNumbatData root, workgroup databases are **folders**, not single files:

| Connection string path | SNumbatData folder |
|------------------------|-------------------|
| `Development and Testing` | `Development and Testing.sndb` |
| `Group/TEMP` | `Group.d/TEMP.sndb` |
| `Group/SubGroup/MyDB` | `Group.d/SubGroup.d/MyDB.sndb` |

The script walks `.d` group folders recursively and indexes every `.sndb` database folder. `master.wdb` inside each `.sndb` folder is also read to index database GUIDs.

Cloud databases are **not** opened or connected. Verify them manually in ICM (Connect to database), Modelling Cloud admin, or via Agent + MCP.

## Running the script

### ICM UI

1. Run [UI_script.rb](UI_script.rb) from **Network** → **Run Ruby script** (or your scripts menu).
2. Answer the prompts:
   - Check standalone `.icmm` files? (default: Yes)
   - Scan workgroup SNumbatData for `.sndb` / `.d` folders? (default: No)
   - If Yes → select the workgroup data root (local path or UNC, e.g. `\\server\share\SNumbatData`)
   - Select output folder for the CSV report
3. Review console summary and open the generated CSV.

## Output

`working_results_folder_report.csv` — full inventory with a **Total** row at the bottom summing `Working_MB`, `Results_MB`, and `Total_MB`.

## Folder locations

By default the script uses:

- `WSApplication.working_folder` / `WSApplication.results_folder` when run inside ICM
- Otherwise `%LOCALAPPDATA%\Innovyze\Working Folder` and `Results Folder`

Each database client uses a subfolder named with a GUID. `DBVER.dat` in that subfolder holds the database connection string and version.

## Workgroup notes

- All workgroup databases on a server share one **SNumbatData** root; you must point the script at that folder (often on another machine — use a UNC path).
- Databases appear as **`Name.sndb`** folders; model groups appear as **`Name.d`** folders and may contain nested databases.
- The connection string path after `host:port/` must match the logical path in the catalog (e.g. `Group/TEMP` → `Group.d/TEMP.sndb`).

