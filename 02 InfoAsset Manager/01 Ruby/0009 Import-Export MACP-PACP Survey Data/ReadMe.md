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
| InfoAsset | Integer | nil | If an integer must be between 1 and 10 – corresponds to the dialog setting |
| Format | String | 7 | PACP db version format (must be "6" or "7") |
| LogFile | String | nil | Path of a log file, if nil or blank then nothing is logged to the file |


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
