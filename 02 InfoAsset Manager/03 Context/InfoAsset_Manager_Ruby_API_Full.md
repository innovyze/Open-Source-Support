# InfoAsset Manager Ruby API - Full Reference

**Purpose:** Complete IAM-applicable Ruby API reference extracted from the official 2027 documentation. Covers all shared WS* classes relevant to InfoAsset Manager scripts.

**Scope:** All classes and methods that work in InfoAsset Manager UI and/or Exchange scripts. ICM-only simulation, 2D meshing, SWMM, and rainfall-event methods are explicitly excluded — see the Excluded Methods appendix.

**Source:** Official InfoWorks Ruby API documentation, 2027. Methods labelled EXCHANGE, UI, or BOTH as in the official docs. Repository evidence citations appended at end of file.

**Load Priority:** REFERENCE — Load when you need method signatures, parameter types, or return types.

**Last Updated:** May 2026

---

## Class Hierarchy

```
WSApplication             (static — top level)
WSDatabase                (from WSApplication.open or .current_database)
  WSModelObject           (from database lookup)
    WSBaseNetworkObject   (parent of network types)
      WSNumbatNetworkObject  (merge-version-controlled network)
    WSModelObjectCollection (from db.model_object_collection)
WSOpenNetwork             (from network_mo.open)
  WSTableInfo             (from net.table)
    WSFieldInfo           (from table_info.fields)
  WSRowObject             (from net.row_objects, net.row_object)
    WSLink                (link-category objects)
    WSNode                (node-category objects)
  WSRowObjectCollection   (from net.row_object_collection)
  WSStructure             (from ro['struct_field'])
    WSStructureRow        (from struct[index] or struct.each)
  WSValidations           (from net.validate)
    WSValidation          (from validations.each)
WSCommits                 (from network_mo.commits)
  WSCommit                (from commits.each)
```

---

## WSApplication

Static class. Call all methods as `WSApplication.method_name`. Available in both UI and Exchange unless noted.

### Method Reference

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `ui?` | — | Boolean | BOTH | `true` when running from UI; use for dual-mode branching |
| `current_network` | — | WSOpenNetwork | UI | Returns the active GeoPlan network |
| `current_database` | — | WSDatabase | UI | Limited database access from UI |
| `open` | `path=nil, update_or_version=nil` | WSDatabase | EXCHANGE | See overloads below |
| `create` | `path, version=nil` | void | EXCHANGE | Creates a new standalone or workgroup database |
| `create_transportable` | `path, version=nil` | void | EXCHANGE | Creates a new transportable database (.icmt/.wspt) |
| `version` | — | String | BOTH | Returns application version string e.g. `'26.0.162'` |
| `local_root` | — | String | BOTH | Returns the working folder path |
| `working_folder` | — | String | BOTH | Same as local_root |
| `results_folder` | — | String | BOTH | Returns the results folder path |
| `set_working_folder` | `path` | void | EXCHANGE | Sets working folder for this Exchange process |
| `set_results_folder` | `path` | void | EXCHANGE | Sets results folder for this Exchange process |
| `script_file` | — | String | BOTH | Absolute path of the running script file |
| `add_ons_folder` | — | String | BOTH | Path to the add-ons/scripts folder |
| `prompt` | `title, layout, hard_wire_cancel` | Array? | UI | Multi-field input dialog — see Prompt Layout below |
| `message_box` | `text, buttons, icon, hard_wire_cancel` | String? | UI | Dialog box — see Message Box below |
| `input_box` | `prompt, title, default` | String? | UI | Single text input dialog |
| `file_dialog` | `open, ext, desc, default, multiple, hard_wire_cancel` | String/Array? | UI | File open/save dialog |
| `folder_dialog` | `title, hard_wire_cancel` | String? | UI | Folder chooser dialog |
| `open_text_view` | `title, filename, delete_on_exit` | void | UI | Opens a text file in a dialog |
| `graph` | `options` | void | UI | Displays a graph — see Graph Options below |
| `scalars` | `title, layout, hard_wire_cancel` | void | UI | Displays key/value grid |
| `choose_selection` | `title` | WSModelObject? | UI | Shows selection list chooser |
| `color` | `r, g, b` | Integer | UI | Converts RGB to Integer for graph colours |
| `use_user_units=` | `bool` | void | BOTH | Set user units on/off |
| `use_user_units?` | — | Boolean | BOTH | Whether user units are active |
| `use_utf8=` | `flag` | void | BOTH | Set UTF-8 string handling |
| `use_utf8?` | — | Boolean | BOTH | Whether UTF-8 is active |
| `override_user_unit` | `code, value` | Boolean | EXCHANGE | Override one unit for this Exchange process |
| `override_user_units` | `file` | String | EXCHANGE | Override all units from CSV file |
| `set_exit_code` | `code` | void | EXCHANGE | Set process exit code (0 = success) |
| `use_arcgis_desktop_licence` | `bool` | void | EXCHANGE | Use ArcGIS desktop licence for ODEC/ODIC |
| `map_component` | — | String? | EXCHANGE | Returns current map component |
| `map_component=` | `component` | void | EXCHANGE | Sets map component (`'mapxtreme'`, `'arcobjects'`, `'arcengine'`) |
| `wds_query_databases` | `server, port` | Hash | BOTH | Queries a Workgroup Data Server |

### `WSApplication.open` Overloads

```ruby
# Open most recently opened database (Exchange)
db = WSApplication.open

# Open by path, no update
db = WSApplication.open('localhost:40000/MyDatabase', false)

# Open standalone, allow update to current version
db = WSApplication.open('C:/Data/MyDB.icmm', true)

# Open standalone, update to specific version
db = WSApplication.open('C:/Data/MyDB.icmm', '2025.0')
```

**Path formats:**
- Workgroup: `'localhost:40000/GroupName/DBName'`
- Standalone: `'C:/path/to/database.icmm'`
- Cloud: `'cloud://dbname.4@guid/region'`
- Pass `nil` to use the last database opened in the UI

### `WSApplication.prompt` Layout Format

Each row in the layout array is an Array:

