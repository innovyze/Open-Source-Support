# ODIC Import Examples

This folder contains example Ruby scripts that import data into an InfoAsset Manager network using the `odic_import_ex` method — the programmatic equivalent of the **Open Data Import Centre (ODIC)** dialog.

Each script demonstrates a single source format and shows how to set import options, reference a field-mapping configuration file (`.cfg`), and import one or more object tables. Copy a script, edit the hardcoded paths and table names for your environment, then run it.

For ODIC **callback classes** (transform or filter values during import), see the companion folder [0002A ODIC Callback Examples](../0002A%20ODIC%20Callback%20Examples/).

---

## Script variants

| Script | Source format | Run from |
|---|---|---|
| [UI-odic_import_ex-CSV.rb](./UI-odic_import_ex-CSV.rb) | CSV | UI |
| [UI-odic_import_ex-CSV-Prompt.rb](./UI-odic_import_ex-CSV-Prompt.rb) | CSV (prompted path, embedded mappings, import summary) | UI |
| [IE-odic_import_ex-CSV.rb](./IE-odic_import_ex-CSV.rb) | CSV | Exchange |
| [UI-odic_import_ex-SHP.rb](./UI-odic_import_ex-SHP.rb) | ESRI Shapefile | UI |
| [IE-odic_import_ex-SHP.rb](./IE-odic_import_ex-SHP.rb) | ESRI Shapefile | Exchange |
| [UI-odic_import_ex-GDB.rb](./UI-odic_import_ex-GDB.rb) | ESRI File Geodatabase | UI |
| [IE-odic_import_ex-GDB.rb](./IE-odic_import_ex-GDB.rb) | ESRI File Geodatabase | Exchange |
| [UI-odic_import_ex-SQLServer.rb](./UI-odic_import_ex-SQLServer.rb) | SQL Server | UI |
| [IE-odic_import_ex-SQLServer.rb](./IE-odic_import_ex-SQLServer.rb) | SQL Server | Exchange |

**UI scripts** (`UI-` prefix) use the currently open network (`WSApplication.current_network`) and are run from **Network → Run Ruby Script…**. They do not require an Exchange licence.

**Exchange scripts** (`IE-` prefix) open a database connection, reserve the target network, run the import, commit changes, and unreserve. Edit the database connection string and network ID near the top of the script before running via InfoAsset Exchange. See the [parent README](../README.md) for Exchange command-line syntax.

---

## Prerequisites

1. **An open network** — UI scripts require the target Collection (or Asset/Distribution) network to be open in InfoAsset Manager.
2. **A field-mapping config file** — create and save this from the ODIC dialog (*Load Config* / *Save Config*), or copy an existing `.cfg` file. Import configs must start with `DBI002` on the first line (export configs use `DBX002` instead).
3. **Source data** — CSV files, shapefiles, a file geodatabase, or SQL Server tables, depending on the script variant.

---

## Customising the scripts

Before running, edit the placeholder paths, table names, and connection details in the script copy on your machine.

### Import options

Each script defines an `options` hash. Uncomment and set keys as needed:

| Option | Type | Default | Notes |
|---|---|---|---|
| `'Error File'` | String | blank | Path for the import error log |
| `'Callback Class'` | Class | nil | Ruby callback class for value conversion or filtering — see [0002A](../0002A%20ODIC%20Callback%20Examples/) |
| `'Set Value Flag'` | String | blank | Flag applied to fields populated from source data (e.g. `'CSV'`, `'SHP'`, `'GDB'`, `'SQL'`) |
| `'Default Value Flag'` | String | blank | Flag applied to fields populated from the default-value column |
| `'Image Folder'` | String | blank | Folder to import images from (Asset networks only) |
| `'Duplication Behaviour'` | String | `'Merge'` | `'Overwrite'`, `'Merge'`, or `'Ignore'` |
| `'Units Behaviour'` | String | `'Native'` | `'Native'`, `'User'`, or `'Custom'` |
| `'Update Based On Asset ID'` | Boolean | false | |
| `'Update Only'` | Boolean | false | Update existing objects only; do not create new ones |
| `'Delete Missing Objects'` | Boolean | false | |
| `'Allow Multiple Asset IDs'` | Boolean | false | |
| `'Update Links From Points'` | Boolean | false | |
| `'Blob Merge'` | Boolean | false | Keep `false` for attachment imports |
| `'Use Network Naming Conventions'` | Boolean | false | |
| `'Import Images'` | Boolean | false | Asset networks only |
| `'Group Type'` | String | nil | Asset networks only |
| `'Group Name'` | String | nil | Asset networks only |

### `odic_import_ex` call syntax by format

**CSV and Shapefile** — four arguments after the options hash:

```ruby
nw.odic_import_ex('CSV',  'C:/Temp/CSVConfig.cfg', options, 'node', 'C:/Temp/node.csv')
nw.odic_import_ex('SHP',  'C:/Temp/SHPConfig.cfg', options, 'node', 'C:/Temp/node.SHP')
```

**File Geodatabase** — five arguments after the options hash (feature class name is required):

