# ODEC Export Examples

This folder contains example Ruby scripts that export data from an InfoAsset Manager network using the `odec_export_ex` method — the programmatic equivalent of the **Open Data Export Centre (ODEC)** dialog.

Each script demonstrates a single destination format and shows how to set export options, reference a field-mapping configuration file (`.cfg`), and export one or more object tables. Copy a script, edit the hardcoded paths and table names for your environment, then run it.

For ODEC **callback classes** (transform, calculate, or filter values during export), see the companion folder [0001A ODEC Callback Examples](../0001A%20ODEC%20Callback%20Examples/).

---

## Script variants

| Script | Destination format | Run from | Notes |
|---|---|---|---|
| [UIIE-odec_export_ex-CSV.rb](./UIIE-odec_export_ex-CSV.rb) | CSV | UI or Exchange | Exports `Node` and `Pipe` |
| [UIIE-odec_export_ex-GDB.rb](./UIIE-odec_export_ex-GDB.rb) | ESRI File Geodatabase | UI or Exchange | Exports `Node` and `Pipe` feature classes |
| [UI-odec_export_ex-SHP.rb](./UI-odec_export_ex-SHP.rb) | ESRI Shapefile | UI | Config and output paths relative to the script file |
| [IE-odec_export_ex-CSV-MultipleNetworks.rb](./IE-odec_export_ex-CSV-MultipleNetworks.rb) | CSV | Exchange | Exports `Pipe` from multiple network IDs |
| [IE-odec_export_ex-GDB-differencial.rb](./IE-odec_export_ex-GDB-differencial.rb) | ESRI File Geodatabase | Exchange | Differential export using `'Previous Version'` |
| [IE-odec_export_ex-SQLSERVER.rb](./IE-odec_export_ex-SQLSERVER.rb) | SQL Server | Exchange | Full export to an existing SQL Server table |
| [IE-odec_export_ex-SQLSERVER-differences.rb](./IE-odec_export_ex-SQLSERVER-differences.rb) | SQL Server | Exchange | Differential export using `'Previous Version'` |

**UI scripts** (`UI-` prefix) use the currently open network (`WSApplication.current_network`) and are run from **Network → Run Ruby Script…**. They do not require an Exchange licence.

**Exchange scripts** (`IE-` prefix) open a database connection, reserve the target network where applicable, run the export, and unreserve. Edit the database connection string and network ID near the top of the script before running via InfoAsset Exchange. See the [parent README](../README.md) for Exchange command-line syntax.

**UIIE scripts** (`UIIE-` prefix) detect whether they are running from the UI or Exchange (`WSApplication.ui?`) and use the open network or a defined database connection accordingly.

---

## Prerequisites

1. **An open network** — UI and UIIE-in-UI scripts require the target Collection (or Asset/Distribution) network to be open in InfoAsset Manager.
2. **A field-mapping config file** — create and save this from the ODEC dialog (*Load Config* / *Save Config*), or copy an existing `.cfg` file. Export configs must start with `DBX002` on the first line (import configs use `DBI002` instead).
3. **Destination** — CSV files, shapefiles, a file geodatabase, or SQL Server tables, depending on the script variant. For SQL Server and GDB update exports, the destination tables or feature classes must already exist.

---

## Customising the scripts

Before running, edit the placeholder paths, table names, and connection details in the script copy on your machine.

### Export options

Each script defines a `params` or `options` hash. Uncomment and set keys as needed:

| Option | Type | Default | Notes |
|---|---|---|---|
| `'Error File'` | String | nil | Path for the export error log |
| `'Callback Class'` | Class | nil | Ruby callback class for value conversion or filtering — see [0001A](../0001A%20ODEC%20Callback%20Examples/) |
| `'Image Folder'` | String | nil | Folder for exported images (Asset networks only) |
| `'Units Behaviour'` | String | `'Native'` | `'Native'` or `'User'` |
| `'Report Mode'` | Boolean | false | Export in report mode |
| `'Append'` | Boolean | false | Append to existing destination data |
| `'Export Selection'` | Boolean | false | Export selected objects only |
| `'Previous Version'` | Integer | 0 | Export only changes since this commit ID — used by the differential scripts |
| `'Don't Update Geometry'` | Boolean | false | |