```ruby
['Label', 'STRING']                              # Text field
['Label', 'STRING', 'default']                   # Text with default
['Label', 'NUMBER']                              # Number field
['Label', 'NUMBER', 3, 2]                        # Number, default 3, 2 decimals
['Label', 'BOOLEAN', true]                       # Checkbox, default true
['Label', 'READONLY', 'value', 2]                # Read-only display, 2 decimals
['Label', 'DATE']                                # Date picker
['Label', 'STRING', nil, nil, 'LIST', ['A','B']] # Dropdown
['Label', 'NUMBER', 5, nil, 'RANGE', 1, 10]      # Range picker
['Label', 'STRING', nil, nil, 'FILE', true, 'csv', 'CSV file', false] # File open
['Label', 'STRING', nil, nil, 'FOLDER', 'Title'] # Folder picker
```

Returns `nil` if user cancels and `hard_wire_cancel` is false; raises exception if `hard_wire_cancel` is true/nil.

### `WSApplication.message_box` Parameters

| Parameter | Values |
|-----------|--------|
| `buttons` | `'OK'`, `'OkCancel'`, `'YesNo'`, `'YesNoCancel'`, `nil` (→ OkCancel) |
| `icon` | `'!'`, `'?'`, `'Information'`, `'Stop'`, `nil` (→ `'!'`) |
| `hard_wire_cancel` | `true`/`nil` exits script on Cancel; `false` returns `nil` |

Returns: `'ok'`, `'cancel'`, `'yes'`, `'no'` (lowercase strings).

### `WSApplication.graph` Options Hash

```ruby
WSApplication.graph({
  'WindowTitle' => 'My Graph',
  'GraphTitle'  => 'Flow vs Time',
  'XAxisLabel'  => 'Time',
  'YAxisLabel'  => 'Flow (l/s)',
  'IsTime'      => false,          # true if X values are DateTime (absolute time only)
  'Traces' => [
    {
      'Title'       => 'Pipe Flow',
      'TraceColour' => WSApplication.color(0, 0, 255),
      'SymbolColour'=> WSApplication.color(0, 0, 255),
      'Marker'      => 'None',     # None, Cross, XCross, Star, Circle, Triangle, Diamond, Square, FCircle, FTriangle, FDiamond, FSquare
      'LineType'    => 'Solid',    # None, Solid, Dash, Dot, DashDot, DashDotDot
      'XArray'      => [1.0, 2.0, 3.0],
      'YArray'      => [10.0, 15.0, 12.0]
    }
  ]
})
```

---

## WSDatabase

Accessed from `WSApplication.open` (Exchange) or `WSApplication.current_database` (UI, limited).

### Method Reference

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `path` | — | String | BOTH | Database path or connection string |
| `guid` | — | String | BOTH | Database GUID identifier |
| `file_root` | — | String | BOTH | Remote Files Root path |

> **SNumbatData directory convention:** Attachment and video files are stored on disk under `SNumbatData/Attachments/[db.guid]/` and `SNumbatData/Videos/[db.guid]/`. The `db.guid` scopes files to a specific database. Field values (e.g., `db_ref`, `detail_image`) store only the UID/filename — resolve against the appropriate subdirectory to get the full path.
| `result_root` | — | String | EXCHANGE | Remote Results Root path |
| `model_object_from_type_and_id` | `type, id` | WSModelObject? | BOTH | Find object by scripting type and integer ID |
| `model_object_from_type_and_guid` | `type, guid` | WSModelObject? | BOTH | Find object by scripting type and GUID string |
| `model_object` | `path` | WSModelObject? | BOTH | Find object by scripting path |
| `model_object_collection` | `type` | WSModelObjectCollection | BOTH | All objects of a given type in the database |
| `find_root_model_object` | `type, name` | WSModelObject? | BOTH | Find root-level object by type and name |
| `root_model_objects` | — | WSModelObjectCollection | BOTH | All root-level objects |
| `new_model_object` | `type, name` | WSModelObject | EXCHANGE | Create object at database root (type must be `'Asset Group'`, `'Model Group'`, or `'Group'`) |
| `copy_into_root` | `object, copy_results, copy_ground_models` | WSModelObject | EXCHANGE | Copy a model object into this database root |
| `new_network_name` | `type, name, branch, add` | String | BOTH | Generate a unique variant network name |
| `list_read_write_run_fields` | — | Array | BOTH | Field names in run objects that can be set |
| `merge_migration_file` | `file, log, import_type, mapping_file` | void | BOTH | Merge a migration file |

### Scripting Paths

```
>CG~MyAssetGroup>MODG~MyNetwork
```

Format: `>TYPE_CODE~Name>TYPE_CODE~Name...`

| Object | Type Code |
|--------|-----------|
| Asset Group | `CG` |
| Model Group | `MODG` |
| Collection Network | `MODG` (same) |
| Selection List | `MODG` (same) |

