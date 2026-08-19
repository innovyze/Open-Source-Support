# Import / Export Snapshot Files

This folder contains Ruby scripts for importing and exporting InfoAsset Manager snapshot files.

**Snapshot file extensions by network type:**

| Network type | Extension |
|--------------|-----------|
| Collection (CAMS) | `.isfc` |
| Distribution (WAMS) | `.isfd` |
| Asset (AMS) | `.isfa` |

Legacy `.isf` imports are supported by the bulk import scripts.

## API reference

### `snapshot_export_ex`

`net.snapshot_export_ex(export_file, options)`

| Parameter | Format | Notes |
|-----------|--------|-------|
| `export_file` | String | Full path of the snapshot file to export to (`.isfc`, `.isfd`, or `.isfa` depending on network type) |
| `options` | Hash | Export options — see table below |

**Common `options` keys:**

| Key | Format | Default | Notes |
|-----|--------|---------|-------|
| `SelectedOnly` | Boolean | `false` | Export only selected network objects |
| `IncludeImageFiles` | Boolean | `false` | Include attached image files |
| `IncludeGeoPlanPropertiesAndThemes` | Boolean | `false` | Include GeoPlan properties and themes |
| `ChangesFromVersion` | Integer | `0` | Export differential from a given version |
| `Tables` | Array of strings | *(all tables)* | Limit export to specific internal table names |

### `snapshot_import_ex`

Used by the bulk import scripts in this folder. See [UI-Snapshot-Bulk-Import.rb](./UI-Snapshot-Bulk-Import.rb) for option examples.

## Scripts in this folder

| Script | UI | Exchange | Purpose |
|--------|:--:|:--------:|---------|
| [UI-snapshot_export_ex.rb](./UI-snapshot_export_ex.rb) | ✓ | | Single snapshot export with Save As dialog |
| [IE-snapshot_export_ex.rb](./IE-snapshot_export_ex.rb) | | ✓ | Basic Exchange snapshot export example |
| [UIIE-snapshot_export_ex-GroupByField.rb](./UIIE-snapshot_export_ex-GroupByField.rb) | ✓ | ✓ | Group objects from selected tables by field; export one snapshot per group |
| [UI-Snapshot-Bulk-Import.rb](./UI-Snapshot-Bulk-Import.rb) | ✓ | | Bulk import from a hardcoded folder |
| [UI-Snapshot-Bulk-Import-FolderSelect.rb](./UI-Snapshot-Bulk-Import-FolderSelect.rb) | ✓ | | Bulk import with folder browser |
| [UI-Snapshot-Bulk-Import-Filename.rb](./UI-Snapshot-Bulk-Import-Filename.rb) | ✓ | | Bulk import filtered by filename |
| [IE-Snapshot-Bulk-Import.rb](./IE-Snapshot-Bulk-Import.rb) | | ✓ | Bulk import via Exchange |

---

## Export Scripts

### `UI-snapshot_export_ex.rb` — UI, single network export
Run from the Network menu > Run Ruby Script... Does not require an Exchange licence.

A Save As dialog opens so you can choose the export destination. The script uses `snapshot_export_ex` with configurable options:

| Option | Default | Description |
|---|---|---|
| `SelectedOnly` | `false` | Export only selected objects |
| `IncludeImageFiles` | `false` | Include attached image files |
| `IncludeGeoPlanPropertiesAndThemes` | `false` | Include GeoPlan properties and themes |
| `ChangesFromVersion` | `0` | Export differential from a given version |
| `Tables` | *(all)* | Limit export to specific table names |

### `IE-snapshot_export_ex.rb` — Exchange, single network export
Run via InfoAsset Exchange outside of the InfoAsset Manager interface. The Database connection and Network ID are set on lines 3–4.

### [UIIE-snapshot_export_ex-GroupByField.rb](./UIIE-snapshot_export_ex-GroupByField.rb)

Groups **network objects** from one or more object tables by a shared field value, then exports **one snapshot file per group**. The file extension is chosen automatically from the open network type (`.isfc` for Collection, `.isfd` for Distribution, `.isfa` for Asset).

Object table selection uses the same checkbox pattern as [UI-SelectNetworkObjectsBySharedFieldValue.rb](../0036%20Select%20Objects/UI-SelectNetworkObjectsBySharedFieldValue.rb): tick one, several, or **Select / deselect all object tables**.

This script mirrors the grouping behaviour of [UIIE-mscc_export_cctv_surveys-GroupByField.rb](../0008%20Import-Export%20MSCC%20Survey%20Data/UIIE-mscc_export_cctv_surveys-GroupByField.rb), but writes InfoAsset snapshot files via `snapshot_export_ex` instead of MSCC XML.

#### Workflow

1. Prompt to select object table(s) from the open network (UI) or read **source_tables** (Exchange).
2. Prompt for export settings (UI) or read remaining **EXCHANGE CONFIG** values (Exchange).
3. Validate that the export folder exists.
4. Read objects from the selected tables — current GeoPlan selection or all rows in those tables.
5. Group objects by the configured field (objects from different tables with the same field value are placed in the same group).
6. Show a pre-flight summary and confirm (UI only).
7. Export one snapshot per group and write a timestamped run log and CSV summary.

Each export uses `SelectedOnly = true` with the relevant object(s) selected before calling `snapshot_export_ex`.

#### Prompt options (UI)

**Prompt 1 — object tables**

| Option | Notes |
|--------|-------|
| Select / deselect all object tables | Tick to include every table in the network |
| *(one checkbox per table)* | Tick individual tables such as `cams_cctv_survey`, `cams_manhole_survey`, `cams_pipe`, etc. |

**Prompt 2 — export settings**