```ruby
nw.odic_import_ex('GDB', 'C:/Temp/GDBConfig.cfg', options, 'node', 'NodeClass', 'C:/Temp/Geodatabase.gdb')
```

**SQL Server** — ten arguments after the options hash:

```ruby
nw.odic_import_ex(
  'SQLSERVER', 'C:/Temp/SQLConfig.cfg', options,
  'node',           # InfoAsset table to import into
  'T_MANHOLE',      # SQL Server source table
  'sqlname',        # Server name
  nil,              # Instance name (nil if default)
  'serverdb',       # Database name
  false,            # Integrated security (true = Windows auth)
  'sqlun',          # Username (ignored when integrated security is true)
  'sqlpw'           # Password
)
```

The **table** argument uses the ODIC UI table name (e.g. `'node'`, `'pipe'`, `'cams_manhole'`). For blob sub-table imports, append the blob field name in PascalCase — for example `'ManholeSurveyAttachments'` when importing into the `attachments` blob on Manhole Survey.

Call `odic_import_ex` once per source file or SQL table. The CSV and SQL Server examples import `node` then `pipe`; the GDB example imports both feature classes from the same geodatabase.

### Prompted CSV import with embedded field mappings

[UI-odic_import_ex-CSV-Prompt.rb](./UI-odic_import_ex-CSV-Prompt.rb) is a self-contained UI template for importing a single object table from CSV. You paste field mappings into the script instead of maintaining a separate `.cfg` file by hand.

1. Copy the script and edit `IMPORT_CONFIG` and `IMPORT_OPTIONS` at the top.
2. Create and save a field-mapping config from the ODIC dialog (*Save Config*).
3. Open the `.cfg` in a text editor and copy the **mapped line** — the first line after `DBI002` that contains the field mappings (not the registry lines that list table names only).
4. Paste that line into `IMPORT_CONFIG[:mapped_line]`. Set `odic_table` to the ODIC UI table name for `odic_import_ex`.
5. Run the script from **Network → Run Ruby Script…**. The dialog prompts only for the CSV file and working folder.
6. The script writes a minimal `.cfg` file (header + mapped line only) and error log to the working folder (`WSApplication.local_root` by default), then calls `odic_import_ex`.

Example generated config (two lines only):

```
DBI002
'cams_manhole,{{"node_id","node_id","","",""},{"asset_id","asset_id","","",""},{"user_text_2","external_ref","","",""}}'
```

The generated config uses the `DBI002` header and the pasted mapped line only. It does not add the full table registry lines that ODIC includes when saving a config for multiple tables.

After import, the script reports CSV row count, objects imported or updated, and any source IDs that were processed but not imported. A built-in ODIC callback records source IDs as each CSV row is processed — with `Duplication Behaviour: Ignore`, the processed count is often higher than the imported count because existing duplicates are skipped.

To transform or filter values during import, define a callback class (`OnBeginRecord{Table}` / `onEndRecord{Table}`) and set `IMPORT_CONFIG[:custom_callback_class]`. See [0002A ODIC Callback Examples](../0002A%20ODIC%20Callback%20Examples/). Your callback methods run first; ID tracking runs automatically after `onEnd` when `use_import_id_callback` is true. Set `use_import_id_callback: false` to use only your callback without ID tracking.

---

## Running a UI script

1. Open the target network in InfoAsset Manager.
2. Save a customised copy of the script as a `.rb` file on your PC.
3. Run via **Network → Run Ruby Script…** and select the file.
4. Check the Ruby console output and the error log file (if `'Error File'` is set) for import results.

Changes made by UI scripts are committed immediately to the open network — there is no separate commit step.

---

## Running an Exchange script

1. Edit the database connection (`WSApplication.open(...)`) and network type/ID (`model_object_from_type_and_id(...)`) at the top of the script.
2. Update all source paths, config paths, and table names.
3. Run via InfoAsset Exchange, for example:

```bat
"C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe" "C:\Temp\IE-odic_import_ex-CSV.rb" /ADSKASSET
```

The Exchange scripts reserve the network before importing, commit with a message on success, and unreserve in an `ensure` block. Uncomment the `nw.revert` lines in the `rescue`/`ensure` section if you want failed imports to roll back uncommitted changes.

---

## Related examples

| Folder | Description |
|---|---|
| [0002A ODIC Callback Examples](../0002A%20ODIC%20Callback%20Examples/) | Callback classes for transforming or filtering values during import |
| [0003 Import an InfoWorks ICM Model into InfoAsset Manager](../0003%20Import%20an%20InfoWorks%20ICM%20Model%20into%20InfoAsset%20Manager/) | End-to-end workflow importing multiple ICM CSV exports via `odic_import_ex` |
| [0045 Import Survey Photos from CSV](../0045%20Import%20Survey%20Photos%20from%20CSV/) | Generates ODIC CSV/cfg files and runs `odic_import_ex` for manhole survey images |

Further API detail is in [`03 Context/InfoAsset_Manager_Ruby_API_Full.md`](../../03%20Context/InfoAsset_Manager_Ruby_API_Full.md).
