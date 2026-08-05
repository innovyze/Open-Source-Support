# Import / Export MSCC CCTV Survey Data

Ruby examples for importing and exporting **MSCC4 XML** CCTV survey data in InfoAsset Manager and InfoAsset Exchange.

The underlying network methods are `mscc_export_cctv_surveys` and `mscc_import_cctv_surveys`. These must be run on an open network.

## Version compatibility

The methods `mscc_export_cctv_surveys` and `mscc_import_cctv_surveys` are available in InfoAsset Manager and InfoAsset Exchange. Run from the UI with a relevant network open, or via Exchange using a `UIIE` script.

## API reference

### `mscc_export_cctv_surveys`

`net.mscc_export_cctv_surveys(export_file, export_images, selection_only, log_file)`

| Parameter | Format | Notes |
|-----------|--------|-------|
| `export_file` | String | Full path of the XML file to export to |
| `export_images` | Boolean | `true` to export defect images to the same folder as the XML |
| `selection_only` | Boolean | `true` to export only selected CCTV surveys |
| `log_file` | String or `nil` | Path of a log file for export errors; `nil` for no log file |

Returns `Boolean`.

### `mscc_import_cctv_surveys`

`net.mscc_import_cctv_surveys(import_file, import_flag, import_images, id_gen, overwrite, log_file)`

| Parameter | Format | Notes |
|-----------|--------|-------|
| `import_file` | String | Full path of the XML file to import from |
| `import_flag` | String | Flag applied to imported data (for example `BDGR`) |
| `import_images` | Boolean | `true` to import images |
| `id_gen` | Integer | Survey ID generation mode — see table below |
| `overwrite` | Boolean | `false` to prevent overwriting existing surveys when IDs clash |
| `log_file` | String | Path of a log file for import errors |

**`id_gen` values:**

| Value | Description |
|-------|-------------|
| 1 | StartNodeRef, Direction, Date and Time |
| 2 | StartNodeRef, Direction and index |
| 3 | US node ID, Direction, Date and Time |
| 4 | US node ID, Direction and index |
| 5 | ClientDefined1 |
| 6 | ClientDefined2 |
| 7 | ClientDefined3 |

## Scripts in this folder

| Script | UI | Exchange | Purpose |
|--------|:--:|:--------:|---------|
| [UIIE-mscc_export_cctv_surveys.rb](./UIIE-mscc_export_cctv_surveys.rb) | ✓ | ✓ | Basic MSCC export example |
| [UIIE-mscc_import_cctv_surveys.rb](./UIIE-mscc_import_cctv_surveys.rb) | ✓ | ✓ | Basic MSCC import example |
| [UI-mscc_export_cctv_surveys-IndividualFiles.rb](./UI-mscc_export_cctv_surveys-IndividualFiles.rb) | ✓ | | Export current selection — one XML per survey |
| [UI-mscc_export_cctv_surveys-IndividualFiles-IncLog.rb](./UI-mscc_export_cctv_surveys-IndividualFiles-IncLog.rb) | ✓ | | Same as above, with a CSV export log |
| [UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles.rb](./UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles.rb) | ✓ | | Run one stored SQL query, then export selection — one XML per survey |
| [UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles-IncLog.rb](./UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles-IncLog.rb) | ✓ | | Same as above, with a CSV export log |
| [UIIE-mscc_export_cctv_surveys-RunMultipleQueries.rb](./UIIE-mscc_export_cctv_surveys-RunMultipleQueries.rb) | ✓ | ✓ | Run multiple stored SQL queries and export after each |

---

## [UIIE-mscc_export_cctv_surveys.rb](./UIIE-mscc_export_cctv_surveys.rb)

Minimal example calling `mscc_export_cctv_surveys`.

- **UI:** uses the current open network.
- **Exchange:** opens Collection Network `#2` — edit the network ID on line 12 as required.

Edit the export path, image export, selection-only flag, and log file path on line 16 before running.

---

## [UIIE-mscc_import_cctv_surveys.rb](./UIIE-mscc_import_cctv_surveys.rb)

Minimal example calling `mscc_import_cctv_surveys`.

- **UI:** uses the current open network.
- **Exchange:** opens Collection Network `#2` — edit the network ID on line 21 as required.

Edit the import path, flag, image import, ID generation mode, overwrite setting, and log file path on line 25 before running.

---

## [UI-mscc_export_cctv_surveys-IndividualFiles.rb](./UI-mscc_export_cctv_surveys-IndividualFiles.rb)

Exports each CCTV survey in the **current GeoPlan selection** to a separate XML file.

Configure on lines 2–3:

- `exportloc` — export folder (must exist)
- `file` — filename prefix (default `MSCC_`)

Output filenames follow the pattern `{prefix}{index}_{SurveyID}.xml`. Non-alphanumeric characters (except `_` and `-`) are removed from the survey ID in the filename.