The differential export scripts ([IE-odec_export_ex-GDB-differencial.rb](./IE-odec_export_ex-GDB-differencial.rb) and [IE-odec_export_ex-SQLSERVER-differences.rb](./IE-odec_export_ex-SQLSERVER-differences.rb)) store the last exported commit ID in a text file and set `'Previous Version'` so only changes since the previous run are exported.

### `odec_export_ex` call syntax by format

**CSV and Shapefile** — four arguments after the options hash:

```ruby
net.odec_export_ex('CSV', 'C:/Temp/export.cfg', options, 'Node', 'C:/Temp/node.csv')
net.odec_export_ex('SHP', 'C:/Temp/export.cfg', options, 'node', 'C:/Temp/node.SHP')
```

**Geodatabase** — nine arguments after the options hash:

```ruby
net.odec_export_ex(
  'GDB', 'C:/Temp/export.cfg', options,
  'Node',        # InfoAsset table to export
  'Manholes2',   # Destination feature class (unqualified name)
  'Node',        # Destination feature dataset (fully qualified name)
  true,          # Update existing feature class (must exist when true)
  nil,           # ArcSDE keyword — nil for file geodatabases
  'C:/Temp/Test.gdb'
)
```

> **Note:** File geodatabase export requires the **Innovyze 32-bit** version of InfoAsset Manager (Workgroup Client) and a valid **ArcMap** licence. Exchange scripts may call `WSApplication.use_arcgis_desktop_licence()` to use a local ArcGIS Desktop licence rather than an ArcGIS Server licence.

**SQL Server** — twelve arguments after the options hash. Call on the **network model object** (`WSNumbatNetworkObject`) — do **not** call `.open` first:

```ruby
nw.odec_export_ex(
  'SQLSERVER', 'C:/Temp/export.cfg', options,
  'node',           # InfoAsset table to export
  'Node',           # SQL Server destination table
  'localhost',      # Server name
  'SQLEXPRESS',     # Instance name
  'IAMExport',      # Database name
  true,             # Update existing table (must exist when true)
  false,            # Integrated security (true = Windows auth)
  'USERNAME',       # Username (ignored when integrated security is true)
  'PASSWORD'        # Password
)
```

The **table** argument uses the ODIC/ODEC UI table name with spaces removed (e.g. `'Node'`, `'Pipe'`, `'CCTVSurvey'`). Table name casing may vary between scripts — match the name used in your saved `.cfg` file.

Call `odec_export_ex` once per destination file, feature class, or SQL table. The CSV example exports `Node` then `Pipe`; the shapefile example also exports `cctvsurvey`.

---

## Running a UI script

1. Open the target network in InfoAsset Manager.
2. Save a customised copy of the script as a `.rb` file on your PC.
3. Run via **Network → Run Ruby Script…** and select the file.
4. Check the Ruby console output and the error log file (if `'Error File'` is set) for export results.

UI exports write directly to the specified destination — there is no separate commit step in the network.

---

## Running an Exchange script

1. Edit the database connection (`WSApplication.open(...)`) and network type/ID (`model_object_from_type_and_id(...)`) at the top of the script.
2. Update all destination paths, config paths, and table names.
3. Run via InfoAsset Exchange, for example:

```bat
"C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe" "C:\Temp\IE-odec_export_ex-CSV-MultipleNetworks.rb" /ADSKASSET
```

The Exchange scripts that reserve the network unreserve in an `ensure` or `rescue` block. Failed exports log to the script error file where configured.

---

## Related examples

| Folder | Description |
|---|---|
| [0001A ODEC Callback Examples](../0001A%20ODEC%20Callback%20Examples/) | Callback classes for transforming or filtering values during export |
| [0002 ODIC Import](../0002%20ODIC%20Import/) | Mirror import examples using `odic_import_ex` |
| [0035 Export CCTV Surveys to WSAA XML](../0035%20Export%20CCTV%20Surveys%20to%20WSAA%20XML/) | Custom XML export workflow |

Further API detail is in [`03 Context/InfoAsset_Manager_Ruby_API_Full.md`](../../03%20Context/InfoAsset_Manager_Ruby_API_Full.md).
