## [UI-ImportINTERLISManholeSurveyDetails.rb](./UI-ImportINTERLISManholeSurveyDetails.rb)  
This script was based on a client support query, where they have INTERLIS XML Manhole Survey data to import into surveys where the header details have been imported.  
  
The script reads the XML to insert 'VSA_KEK_2020_LV95.KEK.Normschachtschaden' elements into a hash of arrays with the REF as key value - this REF value should be the SURVEY ID within InfoAsset Manager, taken from the TID element of the 'VSA_KEK_2020_LV95.KEK.Untersuchung' (Survey Header) section.  
It also reads the 'VSA_KEK_2020_LV95.KEK.Datei' section where the 'art' element is "Foto" (line 24) and "digitales_Video" (line 26) to match these based on the 'Objekt' element to match the observation to import in the image filenames and video filenames respectively.  
  
When running the script, an Open XML File dialog will show to select the XML file to import.  
This will update existing surveys within the Manhole Survey table with the REF values on the details the Survevy ID within the database. The data is imported into the details table, appending onto any existing data.  
Observation values imported are sorted (line 111) on the 'distanz' then 'videozaehlerstand' values.  
The "digitales_Video" value is also set into the 'video_file_in' field (line 135) on the survey.  

### Conversions processed by the script
Line 120: The 'streckenschaden' value has "A" and "B" converted to "S" and "F" respectively when setting the 'cd' field.  
Line 121: The 'verbindung' value is converted from "ja" to true to import into the Boolean field 'joint'.  
Line 129/130: The 'schadenlageanfang'/'schadenlageende' values of "12" are changed to "0" for the 'clock_at'/'clock_to' fields respectively.  