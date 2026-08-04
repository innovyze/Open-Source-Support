# Version Compatibility
The methods `PACP_import_cctv_surveys`, `PACP_export`, `MACP_import`, `MACP_export` are only available in InfoAsset Manager (& Exchange) version 2023.0 and later.  
The methods must be run on an open network.  

# [PACP_import_cctv_surveys](./UIIE-PACP_import_cctv_surveys.rb)
on.pacp_import_cctv_surveys(filename,flag,images,generateIDsFrom,duplicateIDs,importPACP,importLACP,logFile,markImportedSurveysAsCompleted)  
| Parameter | Format   | Notes        |
|-----------|----------|--------------|
| Filename | String | Filename to import from |
| Flag | String | Flag for imported data |
| Images | Boolean | true to import images |
| GenarateIDsfrom | Integer | The following values are allowed:<br/>1 – Upstream Direction + Date + Time<br/>2 – Upstream Direction + Index<br/>3 – Inspection ID<br/>4 – 13 – Custom (4 = custom field 1, 5 = custom field 2, etc.)   |
| DuplicateIds | String | ignore / update / overwrite |
| ImportPACP | Boolean | true to import PACP data |
| ImportLACP | Boolean | true to import LACP data |
| LogFile | String | Log file path |
| MarkImportedSurveysAsCompleted | Boolean | true to mark imported surveys as completed   |  

It is necessary to run the method within a transaction.  


## [UI-PACP7_import_cctv_surveys_from_CSV](./UI-PACP7_import_cctv_surveys_from_CSV.rb)

Import PACP7 (or LACP) CCTV survey data when the deliverable is a folder of CSV files instead of a single `.mdb` file.

The script expects CSV filenames to match the PACP7 exchange table names and column headings to match the corresponding Access field names. It copies a **PACP7 template MDB** (for example an InfoAsset-exported `.mdb`) to preserve `DB_Version`, lookup tables, and exact field types, loads CSV data into the data tables with typed values, then runs `pacp_import_cctv_surveys` on that MDB.

Use this script when a contractor or third party delivers PACP7 data as CSV exports rather than a complete Access database. The template MDB ensures the temporary database matches the structure InfoAsset Manager expects (integer `InspectionID`, date/time fields, condition-code lookups, and so on).

### PACP7 template MDB

A PACP7 `.mdb` is used as a schema template so the temporary database has the correct field types, lookup tables, and `DB_Version` record. You do not need to supply one in most cases.

The script resolves the template in this order:

1. The file you browse to in **PACP7 template MDB (optional)**, if provided.
2. Otherwise the first `.mdb` in the CSV folder (excluding temp files named `PACP_import_*.mdb`).
3. Otherwise the InfoAsset Manager install file **`PACP_LACPv702.mdb`** from `Program Files\Autodesk\InfoAsset Manager {version}\`.

The template is copied to `%TEMP%` as `PACP_import_YYYYMMDD_HHMMSS.mdb`. Only the CSV-backed data tables are cleared (child tables first, to respect Access relationships) and reloaded. Lookup tables, `DB_Version`, and all other schema remain unchanged from the template.

### Expected CSV files

| CSV filename | Required when |
|--------------|---------------|
| `PACP_Inspections.csv` | Import PACP = true (**required**) |
| `PACP_Conditions.csv` | Import PACP = true (**required**) |
| `PACP_Media_Inspections.csv` | Import PACP = true (optional) |
| `PACP_Media_Conditions.csv` | Import PACP = true (optional) |
| `PACP_Custom_Fields.csv` | Import PACP = true (optional) |
| `PACP_Ratings.csv` | Import PACP = true (optional) |
| `LACP_Inspections.csv` | Import LACP = true (**required**) |
| `LACP_Conditions.csv` | Import LACP = true (**required**) |
| `LACP_Media_Inspections.csv` | Import LACP = true (optional) |
| `LACP_Media_Conditions.csv` | Import LACP = true (optional) |
| `LACP_Custom_Fields.csv` | Import LACP = true (optional) |

Only the inspections (header) and conditions CSVs are mandatory. Media, custom-field, and ratings tables are loaded when present; otherwise they are skipped.

**CSV format rules:**

- The first row must be column headers matching Access field names exactly (for example `InspectionID`, `Inspection_Date`, `Inspection_Time`).
- Filenames are matched case-insensitively (`PACP_Inspections.csv`, `pacp_inspections.csv`, etc.).
- Spaces in filenames are treated as underscores (`PACP Inspections.csv` matches `PACP_Inspections`).
- CSV files in subfolders of the selected folder are also discovered.

### Prompt options

| Option | Default | Notes |
|--------|---------|-------|
| Folder containing CSV files | — | All CSVs for the import should be in this folder |
| PACP7 template MDB (optional) | — | Browse to override; otherwise uses an `.mdb` in the CSV folder, or `PACP_LACPv702.mdb` from the InfoAsset Manager install folder |
| Import PACP pipe surveys? | true | Requires `PACP_Inspections.csv` and `PACP_Conditions.csv`; loads optional `PACP_*` media/custom/ratings CSVs if present |
| Import LACP lateral surveys? | false | Requires `LACP_Inspections.csv` and `LACP_Conditions.csv`; loads optional `LACP_*` media/custom CSVs if present |
| Import images? | true | Passed to `pacp_import_cctv_surveys`; only applies when media CSVs are present and paths are relative to the CSV folder |
| Mark imported surveys as completed? | false | Passed to `pacp_import_cctv_surveys` |
| Generate IDs from | Upstream MH, Direction, Date and Time | Same values as the PACP/LACP import dialog (1–13) |
| Duplicate survey handling | Update existing surveys | String passed to `pacp_import_cctv_surveys`: `ignore` or `update` (must be a string, not a boolean) |
| Flag for imported fields | BDGR | Passed to `pacp_import_cctv_surveys` |
| Keep temporary MDB file? | false | Temp MDB is written to `%TEMP%`; when false, deleted after a successful import |

### Workflow

1. Select the folder containing the PACP/LACP CSV files (and optionally browse to a PACP7 template MDB).
2. Copy the template `.mdb` to `%TEMP%` and clear/reload CSV-backed data tables using ACE/Jet field types read from the template schema.
3. Validate the built MDB (for example confirm `InspectionID` is numeric and date/time fields are populated).
4. Run `pacp_import_cctv_surveys` inside a network transaction.
5. Write an import log alongside the CSV folder (`PACPimport_{folder}_{YYYYMMDD_HHMMSS}.log`) and echo it to the Ruby console.

### Data handling notes

- **Typed columns:** Values are written using the field types defined in the template (integers, dates, booleans, floats, text). Do not rely on creating tables from CSV alone; the template provides the correct schema.
- **Inspection time recovery:** When `PACP_Inspections.csv` contains an Excel-style placeholder time (`00/01/1900`), the script attempts to recover `Inspection_Time` from the corresponding `PACP_Media_Inspections` video filename (for example `_2221` in `..._20180816_2221.MPG` → 22:21:00).
- **Duplicate surveys:** Choose **Update existing surveys** to refresh an existing CCTV survey matched by the selected ID mode. Choose **Do not import duplicates** to skip surveys that already exist in the network.

### Requirements

InfoAsset Manager 2023.0+ (`pacp_import_cctv_surveys`). Microsoft Access Database Engine (ACE or Jet) must be installed. The network/database CCTV standard should be PACP (or LACP for lateral data). Run from the UI with a Collection Network open, or via Exchange as for [PACP_import_cctv_surveys](./UIIE-PACP_import_cctv_surveys.rb).

**Note:** `PACP_Ratings.csv` is included in the temporary MDB when present, but summary rating fields on CCTV surveys are not updated automatically from that table. Use **Calculate CCTV Scores/Grades** in InfoAsset Manager, or export/import via [UI-PACP_export-PACP_Ratings](./UI-PACP_export-PACP_Ratings.rb) if ratings must be preserved exactly.

### Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| "A PACP7 template MDB is required" | No template found via browse, CSV folder, or InfoAsset Manager install. Confirm InfoAsset Manager is installed and `PACP_LACPv702.mdb` exists under `Program Files\Autodesk\InfoAsset Manager {version}\`. |
| "InspectionID must be numeric" / import log shows blank date or time | Template missing or CSV columns do not match Access field names. Confirm headers match the PACP7 exchange format. |
| Log says `'Do not import duplicate survey' is selected` but you chose Update | Re-run with **Update existing surveys**; the script passes `update` as a string to the API. |
| Surveys not created after a successful run | Check the import log in the CSV folder. Confirm **Generate IDs from** matches how surveys are identified in the network. |
| Image paths not found | Media CSV paths must be relative to the CSV folder (or absolute). Enable **Import images?** and ensure `PACP_Media_Inspections.csv` is present. |

# [PACP_export](./UIIE-PACP_export.rb)
on.pacp_export(filename,optionsHash)  
    filename – String - filename to export to  
    optionsHash - Hash of parameters for export  

| Parameter | Format | Default | Notes |
|----------|----------|----------|----------|
| Selection Only | Boolean | false | true for selection only, all objects otherwise |
| Images | Boolean | false | If true the images are exported to same location as .mdb |
| Imperial | Boolean | false | true for imperial values (the WSApplication setting for units is ignored) |
| InfoAsset | Integer | nil | If an integer must be between 1 and 10 – corresponds to the dialog setting<sup>1</sup> |
| Format | String | 7 | PACP db version format (must be "6" or "7") |
| LogFile | String | nil | Path of a log file, if nil or blank then nothing is logged to the file |  

<sup>1</sup> Exports the InfoAsset Manager Survey ID field value to the Custom_Field_One / *_Two etc. field in the PACP_Custom_Fields table of the mdb. The User_Text_1 / *_2 - *_10 field values will be exported to the PACP_Custom_Fields.  


## [UI-PACP_export-PACP_Ratings](./UI-PACP_export-PACP_Ratings.rb)
Export CCTV Surveys to PACP7 format and populate the PACP_Ratings table.  
A prompt dialog is used to populate the export filename and other options, like the UI dialog.  
The process does require having the InfoAsset Survey ID value exported to one of the PACP_Custom_Field fields, as this is needed to find the correct InspectionID to create the relationship between the tables within the mdb. The prompt will default to use field one.  
**Note**: This script must be run with the Display Units (Tools > Options > Units) as 'MGD'. At a minimum, 'Length' needs to be in 'ft'.  


# [MACP_import](./UIIE-MACP_import.rb)
on.macp_import(filename,optionsHash)  
    filename – String - filename to import from  
    optionsHash - Hash of parameters for import  

| Parameter                  | Format   | Default   | Notes |
|----------------------------|----------|-----------|-------|
| IDs                        | String   |           | Field(s) to use for IDs. Choices: 'ManholeNumberDateAndTime', 'ManholeNumberAndIndex', 'InspectionID', 'CustomField' |
| CustomField                | Integer  |           | Optional. ID of custom field. Needed if IDs is set to 'CustomField' |
| IfBlankUseInspectionID     | Boolean  | false     | Optional. If blank, use Inspection ID |
| UpdateDuplicates           | Boolean  | false     | Update duplicates. May not be false if IDs is 'ManholeNumberAndIndex' |
| Images                     | Boolean  | false     | Import images |
| LogFile                    | String   |           | Optional. Path of log file. If blank, no log file |
| Flag                       | String   |           | Optional. Flag to use for imported fields |


## [UIIE-MACP_import-Ratings](./UIIE-MACP_import-Ratings.rb)
Import MACP manhole survey data using `MACP_import`, then populate the nine MACP summary rating fields on each matched `cams_manhole_survey` record from the Access database `MACP_Ratings` table.

The `MACP_Ratings` table links to surveys only via `InspectionID`. The script reads `MH_Inspections` for header details (manhole number, inspection date/time) to match each imported network survey to the correct `InspectionID`, then writes the ratings.

### Workflow

1. **MACP survey import** — runs `MACP_import` on the selected MDB.
2. **Import log** — writes a unique log file alongside the MDB and echoes its contents to the Ruby console.
3. **MACP ratings import** — reads `MH_Inspections` and `MACP_Ratings` from the same MDB, matches each inspection to a network survey, and writes rating fields.
4. **Summary** — reports counts of updated surveys, unmatched inspections, and missing ratings rows.

### Prompt options

| Option | Default | Notes |
|--------|---------|-------|
| MDB filename | — | Open-file dialog (`.mdb`) |
| Generate IDs from | ManholeNumberDateAndTime | Dropdown: `ManholeNumberDateAndTime`, `ManholeNumberAndIndex`, `InspectionID`, `CustomField` |
| Custom field (1–10) | 1 | Used when Generate IDs from = `CustomField` |
| If blank use InspectionID? | false | Passed to `MACP_import` |
| Update duplicate surveys? | false | Passed to `MACP_import` |
| Import images? | true | Passed to `MACP_import` |
| Flag for imported fields | BDGR | Passed to `MACP_import` |

### Field mapping

| Access `MACP_Ratings` field | InfoAsset `cams_manhole_survey` field |
|-----------------------------|---------------------------------------|
| STMHRating | macp_struct_rating |
| OMMHRating | macp_oandm_rating |
| OverallMHRating | macp_overall_rating |
| STQuickRating | macp_struct_quick_rating |
| OMQuickRating | macp_oandm_quick_rating |
| MACPQuickRating | macp_overall_quick_rating |
| STMHRatingsIndex | macp_struct_index_rating |
| OMMHRatingsIndex | macp_oandm_index_rating |
| OverallMHRatingsIndex | macp_overall_index_rating |

Grade score columns (`STGradeScore1`–`5`, `OMGradeScore1`–`5`) and `LoFMACP` are not imported. Rating fields absent from the network schema are skipped automatically.

### Matching

Ratings are driven from each `MH_Inspections` row in the MDB. `MACP_Ratings` only stores `InspectionID`, so the script first resolves which network survey corresponds to each `MH_Inspections` record, then copies the ratings.

For each `MH_Inspections` row the script:
1. Tries likely generated `survey.id` values (based on **Generate IDs from**).
2. Falls back to header-field matching on the network survey.

| Generate IDs from | How the network survey is found |
|-------------------|----------------------------------|
| **InspectionID** | `survey.id` equals the `InspectionID` value |
| **ManholeNumberDateAndTime** | `Manhole_Number` + `Inspection_Date` + `Inspection_Time` from `MH_Inspections` matched to the parent node `node_id` (or `employers_job_ref`) and `when_surveyed` / `survey_date` on the survey; also tries common generated-ID string formats |
| **ManholeNumberAndIndex** | `Manhole_Number` matched to node / survey ID prefix, with `survey_index` or ID suffix for duplicates; date/time used to distinguish repeat inspections of the same manhole |
| **CustomField** | Value from `MH_Custom_Fields` matched to the corresponding `user_text_1`–`user_text_10` field on the survey (and `survey.id`) |

Only inspections present in the imported MDB are processed; existing network surveys not in the file are left unchanged.

### Requirements

InfoAsset Manager 2022.1+ (`MACP_import`). Microsoft Access Database Engine (ACE or Jet) must be installed for the ratings step. Run from the UI with a Collection Network open, or via Exchange as for [MACP_import](./UIIE-MACP_import.rb).

A unique import log file is written alongside the MDB (`MACPimport_{mdb_basename}_{YYYYMMDD_HHMMSS}.log`) and its contents are echoed to the Ruby console after the survey import completes.


# [MACP_export](./UIIE-MACP_export.rb)
on.macp_export(filename,optionsHash)  
    filename – String - filename to export to  
    optionsHash - Hash of parameters for export  

| Parameter | Format   | Default  | Notes    |
|-----------|----------|----------|----------|
| Selection Only | Boolean | false | true for selection only, all objects otherwise |
| Images    | Boolean  | false    | If true the images are exported to same location as .mdb |
| Imperial  | Boolean  | false    | true for imperial values (the WSApplication setting for units is ignored) |
| Format    | String   | 7        | MACP db version format (must be "6" or "7") |
| LogFile   | String   | nil      | Path of a log file, if nil or blank then nothing is logged to the file |