Escape special chars with backslash: `~` → `\~`, `>` → `\>`, `\` → `\\`

### Object Types for `model_object_from_type_and_id`

| Type String | Notes |
|-------------|-------|
| `'Collection Network'` | Most common IAM network |
| `'Distribution Network'` | Water distribution network |
| `'Asset Network'` | Asset-only network |
| `'Selection List'` | Selection list object |
| `'Asset Group'` | Root-level container |
| `'Model Group'` | Sub-container |
| `'Group'` | Generic container |
| `'Ruby Script'` | Script database item |
| `'Stored Query'` | SQL stored query |
| `'Theme'` | Network theme |

> **Case sensitivity:** Type strings are case-insensitive at runtime (e.g., `'Asset group'` and `'Asset Group'` both resolve). Use title case (`'Asset Group'`, `'Selection List'`, `'Collection Network'`) as the canonical form.

---

## WSModelObject

Represents any object in the database tree.

### Method Reference

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `id` | — | Integer | BOTH | Model object ID |
| `name` | — | String | BOTH | Object name |
| `name=` | `new_name` | void | BOTH | Rename object |
| `type` | — | String | BOTH | Scripting type string |
| `path` | — | String | BOTH | Full scripting path |
| `parent_id` | — | Integer | BOTH | Parent ID (0 if at root) |
| `parent_type` | — | String | BOTH | Parent type (`'Database'` if at root) |
| `comment` | — | String | EXCHANGE | Description / comment |
| `comment=` | `text` | void | EXCHANGE | Set description |
| `modified_by` | — | String | BOTH | Username that last modified this object |
| `children` | — | WSModelObjectCollection | BOTH | Child objects |
| `find_child_model_object` | `type, name` | WSModelObject? | BOTH | Find a named child |
| `new_model_object` | `type, name` | WSModelObject | BOTH | Create a child object (UI limited to Selection Lists and Groups) |
| `open` | — | WSOpenNetwork | BOTH | Open a network object — returns WSOpenNetwork |
| `export` | `path, format` | void | EXCHANGE | Export model object data |
| `compare` | `other` | Boolean | EXCHANGE | Compare two model objects |
| `copy_here` | `object, copy_sims, copy_ground_models` | WSModelObject | BOTH | Copy an object as a child |
| `delete` | — | void | BOTH | Delete if no children and not used in a run |
| `bulk_delete` | — | void | BOTH | Delete unconditionally including children |
| `deletable?` | — | Boolean | EXCHANGE | Whether safe to call `delete` |
| `==` | `other_mo` | Boolean | BOTH | Equality check |
| `!=` | `other_mo` | Boolean | BOTH | Inequality check |
| `[]` | `field` | Any | BOTH | Get field value |
| `[]=` | `field, value` | void | BOTH | Set field value |

### `WSModelObject#export` Formats for IAM

| Format string | Description |
|---------------|-------------|
| `'html'` | Dashboard export (InfoAsset Manager) |
| `'csv'` | Export in InfoWorks CSV format (inflow, level, etc.) |
| `''` (empty) | Export in InfoWorks text file format |

---

## WSNumbatNetworkObject

Inherits from `WSModelObject > WSBaseNetworkObject`. Represents a merge version-controlled network.

> **IAM Note:** InfoAsset Manager Collection Networks, Distribution Networks, and Asset Networks all use merge version control. `WSNumbatNetworkObject` methods are therefore fully relevant to IAM scripting. This is not an ICM-only class.

### Method Reference

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `open` | — | WSOpenNetwork | BOTH | Opens the latest version |
| `open_version` | `commit_id` | WSOpenNetwork | EXCHANGE | Opens a specific version by commit ID |
| `commit` | `comment` | Integer | EXCHANGE | Commits changes; returns commit ID or nil if no changes |
| `commit_reserve` | `comment` | Integer | EXCHANGE | Commit but keep reserved |
| `revert` | — | void | EXCHANGE | Abandon uncommitted changes |
| `reserve` | — | void | EXCHANGE | Reserve and update local copy to latest |
| `unreserve` | — | void | EXCHANGE | Release the reservation |
| `uncommitted_changes?` | — | Boolean | EXCHANGE | Whether there are uncommitted changes |
| `commits` | — | WSCommits | EXCHANGE | Full commit history |
| `current_commit_id` | — | Integer | EXCHANGE | Local copy's commit ID |
| `latest_commit_id` | — | Integer | EXCHANGE | Server's latest commit ID |
| `branch` | `commit_id, new_name` | WSModelObject | EXCHANGE | Branch from a commit |
| `csv_changes` | `commit_id_1, commit_id_2, file` | void | EXCHANGE | Export differences between commits to CSV |
| `gis_export` | `format, options, destination` | void | EXCHANGE | GIS export (shp, tab, mif, gdb) |
| `list_gis_export_tables` | — | Array | EXCHANGE | Tables available for GIS export |
| `select_changes` | `commit_id` | void | EXCHANGE | Select objects changed since a commit |
| `select_clear` | — | void | EXCHANGE | Deselect all objects |
| `select_count` | — | Integer | EXCHANGE | Count of selected objects |
| `select_sql` | `table, sql` | void | EXCHANGE | Run SQL to select objects |
| `update` | — | void | EXCHANGE | Update local copy to latest commit |
| `user_field_names` | — | Array | EXCHANGE | User-defined field names |
| `csv_export` | `file, options` | void | EXCHANGE | Export network to CSV |
| `csv_import` | `file, options` | void | EXCHANGE | Import/update network from CSV |
| `odec_export_ex` | `format, config, options, table, *args` | void | BOTH | ODEC export |
| `odic_import_ex` | `format, config, options, table, *args` | void | BOTH | ODIC import |
| `remove_local` | — | void | EXCHANGE | Remove local working copy |

---

## WSBaseNetworkObject Methods

Inherited by `WSNumbatNetworkObject`. Available directly on network model objects (before opening).

### `csv_export` Options Hash

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `'Multiple Files'` | Boolean | false | Export each table to a separate file |
| `'Field Descriptions'` | Boolean | false | Include field descriptions |
| `'Field Names'` | Boolean | true | Include field names header |
| `'Flag Fields'` | Boolean | true | Include flag fields |
| `'Selection Only'` | Boolean | false | Export selected objects only |
| `'User Units'` | Boolean | false | Export in user units |
| `'Object Types'` | Boolean | false | Include object type column |
| `'WGS84'` | Boolean | false | Export coordinates as WGS84 |
| `'Coordinate Arrays Format'` | String | `'Packed'` | `'Packed'`, `'None'`, `'Separate'` |

### `csv_import` Options Hash

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `'Force Link Rename'` | Boolean | true | |
| `'Load Null Fields'` | Boolean | true | |
| `'Update With Any Flag'` | Boolean | true | false = only update fields with Update Flag |
| `'Use Asset ID'` | Boolean | false | Match by asset ID |
| `'User Units'` | Boolean | true | Input uses user units |
| `'Action'` | String | `'Mixed'` | `'Mixed'`, `'Update And Add'`, `'Update Only'`, `'Delete'` |
| `'Header'` | String | `'ID'` | `'ID'`, `'ID Description'`, `'ID Description Units'`, `'ID Units'` |
| `'New Flag'` | String | nil | Flag for new/updated data |
| `'UK Dates'` | Boolean | false | Use UK date format |

