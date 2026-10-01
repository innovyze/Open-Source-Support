# Batch Update Databases to Latest Version

Updates a list of InfoWorks ICM databases (cloud, workgroup and standalone, in one list) to a newer ICM version from the command line, instead of opening each database and running *Update current database* by hand. Writes a timestamped results CSV with SUCCESS/FAILED per database.

> **Back up first.** A database version update cannot be undone. Take a backup of every database before running the script, and make sure no one has the databases open.

## Files

- **batch_update_databases.rb** - ICM Exchange script that reads the ledger and updates each database
- **databases.csv** - Ledger template: one row per database

## Prerequisites

- InfoWorks ICM Ultimate (includes `ICMExchange.exe`)
- Write/admin permission on the target databases and cloud hubs
- Exclusive access: no open sessions or locked items on the target databases

## 1. Find each database's connection string

- **Cloud:** in ICM, *File > Recent databases*. Format: `cloud://<DB_Name>@<Tenant_ID>/<Region>`
- **Workgroup:** `<server>:<port>/<Group>/<DB_Name>`, for example `your-server:40000/Example_Group/Example_DB`
- **Standalone:** full local or UNC path to the `.icmm` file

## 2. Fill in the ledger

Edit `databases.csv` (same folder as the script by default). Lines starting with `#` are ignored.

```csv
name,type,path,target_version
Example Cloud Model,cloud,cloud://Example_Model@000000000000000000000000/emea,latest
Example Workgroup Model,workgroup,your-server:40000/Example_Group/Example_DB,latest
Pinned Version Model,workgroup,192.0.2.10:40000/Example_Group/Example_DB_2,2025.2
Example Standalone Model,standalone,C:/ICM_Models/Example.icmm,latest
```

| Column | Description |
|---|---|
| name | Display name for logging |
| type | `cloud`, `workgroup` or `standalone` |
| path | Connection string or file path |
| target_version | `latest` (or blank) to match the running ICM client, or a specific version the installed client recognises, e.g. `2025.2` |

The ledger is built once. After that, add or remove rows as databases are created or retired.

## 3. Run it

```
"C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2027\ICMExchange.exe" "C:\Scripts\batch_update_databases.rb" -l "C:\Scripts\databases.csv"
```

- Keep the `-l` (or `-login`) switch. If you are already signed in to Autodesk nothing appears; otherwise it opens the sign-in page once instead of failing with *The licence is not authorised (3)*.
- The CSV path is optional when `databases.csv` sits next to the script.

## 4. Check the results

The script prints progress to the console and writes `update_results_YYYYMMDD_HHMMSS.csv` next to the script. ICM Exchange always returns exit code 0, so check the summary and the results CSV for `FAILED` rows rather than the exit code.

## Troubleshooting

| Error | Cause and action |
|---|---|
| Error 51: Unknown product or version | The database was created with a newer ICM than the running `ICMExchange.exe`. Upgrade the local ICM installation first. |
| Error 57: HTTP 403 ACCESS DENIED | The Autodesk account lacks access to the cloud hub/project, or the Tenant_ID in the path is wrong. |
| database requires minor/major update but allow update flag is not set | `WSApplication.open` was called without the update parameter. This script sets it. |
| The licence is not authorised (3) | Not signed in to Autodesk. Pass `-l`. |
| open - internal error - database not updated | Seen on large version jumps. The script retries once automatically. If it still fails, re-run (already-current databases are skipped harmlessly) or open the database in ICM and use *File > Database update* to see the full error. |

## Notes

- Databases are processed one at a time, and each connection is closed before the next opens.
- The script does not discover databases; list them in the ledger.
- Tested on ICM 2027.1 against workgroup databases from 2023.2, 2026.2 and 2027.0 and two cloud databases.
