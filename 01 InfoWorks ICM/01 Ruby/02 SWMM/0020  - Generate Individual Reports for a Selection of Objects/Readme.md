# Introduction
With the release of InfoAsset Manager 2021.2 a new Ruby UI method has been created to allow multiple Reports to be created for each individual item in the current network selection.  So instead of creating a single Report for all 5 CCTV Surveys currently selected, 5 Reports will be generated for each individual Survey.  
The process can only be run from the interface: **Network** > **Run Ruby Script…** - note, an IExchange licence is not required to run scripts from the interface.  

## Supported Report Types
The Reports which are supported to be generated via this method are:  
- Manhole Report  -  ['cams_manhole',nil]  
- Manhole Survey Report  -  ['cams_manhole_survey',nil]  
- CCTV Survey Report  -  ['cams_cctv_survey','nil']  
- CCTV Survey Report (MSCC format)  -  ['cams_cctv_survey','MSCC']  
- CCTV Survey Report (PACP format)  -  ['cams_cctv_survey','PACP']  
- Pipe Clean Report  -  ['cams_pipe_clean',nil]  
- Pipe Repair Report  -  ['cams_pipe_repair',nil]  
- Manhole Repair Report  -  ['cams_manhole_repair',nil]  
- FOG Inspection Report  -  ['cams_fog_inspection',nil]  
All can be produced in either Word (.doc) or HTML (.html) formats.  

## [UI-Reports-CreateIndividualForSelection.rb](./UI-Reports-CreateIndividualForSelection.rb)
Set on line 23 the folder (and filename prefix), replacing `c:\\temp\\Report_` to the folder (and optionally) the filename prefix desired.  
## [UI-Reports-CreateIndividualForSelection_folder.rb](./UI-Reports-CreateIndividualForSelection_folder.rb)
This script is the same as [UI-Reports-CreateIndividualForSelection.rb](./UI-Reports-CreateIndividualForSelection.rb) but instead of needing to enter the export location into the script itself, a prompt dialog will appear to select a folder to save the reports into.

### Customising The Script
To change/add in report types to export, change line 6 (tables=) to the type(s) as detailed in the supported reports section.  
Each individual report type should be separated by a comma, and within an overarching square bracket pair – as shown in the commented-out section of the syntax after the double-hash.  
To generate reports in HTML format, change "'.doc'" on line 24 or uncomment line 25 - so the file-type suffix is "'.html'".  

## The Ruby Method
net.generate_report(Table_Name,Suffix,Title,Output_File_Name)  
1. Table name  
2. Suffix (usually nil but can be MSCC or PACP for CCTV surveys)  
3. Title (this is the one that usually says 'selection' or whatever on the reports, but you can say what you like)  
4. Output file name (.doc or .html - it uses the suffix to decide which report to do)  
The report is always for the selected object.  


### Version Compatibility
The generate_report method is available in InfoAsset Manager 2021.2 and later.  