### `odec_export_ex` Parameters and Options

```ruby
# CSV export
net.odec_export_ex('CSV', 'C:/config.cfg', options, 'Pipe', 'C:/output.csv')

# SHP export
net.odec_export_ex('SHP', 'C:/config.cfg', options, 'Pipe', 'C:/output.shp')

# XML export
net.odec_export_ex('XML', 'C:/config.cfg', options, 'Pipe', 'root_element', 'data_element', 'C:/output.xml')

# SQLSERVER export (call on WSNumbatNetworkObject — do NOT open the network first)
nw.odec_export_ex('SQLSERVER', 'C:/config.cfg', options,
  'node',          # IAM source table (lowercase)
  'Node',          # SQL Server destination table name
  'localhost',     # Server
  'SQLEXPRESS',    # Instance
  'IAMExport',     # Database
  true,            # Update existing target (must exist)
  false,           # Integrated security (false = use credentials below)
  'USERNAME',      # SQL Server username
  'PASSWORD'       # SQL Server password
)
```

> **Receiver note:** For `'SQLSERVER'` and `'ORACLE'` formats, call `odec_export_ex` on the `WSNumbatNetworkObject` (model object) directly — do NOT call `.open` first. For file-based formats (`'CSV'`, `'SHP'`, `'GDB'`, etc.) you may call on either the model object or the opened `WSOpenNetwork`.

**Supported formats:** `'CSV'`, `'TSV'`, `'XML'`, `'MDB'`, `'SHP'`, `'TAB'`, `'GDB'`, `'FILEGDB'`, `'ORACLE'`, `'SQLSERVER'`

**Options hash keys:**

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `'Error File'` | String | nil | Path for error log |
| `'Image Folder'` | String | `''` | Asset Networks only |
| `'Units Behaviour'` | String | `'Native'` | `'Native'` or `'User'` |
| `'Report Mode'` | Boolean | false | Export in report mode |
| `'Append'` | Boolean | false | Append to existing data |
| `'Export Selection'` | Boolean | false | Export selected objects only |
| `'Callback Class'` | Ruby Class | nil | Callback class instance |

**Table name format:** UI display name with spaces removed. Examples:
- `'Pipe'` → `cams_pipe`
- `'CCTVSurvey'` → `cams_cctv_survey`
- `'ManholeReport'` (for report mode)

### `odic_import_ex` Parameters and Options

```ruby
# CSV import
net.odic_import_ex('CSV', 'C:/config.cfg', options, 'Pipe', 'C:/input.csv')
```

**Options hash keys:**

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `'Error File'` | String | nil | Path for error log |
| `'Image Folder'` | String | nil | Import images from folder (asset networks) |
| `'Import Images'` | Boolean | false | Asset networks only |
| `'Group Name'` | String | nil | Asset networks only |
| `'Group Type'` | String | nil | Asset networks only |
| `'Units Behaviour'` | String | `'Native'` | `'Native'`, `'User'`, `'Custom'` |
| `'Duplication Behaviour'` | String | `'Merge'` | `'Overwrite'`, `'Merge'`, `'Ignore'` |
| `'Delete Missing Objects'` | Boolean | false | |
| `'Update Only'` | Boolean | false | |
| `'Blob Merge'` | Boolean | false | |
| `'Callback Class'` | Ruby Class | nil | |
| `'Set Value Flag'` | String | nil | Flag for imported fields |
| `'Default Value Flag'` | String | nil | Flag for default-value fields |

---

## WSOpenNetwork

Obtained from `network_mo.open` (Exchange) or `WSApplication.current_network` (UI).

### Row Object Access

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `row_objects` | `type` | Array | BOTH | All objects of a type |
| `row_object` | `type, id` | WSRowObject? | BOTH | One object by type and ID |
| `row_object_collection` | `type` | WSRowObjectCollection | BOTH | All objects as a collection |
| `row_objects_selection` | `type` | Array | BOTH | Selected objects of a type |
| `row_object_collection_selection` | `type` | WSRowObjectCollection | BOTH | Selected objects as a collection |
| `row_objects_from_asset_id` | `type, id` | Array | BOTH | Objects matching an asset ID |
| `new_row_object` | `type` | WSRowObject | BOTH | Create a new object (must be in a transaction; set `id` before `write`) |
| `each` | `{ \|ro\| }` | WSRowObject | BOTH | Iterate every object in the network |
| `each_selected` | `{ \|ro\| }` | WSRowObject | BOTH | Iterate selected objects |

**Type argument values:**
- Table name: `'cams_pipe'`, `'cams_manhole'`, `'cams_cctv_survey'`, etc.
- Category: `'_nodes'`, `'_links'`, `'_other'`

> **CRITICAL — Table names MUST use the full `cams_` prefix.** Using `'pipe'` or `'manhole'` without the prefix will cause a runtime error (table not found). Always use `'cams_pipe'`, `'cams_manhole'`, `'cams_cctv_survey'`, etc. See Schema Reference for the complete list.

### Selection

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `clear_selection` | — | void | BOTH | Deselect all objects |
| `selection_size` | — | Integer | BOTH | Count of selected objects |
| `load_selection` | `selection_list` | void | BOTH | Select objects from a selection list object (id, path, or WSModelObject) |
| `save_selection` | `selection_list` | void | BOTH | Save current selection to an existing selection list |
| `objects_in_polygon` | `polygon, type` | Array | BOTH | All objects inside a polygon row object |
| `search_at_point` | `x, y, distance, types` | Array | BOTH | Objects within radius of a point |
| `export_ids` | `filename, options` | void | BOTH | Export IDs of objects to file |

### Transactions

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `transaction_begin` | — | void | BOTH | Start a transaction (required for field edits, new/delete objects) |
| `transaction_commit` | — | void | BOTH | Commit (save) transaction changes |
| `transaction_rollback` | — | void | BOTH | Abandon transaction changes |

**Pattern:**
```ruby
net.transaction_begin
begin
  # edits here
  net.transaction_commit
rescue => e
  net.transaction_rollback
  raise e
end
```