| Option | Default | Notes |
|--------|---------|-------|
| Export folder | `C:\Temp\export\` | Must be an **existing** folder. |
| Export file prefix (optional) | `Snapshot_` | Prepended to snapshot, log, and summary filenames. Leave blank to use `Snapshot_`. |
| Process selection only? | true | Checked = current GeoPlan selection only. Unchecked = all objects in the selected tables. |
| Group field | `user_text_5` | Field on the object, or on a related pipe using `pipe.fieldname`. |
| Label for blank group values (optional) | `Unknown` | Used when an object has no group value and **Skip objects with blank group values** is unchecked. |
| Skip objects with blank group values | false | When checked, objects with a blank group value are excluded from export. |
| Include image files | false | Maps to `IncludeImageFiles` in `snapshot_export_ex` |
| Include GeoPlan properties and themes | false | Maps to `IncludeGeoPlanPropertiesAndThemes` |
| Create subfolder per group | false | When checked, each group exports into `{export folder}\{group}\` |

Pipe fields (`pipe.fieldname`) are resolved via object navigation, survey link fields (`us_node_id`, `ds_node_id`, `link_suffix`), `asset_id`, or `plr`. Pipe rows (`cams_pipe`, `wams_pipe`) can be grouped directly using `pipe.fieldname`.

#### Output filenames

The extension depends on the network profile detected from table names in the open network:

| Network | Extension | Example |
|---------|-----------|---------|
| Collection (CAMS) | `.isfc` | `Snapshot_PCL001.isfc` |
| Distribution (WAMS) | `.isfd` | `Snapshot_PCL001.isfd` |
| Asset (AMS) | `.isfa` | `Snapshot_PCL001.isfa` |

**One snapshot per group:**

```
{export folder}\{prefix}{group}.{isfc|isfd|isfa}
```

**With subfolder per group:**

```
{export folder}\{group}\{prefix}{group}.{isfc|isfd|isfa}
```

**Log files** (always written):

```
{export folder}\{prefix}Export_{YYYYMMDD_HHMMSS}.log
{export folder}\{prefix}ExportSummary_{YYYYMMDD_HHMMSS}.csv
```

The CSV summary lists each group, object count, output filename, status (`OK` / `Failed`), and object IDs in `table:id` format (for example `cams_cctv_survey:Survey123`).

#### EXCHANGE CONFIG

```ruby
export_folder = 'C:\\Temp\\export\\'
include_image_files = false
include_geoplan_properties = false
subfolder_per_group = false
skip_blank_groups = false
selection_only = true
source_tables = 'cams_cctv_survey'
group_field = 'user_text_5'
blank_group_label = 'Unknown'
file_prefix = 'Snapshot_'
```

Set `source_tables` to a comma-separated list of internal table names. Leave blank to include **all** tables in the network. Set `selection_only = false` to process all rows in those tables. Confirm the Collection Network ID on line 355 (`Collection Network`, `2`) matches your database.

#### Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `No object tables were found` | The network has no tables, or it is not open. |
| `No object tables were selected` | No table was ticked in the first prompt. |
| `No objects found in the current selection` | Nothing selected on the GeoPlan for the chosen tables. |
| All objects in one `Unknown` group | Group field name is wrong, or values are blank on the object / related pipe. |
| `Export folder not found` | Create the export folder first, or choose an existing folder in the prompt. |
| Previous export overwritten | Two different group field values sanitized to the same folder/filename (for example `2` and `2/`). The script replaces invalid characters with `_` and adds a numeric suffix when labels still collide. Check the log for `Export label:` lines. |

---

## Bulk Import Scripts

These scripts import multiple snapshot files from a folder (and its sub-folders) in a single run. [This article](https://innovyze.force.com/support/s/article/Bulk-Data-Imports-Using-Ruby) provides further background.

The Ruby syntax will need to be saved on your machine in a text file with the file type extension of `.rb`.

### Script variants

| Script | How the source folder is chosen | Run from |
|---|---|---|
| `UI-Snapshot-Bulk-Import.rb` | Hardcoded path on line 7 — edit the string directly before running | UI |
| `UI-Snapshot-Bulk-Import-FolderSelect.rb` | Opens a folder browser dialog at run time — no editing required | UI |
| `IE-Snapshot-Bulk-Import.rb` | Hardcoded path — edit before running | Exchange |
| `UI-Snapshot-Bulk-Import-Filename.rb` | Hardcoded path — also filters by a string in the filename | UI |

UI scripts are run from the Network menu > Run Ruby Script... and do not require an Exchange licence.

### Customising the syntax

#### Source Data Directory

**Hardcoded path version (`UI-Snapshot-Bulk-Import.rb` / `IE-Snapshot-Bulk-Import.rb`)**  
Edit the `dir` variable and set the top-level source directory between the quotation marks, ending with a forward slash.

`dir = "C:/Temp/Data/"`

**Folder dialog version (`UI-Snapshot-Bulk-Import-FolderSelect.rb`)**  
When the script runs a folder browser dialog will open. Navigate to and select the import source folder. If the dialog is cancelled the script will exit without importing anything.

#### Source Data File Format
Set the file type extensions on the `ext` line, separating multiple extensions with a comma.

`ext = 'isfc,isf'`

To import into a Distribution network use `.isfd`, Asset network use `.isfa`; for an ICM Model network use `.isfm`.

#### Import Options
The options hash maps directly to the checkboxes shown in the interface import dialog. Set each value to `true` or `false` as required.

`options['AllowDeletes'] = true`

### The Output
Lines beginning with `puts` write progress information to the script output window, confirming each file as it is imported and signalling when the run is complete.

### Filtering by filename
`UI-Snapshot-Bulk-Import-Filename.rb` extends the basic bulk import by only selecting files whose name contains a specific search term. Edit the search string in the `Dir.glob` call before running.
