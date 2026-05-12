# Import / Export Snapshot Files

This folder contains Ruby scripts for importing and exporting InfoAsset Manager snapshot files (`.isfc` / `.isf`).

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
