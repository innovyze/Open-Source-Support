# Ruby Script ODEC Callback Classes in InfoAsset Manager

This directory contains examples of Open Data Export Centre Callback Class syntax.  
They can be either utilised either via the IAM UI or embedded within IAM Exchange scripts. 


Further guidance can be found in the articles on our [Support Portal](https://innovyze.force.com/support/s/) [Knowledgebase](https://innovyze.force.com/support/s/topic/0TO0P000000IdBQWA0):  
[Ruby Scripting: Changing values on export using a callback class](https://innovyze.force.com/support/s/article/Ruby-Scripting-Changing-values-on-export-using-a-callback-class)  
[Ruby Scripting: Filtering objects on export using a callback class](https://innovyze.force.com/support/s/article/Ruby-Scripting-Filtering-objects-on-export-using-a-callback-class)  


## ODEC Callback Classes in the UI
Simply save the Callback class syntax in a file with `.rb` as the file type suffix, then to action the script select the file from the Ruby Script parameter on the ODEC dialog.  
![Set the Ruby 'Script File' location, if you change the script's contents when already loaded - click Reload.](image01.jfif)
### ODEC Converter Callback classes
Once the Script File has been set to the .rb file, if the callback class is to convert/calculate a value for export, you will need to set the Field Mappings by selecting the Field Type of 'Script' and choose the Exporter Class Definition name as the Internal Field.  
![Configure the Field Mappings to use the Script contents.](image02.jfif)

## ODEC Callback Classes in IExchange scripts
The same callback class can be utilised by an export script when using the odec_export_ex method for export.  
Simply insert the same syntax defining the callback class and its methods before the export syntax and save the field mappings with the Script Field Types into the specified config file.  
Then as part of the export parameters hash, specify the Class name against a parameter for 'Callback class'.  For example, to use the class as defined above, we would use:  
`options['Callback Class'] = Exporter`  
Then run the export script as normal and the calculated fields will show in the destination.



