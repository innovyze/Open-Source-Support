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