### Schema Introspection

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `table_names` | — | Array | BOTH | All table name strings in the network |
| `tables` | — | Array | BOTH | Array of WSTableInfo objects |
| `table` | `name` | WSTableInfo | BOTH | WSTableInfo for a specific table |
| `field_names` | `table` | Array | BOTH | Field name strings for a table |

### Snapshot

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `snapshot_export` | `file` | void | BOTH | Export snapshot of entire network |
| `snapshot_export_ex` | `file, options` | void | BOTH | Export snapshot with options |
| `snapshot_import_ex` | `file, options` | void | BOTH | Import snapshot with options |
| `snapshot_scan` | `file` | Hash | BOTH | Scan snapshot file for metadata |

**`snapshot_export_ex` options hash keys:** `'SelectedOnly'` (Boolean), `'IncludeImageFiles'` (Boolean), `'IncludeGeoPlanPropertiesAndThemes'` (Boolean), `'ChangesFromVersion'` (Integer commit_id), `'Tables'` (Array of table name strings).

**`snapshot_import_ex` options hash keys:** `'Tables'` (Array), `'AllowDeletes'` (Boolean), `'ImportGeoPlanPropertiesAndThemes'` (Boolean), `'UpdateExistingObjectsFoundByID'` (Boolean), `'UpdateExistingObjectsFoundByUID'` (Boolean), `'ImportImageFiles'` (Boolean).

### Export

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `csv_export` | `filename, options` | void | BOTH | Export to CSV |
| `csv_import` | `filename, options` | void | BOTH | Import from CSV |
| `odec_export_ex` | `format, config, options, table, *args` | void | BOTH | ODEC export |
| `odic_import_ex` | `format, config, options, table, *args` | Array | BOTH | ODIC import; returns updated objects |
| `gis_export` | `format, options, location` | void | BOTH | GIS export (SHP, TAB, MIF, GDB) |
| `list_gis_export_tables` | — | Array | EXCHANGE | Tables available for GIS export |
| `run_sql` | `table, query` | void | BOTH | Run a SQL query on this network |
| `run_stored_query_object` | `stored_query` | void | BOTH | Run a stored query object |

### Survey Import/Export

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `mscc_export_cctv_surveys` | `file, export_images, selection_only, log_file` | Boolean | BOTH | MSCC4 XML CCTV export |
| `mscc_import_cctv_surveys` | `file, flag, import_images, id_gen, overwrite, log_file` | — | BOTH | MSCC4 XML CCTV import |
| `mscc_export_manhole_surveys` | `file, export_images, selection_only, log_file` | Boolean | BOTH | MSCC5 XML manhole survey export |
| `mscc_import_manhole_surveys` | `file, flag, import_images, id_gen, overwrite, log_file` | — | BOTH | MSCC5 XML manhole survey import |
| `ribx_export_surveys` | `file, selection_only, log_file` | Boolean | BOTH | RIBX XML export (CCTV + manhole) |
| `ribx_import_surveys` | `file, flag, id_gen, overwrite, log_file` | — | BOTH | RIBX XML import |
| `update_cctv_scores` | — | void | BOTH | Recalculate CCTV scores for all surveys |

**`mscc_import` / `ribx_import` id_gen values:**

| Value | Description |
|-------|-------------|
| 1 | StartNodeRef, Direction, Date and Time |
| 2 | StartNodeRef, Direction and index |
| 3 | US node ID, Direction, Date and Time |
| 4 | US node ID, Direction and index |
| 5 | ClientDefined1 |
| 6 | ClientDefined2 |
| 7 | ClientDefined3 |

### PACP/MACP Survey Methods (v2022.1+)

| Method | Signature | Availability | Notes |
|--------|-----------|--------------|-------|
| `PACP_export` | `(filename, options_hash)` | BOTH | Export CCTV surveys to PACP MDB |
| `pacp_import_cctv_surveys` | `(file, flag, images, id_gen, duplicateIDs, importPACP, importLACP, logFile, [markCompleted])` | BOTH | Import from PACP MDB (requires transaction) |
| `MACP_export` | `(filename, options_hash)` | BOTH | Export manhole surveys to MACP MDB |
| `MACP_import` | `(filename, options_hash)` | BOTH | Import manhole surveys from MACP MDB |

**`PACP_export` / `MACP_export` options hash keys:**

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `"Selection Only"` | Boolean | false | Export only selected surveys |
| `"Imperial"` | Boolean | false | true = imperial units |
| `"Images"` | Boolean | false | Export images alongside MDB |
| `"LogFile"` | String | nil | Log file path |
| `"Format"` | String | `"7"` | MDB version: `"6"` or `"7"` |
| `"InfoAsset"` | Integer/nil | nil | PACP only: 1–10 for custom field mapping |

**`MACP_import` options hash keys:**

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `'IDs'` | String | — | `'ManholeNumberDateAndTime'`, `'ManholeNumberAndIndex'`, `'InspectionID'`, `'CustomField'` |
| `'CustomField'` | Integer | — | Required if IDs = `'CustomField'` |
| `'IfBlankUseInspectionID'` | Boolean | false | Fallback to Inspection ID |
| `'UpdateDuplicates'` | Boolean | false | Cannot be false when IDs = `'ManholeNumberAndIndex'` |
| `'Images'` | Boolean | false | Import images |
| `'LogFile'` | String | `''` | Log file path |
| `'Flag'` | String | `''` | Flag for imported fields |

**`pacp_import_cctv_surveys` positional parameters:**

| # | Name | Type | Notes |
|---|------|------|-------|
| 1 | filename | String | Path to PACP MDB |
| 2 | flag | String | Flag for imported records |
| 3 | images | Boolean | Import images |
| 4 | generateIDsFrom | Integer | 1=Upstream+Dir+Date+Time, 2=Upstream+Dir+Index, 3=InspectionID, 4–13=Custom |
| 5 | duplicateIDs | Boolean | true = overwrite existing |
| 6 | importPACP | Boolean | Import pipe surveys |
| 7 | importLACP | Boolean | Import lateral surveys |
| 8 | logFile | String | Log file path |
| 9 | markCompleted | Boolean | Optional: mark imported surveys as completed |