Requires surveys to be selected before running the script.

---

## [UI-mscc_export_cctv_surveys-IndividualFiles-IncLog.rb](./UI-mscc_export_cctv_surveys-IndividualFiles-IncLog.rb)

Same behaviour as [UI-mscc_export_cctv_surveys-IndividualFiles.rb](./UI-mscc_export_cctv_surveys-IndividualFiles.rb), but also writes a timestamped CSV log to the export folder listing each survey ID and output filename.

---

## [UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles.rb](./UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles.rb)

Runs a **single stored SQL query**, then exports each selected CCTV survey to a separate XML file.

Configure on lines 2–6:

- `exportloc` — export folder (must exist)
- `file` — filename prefix
- `run_stored_query_object(1215)` — replace `1215` with your stored query database object ID

The stored query should select CCTV survey objects (or objects that resolve to `cams_cctv_survey` in the selection). Stored query IDs can be listed using [UIIE-DatabaseContents.rb](../0029%20List%20Database%20Objects%20Contents/UIIE-DatabaseContents.rb) in folder `0029`.

---

## [UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles-IncLog.rb](./UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles-IncLog.rb)

Same behaviour as [UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles.rb](./UI-mscc_export_cctv_surveys-RunQuery-ExportIndividualFiles.rb), with an additional timestamped CSV export log.

---

## [UIIE-mscc_export_cctv_surveys-RunMultipleQueries.rb](./UIIE-mscc_export_cctv_surveys-RunMultipleQueries.rb)

Runs **multiple stored SQL queries** in sequence. After each query, exports the selected CCTV surveys using `mscc_export_cctv_surveys`.

This is the most configurable script in the folder. In the UI, all options are entered via a prompt dialog. In Exchange, set values in the **EXCHANGE CONFIG** section at the top of the script.

### Workflow

1. Prompt for export settings (UI) or read **EXCHANGE CONFIG** (Exchange).
2. Validate that the export folder exists.
3. For each stored query ID:
   - Clear the current selection.
   - Run the stored query via `run_stored_query_object`.
   - Export selected `cams_cctv_survey` objects.
4. Write a timestamped log file to the export folder.

### Prompt options (UI)

| Option | Default | Notes |
|--------|---------|-------|
| Export folder | `C:\Temp\export\` | Must be an **existing** folder. If the folder is missing, a warning is shown and the prompt reopens. |
| Export file prefix (optional) | `MSCC_` | Prepended to XML and log filenames. Leave blank to use `MSCC_`. |
| Stored query IDs (comma separated) | — | Database object IDs, for example `2602,2603` |
| Export labels (comma separated, optional) | — | One label per query, same order as the IDs. Used in filenames instead of the query ID. Leave blank to use query IDs. |
| Individual XML files per survey | false | `false` = one combined XML per stored query; `true` = one XML per selected survey |
| Export defect images | false | Images are saved alongside the XML files |

### Output filenames

**Combined export** (Individual files = false):

```
{export folder}\{prefix}{label}.xml
```

Example: `C:\Temp\export\MSCC_Area_A.xml`

**Individual files** (Individual files = true):

```
{export folder}\{prefix}{label}_{index}_{SurveyID}.xml
```

Example: `C:\Temp\export\MSCC_Area_A_0_Survey123.xml`

**Log file** (always written):

```
{export folder}\{prefix}Export_{YYYYMMDD_HHMMSS}.log
```

Example: `C:\Temp\export\MSCC_Export_20250805_154600.log`

### EXCHANGE CONFIG

When running via Exchange, edit these variables at the top of the script:

```ruby
export_folder = 'C:\\Temp\\export\\'
export_images = false
individual_files = false
stored_query_ids = '2602,2603'
query_labels = ''
file_prefix = 'MSCC_'
```

Also confirm the Collection Network ID on line 75 (`Collection Network`, `2`) matches your database.

### Stored query requirements

Each stored SQL query must produce a GeoPlan selection that includes the CCTV surveys to export. The script reads selected objects from the `cams_cctv_survey` table after each query runs.

To find stored query IDs, run [UIIE-DatabaseContents.rb](../0029%20List%20Database%20Objects%20Contents/UIIE-DatabaseContents.rb) and look under **Stored Query**.

### Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `Export folder not found` | The folder path does not exist. Create the folder first, or choose an existing folder in the prompt. |
| `Export failed: ... contains an incorrect path` | Same as above — the export folder was missing when the export ran. |
| `No stored query IDs provided` | The stored query IDs field was empty. |
| Query runs but 0 surveys exported | The stored query did not select any `cams_cctv_survey` objects. Check the query selects surveys, not only pipes or other asset types. |
| Unexpected filename | Check export labels align with query IDs by position. A missing label falls back to the query ID. |
