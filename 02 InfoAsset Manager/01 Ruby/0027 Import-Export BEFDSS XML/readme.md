# Importing BEFDSS XML Survey Data  

## Importing BEFDSS XML CCTV Survey Data  
### [befdss_import_cctv](IE-befdss_import_cctv.rb) (InfoAsset Exchange only)

`on.befdss_import_cctv(Filename,Flag,Images,MatchExisting,GenerateIDsFrom,DuplicateIDs,LogFile)`  

e.g.  
`on.befdss_import_cctv('D:\\import.xml','IM',true,false,1,false,'D:\\log.txt')`  
  
#### Parameters:
**Filename** (string) - The XML filename & path.  
**Flag** (string) - Either *nil* or the string specifies the data flag for imported fields.  
**Images** (boolean) - *true* to import images from an absolute path in the PHOTO_REF field of the BEFDSS XML file, or a relative path if the image is in the folder containing the XML file, or a sub-folder.   
**MatchExisting** (boolean) - *true* = Update existing records by matching node 1 reference (AAD), node 2 reference (AAF) and employers job reference (ABJ). Create survey if match not found.  
**GenerateIDsFrom** (integer) - Uses the following values (these correspond to the user interface options in the help):  
 *1* - StartNodeRef (AAB), Direction (AAK), Date (ABF) and Time (ABG)  
 *2* - StartNodeRef (AAB), Direction (AAK), and an index if needed  
 *3* - PIPELINE_IDNR  
**DuplicateIDs** (boolean) - *false* = "Do not import duplicate survey", *true* = "Overwrite existing survey".  
**LogFile** (string) - Either *nil* or filename & path to .txt log file, the log will be created or overwritten if one exists.  


## Importing BEFDSS XML Manhole Survey Data  
### [befdss_import_manhole_surveys](IE-befdss_import_manhole_surveys.rb) (InfoAsset Exchange only)

`on.befdss_import_manhole_surveys(Filename,Flag,false,MatchExisting,1,false,LogFile)`  

e.g.  
`on.befdss_import_manhole_surveys('D:\\import.xml','IM',false,false,1,false,'D:\\log.txt')`  
  
#### Parameters:
**Filename** (string) - The XML filename & path.  
**Flag** (string) - Either *nil* or the string specifies the data flag for imported fields.  
**P3** (boolean) - not used.  
**MatchExisting** (boolean) - *true* = Match to existing records by node reference (CAA) and employers job reference (CBJ / IAM `customer` field) option to merge survey data into existing surveys. Create survey if match not found.  
**GenerateIDsFrom** (integer) - Must be *1* = Node reference (CAA) and an index.  
**P6** (boolean) - not used.   
**LogFile** (string) - Either *nil* or filename & path to .txt log file, the log will be created or overwritten if one exists.  