> **Transaction required:** Wrap `pacp_import_cctv_surveys` in `net.transaction_begin` / `net.transaction_commit`.

### BEFDSS Survey Methods

| Method | Params | Receiver | Notes |
|--------|--------|----------|-------|
| `befdss_export` | `file, type, images, selection_only, log_file` | WSNumbatNetworkObject | BEFDSS XML export |
| `befdss_import_cctv` | `file, flag, images, match_existing, id_gen, duplicate_ids, log_file` | WSNumbatNetworkObject | BEFDSS CCTV import |
| `befdss_import_manhole_surveys` | `file, flag, images, match_existing, id_gen, duplicate_ids, log_file` | WSNumbatNetworkObject | BEFDSS manhole import |

> **Receiver note:** BEFDSS methods are called on the model object (`WSNumbatNetworkObject`) — do NOT call `.open` first.

### Report Generation

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `generate_report` | `table, sub_type, title, output_path` | void | BOTH | Generate a Word/HTML report for the currently selected object |

**Parameters:**
- `table` — database table name (e.g., `'cams_cctv_survey'`, `'cams_manhole_survey'`)
- `sub_type` — `nil` for default report; `'MSCC'` for MSCC CCTV format; `'PACP'` for PACP format
- `title` — title/header text shown on the report (typically `ro.id`)
- `output_path` — output file path; use `.doc` for Word, `.html` for HTML

**Prerequisite:** The target object must be selected (`ro.selected = true`) and be the only selected object before calling.

### Validation and Inference

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `validate` | `scenarios` | WSValidations | BOTH | Validate scenario(s); pass nil, String, or Array |
| `run_inference` | `inference, ground_model, mode, zone, error_file` | void | BOTH | Run an inference object on the network |

**`validate` scenarios parameter:** `nil` (Base scenario), `'ScenarioName'` (one scenario), `['Base','S1','S2']` (multiple).

**`run_inference` mode values:** `nil`/`false`/`'Network'`, `true`/`'Selection'`, `'Zone'`, `'Category'`.

### Scenarios

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `scenarios` | `{ \|s\| }` | String | BOTH | Iterates scenario names; includes `'Base'` |
| `current_scenario` | — | String | BOTH | Current scenario name |
| `current_scenario=` | `name` | void | BOTH | Set current scenario (nil → Base) |
| `add_scenario` | `name, based_on, notes` | void | BOTH | Add a new scenario |
| `delete_scenario` | `name` | void | BOTH | Delete a scenario |

### Network Object

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `model_object` | — | WSModelObject | BOTH | The WSModelObject for this network (or its sim) |
| `network_model_object` | — | WSModelObject | BOTH | Always the network WSModelObject (not sim) |

### Network Operations

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `clean_up_network` | `options` | void | BOTH | Run network cleanup routines |
| `delete_selection` | — | void | BOTH | Delete currently selected objects |
| `set_projection_string` | `string` | void | EXCHANGE | Set the map projection string |

> **Note:** Some repository examples call `net.commit('message')` and `net.revert` directly on the `WSOpenNetwork` object. These are convenience delegations to the underlying `WSNumbatNetworkObject`. The canonical approach is to call `commit`/`revert` on the model object (before `.open`), but both paths work at runtime.

---

## WSRowObject

Represents one object (row) in a network table.

### Method Reference

| Method | Params | Return | Availability | Notes |
|--------|--------|--------|--------------|-------|
| `[]` | `field` | Any | BOTH | Get field value by name |
| `[]=` | `field, value` | void | BOTH | Set field value by name |
| `.field` | — | Any | BOTH | Get field using dot syntax (where name is valid Ruby method name) |
| `.field=` | `value` | void | BOTH | Set field using dot syntax |
| `id` | — | String | BOTH | Primary ID string; multi-part IDs (e.g. link) separated by `.` |
| `id=` | `new_id` | void | BOTH | Set primary ID |
| `autoname` | — | void | BOTH | Set ID using network autonaming convention |
| `write` | — | void | BOTH | Write pending field changes (must be inside a transaction) |
| `delete` | — | void | BOTH | Delete this object (immediate; does not require `write`, but must be inside a transaction) |
| `table` | — | String | BOTH | Table name of this object e.g. `'cams_pipe'` |
| `category` | — | String | BOTH | Category e.g. `'_links'`, `'_nodes'` |
| `table_info` | — | WSTableInfo | BOTH | Schema metadata for this object's table |
| `field` | `name` | WSFieldInfo? | BOTH | Schema metadata for one field |
| `selected?` | — | Boolean | BOTH | Whether this object is currently selected |
| `selected=` | `bool` | void | BOTH | Select or deselect this object |
| `navigate` | `type` | Array | BOTH | Navigate to related objects (one-to-many) — see Navigate Types |
| `navigate1` | `type` | WSRowObject? | BOTH | Navigate to one related object (one-to-one) |
| `contains?` | `other` | Boolean | BOTH | For polygons: does this polygon contain another object? |
| `is_inside?` | `other` | Boolean | BOTH | Is this object inside a polygon? |
| `objects_in_polygon` | `type` | Array | BOTH | For polygons: all objects inside this polygon matching type |
| `results` | `field` | Array | BOTH | Array of result values for all timesteps |
| `result` | `field` | Float | BOTH | Result value at the current timestep |
| `gauge_results` | `field` | Array | BOTH | Result values at gauge timesteps |
| `_*` | — | Any | BOTH | Get tag (temporary script value) e.g. `ro._seen` |
| `_*=` | `value` | void | BOTH | Set tag e.g. `ro._seen = true` |

> **Attachment/image path resolution:** Fields like `db_ref`, `detail_image`, `location_photo`, `internal_image`, etc. store **relative filenames** (not absolute paths). To check file existence, concatenate a root directory + the field value: `File.exist?(root_path + ro['detail_image'])`. The root is typically the SNumbatData subdirectory for the database (see WSDatabase `guid` note above).

### Navigate Types

From `WSRowObject.navigate(type)` or `navigate1(type)`:

See `InfoAsset_Manager_Ruby_Schema.md` → **Navigate Types** for the full table of 35+ navigation relationships.

**Notes:**
- Use `navigate(type)` (returns Array) for one-to-many relationships.
- Use `navigate1(type)` (returns WSRowObject?) for one-to-one relationships.
- `navigate` is safe for both; one-to-one via `navigate` returns a single-element array.

### Tags

Tags are temporary per-object script variables. They are not persisted and do not require a transaction.

```ruby
ro._visited = true
next if ro._visited
ro._score = 42
```

Tag names may only contain alphanumeric characters (letters and numbers).

> **Multi-trace reset:** When tracing from multiple starting objects independently, reset `_seen` tags on all links before each trace: `net.row_objects('_links').each { |l| l._seen = false }`. Without this, subsequent traces inherit visited state from earlier ones and will skip links.

---

## WSRowObjectCollection

An ordered collection of WSRowObject instances.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `each` | `{ \|ro\| }` | WSRowObject | Iterate all objects |
| `[]` | `index` | WSRowObject? | Zero-based index access |
| `length` | — | Integer | Count of objects |

```ruby
net.row_object_collection('cams_pipe').each do |ro|
  puts ro['pipe_id']
end
```

---

## WSModelObjectCollection

An ordered collection of WSModelObject instances.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `each` | `{ \|mo\| }` | WSModelObject | Iterate all objects |
| `[]` | `index` | WSModelObject? | Zero-based index access |
| `length` | — | Integer | Count of objects |

---

## WSTableInfo

Schema metadata for a network table. Obtained from `net.table(name)` or `ro.table_info`.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `name` | — | String | Internal table name e.g. `'cams_pipe'` |
| `description` | — | String | UI display name e.g. `'Pipe'` |
| `fields` | — | Array | Array of WSFieldInfo (excludes results fields) |
| `results_fields` | — | Array | Array of WSFieldInfo for results (only when results loaded) |
| `tableinfo_json` | — | String | Full table info as JSON string |

---

## WSFieldInfo

Schema metadata for one field. Obtained from `table_info.fields`, `ro.field(name)`, or `net.table(name).fields`.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `name` | — | String | Database field name (use this with `ro['name']`) |
| `description` | — | String | UI display name / label |
| `data_type` | — | String | InfoWorks type string — see type map below |
| `size` | — | Integer | Max length for String fields; 0 for others |
| `read_only?` | — | Boolean | Whether this field can be written |
| `has_time_varying_results?` | — | Boolean | Whether this field has time-varying results |
| `fields` | — | Array? | Sub-fields if the field is a structure blob; nil otherwise |

**InfoWorks data type → Ruby type:**

| WS Type | Ruby Type |
|---------|-----------|
| `'Flag'` | String |
| `'Boolean'` | Boolean |
| `'Single'` | Float |
| `'Double'` | Float |
| `'Short'` | Integer |
| `'Long'` | Integer |
| `'Date'` | DateTime |
| `'String'` | String |
| `'Array:Long'` | Array |
| `'Array:Double'` | Array |
| `'WSStructure'` | WSStructure |
| `'GUID'` | String |

---

## WSStructure

A structure-blob field of a WSRowObject — a table-within-a-row.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `length` | — | Integer | Number of rows |
| `length=` | `n` | void | Set number of rows (resizes; new rows are blank) |
| `[]` | `index` | WSStructureRow? | Zero-based index access |
| `each` | `{ \|row\| }` | WSStructureRow | Iterate all rows |
| `write` | — | void | Write changes (also call `ro.write` on the parent) |

**Usage pattern:**
```ruby
struct = ro['cross_section_data']    # Get structure blob
struct.each { |row| puts row['flow'] }

net.transaction_begin
struct.length = struct.length + 1    # Add one row
struct[struct.length - 1]['flow'] = 1.5
struct.write
ro.write
net.transaction_commit
```

---

## WSStructureRow

One row in a WSStructure.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `[]` | `field` | Any | Get field value |
| `[]=` | `field, value` | void | Set field value (call `struct.write` and `ro.write` to persist) |

---

## WSCommit

One commit in a network's version history.

| Method | Params | Return | Availability |
|--------|--------|--------|--------------|
| `commit_id` | — | Integer | EXCHANGE |
| `branch_id` | — | Integer | EXCHANGE |
| `date` | — | DateTime | EXCHANGE |
| `user` | — | String | EXCHANGE |
| `comment` | — | String | EXCHANGE |
| `inserted_count` | — | Integer | EXCHANGE |
| `modified_count` | — | Integer | EXCHANGE |
| `deleted_count` | — | Integer | EXCHANGE |
| `setting_changed_count` | — | Integer | EXCHANGE |

---

## WSCommits

Collection of WSCommit objects from `network_mo.commits`.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `length` | — | Integer | Number of commits |
| `[]` | `index` | WSCommit? | Zero-based index |
| `each` | `{ \|c\| }` | WSCommit | Iterate all commits |

---

## WSLink

Inherits from WSRowObject. Available for link-category objects.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `us_node` | — | WSNode? | Upstream node |
| `ds_node` | — | WSNode? | Downstream node |

---

## WSNode

Inherits from WSRowObject. Available for node-category objects.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `us_links` | — | WSRowObjectCollection | Upstream links |
| `ds_links` | — | WSRowObjectCollection | Downstream links |

---

## WSValidations

Collection of WSValidation objects returned by `net.validate(...)`.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `length` | — | Integer | Total count of all validation messages |
| `error_count` | — | Integer | Count of error-priority messages only |
| `warning_count` | — | Integer | Count of warning-priority messages only |
| `each` | `{ \|v\| }` | WSValidation | Iterate all messages |

> **Note:** `error_count + warning_count` does not necessarily equal `length` — informational/advisory messages count in `length` but not in either counter. Always use `length` for total.

---

## WSValidation

One validation message from `validations.each`.

| Method | Params | Return | Notes |
|--------|--------|--------|-------|
| `code` | — | String | Validation code |
| `message` | — | String | Human-readable message |
| `object_id` | — | String | ID of the object that failed |
| `object_type` | — | String | Table/type of the object |
| `field` | — | String | Field name involved |
| `field_description` | — | String | UI label of the field |
| `priority` | — | String | `'Error'`, `'Warning'`, or other |
| `type` | — | String | Validation type |
| `scenario` | — | String | Scenario in which the message was raised |

---

## Excluded ICM/WS Pro-Only Methods

The following methods exist in the full Ruby API but are **not available in InfoAsset Manager**. Do not generate IAM code that uses these.

> **Note:** `validate`, `run_inference`, scenario methods, and `WSNumbatNetworkObject` methods ARE valid for InfoAsset Manager. They are documented in the main body above and must not be excluded from IAM scripts.

**WSApplication (not for IAM):** `cancel_job`, `connect_local_agent`, `launch_sims`, `launch_sims_ex`, `wait_for_jobs`, `rpa_export`, `background_network`

**WSModelObject (not for IAM):** `new_run`, `new_risk_analysis_run`, `new_synthetic_rainfall`, `import_all_sw_model_objects`, `import_new_sw_model_object`, `import_grid_ground_model`, `import_infodrainage_object`, `import_new_model_object`, `import_new_model_object_from_generic_csv_files`, `import_data`, `import_tvd`, `csv_import_tvd`, `delete_results`, `update_to_latest`, `generate_sim_stats`

**WSOpenNetwork (not for IAM):** `cancel_mesh_job`, `download_mesh_job_log`, `infodrainage_import`, `load_mesh_job`, `mesh`, `mesh_async`, `mesh_job_status`, `xprafts_import`, `current_timestep`, `current_timestep=`, `current_timestep_time`, `timestep_count`, `timestep_time`, `list_timesteps`, `gauge_timestep_count`, `gauge_timestep_time`, `list_gauge_timesteps`

**Entire classes not for IAM:** `WSSimObject`, `WSRiskAnalysisRunObject`, `WSSWMMRunBuilder`, `WSOpenTSD`, `WSTSDObject`

---

## Key Behaviours and Conventions

- Ruby version in IAM 2027.0+: **Ruby 3.4.6**. Prior versions use Ruby 2.4.0.
- External gems supported from **version 2027.0** only.
- Field access via `ro['field_name']` or `ro.field_name` (dot syntax limited to valid Ruby method names).
- `nil` values are valid field values (equivalent to NULL). Unlike SQL, nil comparisons in Ruby require explicit `.nil?` checks.
- Always call `ro.write` after setting fields, within a `transaction_begin`/`transaction_commit` block.
- Structure blob fields require `struct.write` AND `ro.write` to persist changes.
- Tags (`ro._name = value`) are temporary and not persisted.
- `WSApplication.script_file` returns the path of the first running script — useful for finding config files co-located with the script.
- `Dir.glob` on Windows: normalize backslash paths with `path.gsub('\\', '/')` before globbing.
- Use `WSApplication.message_box` for user feedback (4 args). Do not use bare `exit` — use `raise 'abort'` with a rescue block instead.

---

## Repository Evidence Citations

The following table maps key methods to repository example folders where they are observed in use.

### Shared (UI + Exchange) Methods

| Method | Evidence Folders |
|--------|-----------------|
| `WSApplication.ui?` | `0029 List Database Objects Contents`, `0001 ODEC Export`, `0009 Import-Export MACP-PACP Survey Data` |
| `odec_export_ex` | `0001 ODEC Export`, `0035 Export CCTV Surveys to WSAA XML` |
| `odic_import_ex` | `0002 ODIC Import` |
| `GIS_export` | `0004 GIS Export` |
| `pacp_import_cctv_surveys` / `pacp_export` | `0009 Import-Export MACP-PACP Survey Data` |
| `macp_import` / `macp_export` | `0009 Import-Export MACP-PACP Survey Data` |

### UI Methods

| Method | Evidence Folders |
|--------|-----------------|
| `WSApplication.current_network` | `0040 Convert Coordinate Values`, `0020 Generate Individual Reports`, `0041 Export to GeoJSON` |
| `WSApplication.prompt` | `0040`, `0016 Update from object comparison`, `0035`, `0022 Rename Exported Files` |
| `WSApplication.message_box` | `0040`, `0038 Import INTERLIS`, `0022`, `0041` |
| `generate_report` | `0020 Generate Individual Reports for a Selection of Objects` |

### Exchange Methods

| Method | Evidence Folders |
|--------|-----------------|
| `WSApplication.open(...)` | `0001 ODEC Export`, `0002 ODIC Import`, `0004 GIS Export`, `0006 Snapshot`, `0010 BEFDSS XML`, `0025 Copy Network Attachments` |
| `WSApplication.use_arcgis_desktop_licence` | `0004 GIS Export/IE-GIS_export-SHP.rb` |

---

## Version Notes

- `pacp_import_cctv_surveys`, `pacp_export`, `macp_import`, and `macp_export` are documented in the repo as InfoAsset Manager methods available in later product versions. Confirm exact version behavior against official Help before generating new code.
- Repository examples show mixed capitalization in some method calls for PACP and MACP methods. Prefer the documented spellings above and verify against Help or runtime.

---

## Mode Guidance

### UI Scripts

- Start from `WSApplication.current_network`.
- Keep prompts and message boxes inside UI code paths.
- If a script needs both UI and Exchange, use a dual-mode pattern instead of forcing UI methods into Exchange.

### Exchange Scripts

- Exchange examples typically open a database, fetch a model object, then operate on it.
- Hard-coded database paths and object IDs are common in examples but should be treated as placeholders.
- Keep unattended batch processing in Exchange-only scripts unless a dual-mode wrapper is deliberate.

### Avoid In UI Files

- Explicit `WSApplication.open(...)` database flows unless inside an Exchange branch.
- Unattended batch workflows as the default UI pattern.

### Avoid In Exchange Files

- `WSApplication.current_network` as the primary entry point.
- UI prompts or message boxes as required control flow.
- Assumptions about an already-open GeoPlan context.

### Do Not Infer

- Do not assume shared network methods exist in InfoWorks ICM or InfoWorks WS Pro just because names look similar.
- Do not infer UI-only prompts from a shared method or Exchange-only database flows from a shared method.
