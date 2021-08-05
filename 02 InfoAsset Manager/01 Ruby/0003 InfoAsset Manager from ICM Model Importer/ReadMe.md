# Introduction
Over the years there has been one question from my InfoAsset Manager (formerly InfoNet) clients that has consistently popped up; "*How do I import an InfoWorks ICM Model into InfoAsset Manager?*". I must have been asked this a squillion times, and the answer has always been the same.

"*Since models don’t necessarily reflect what is in the ground, through model thinning, simplification or optioneering, InfoAsset Manager does not provide an importer, InfoAsset Manager is about data certainty and confidence.*"


Because of the many import/export options available in both InfoWorks ICM and InfoAsset Manager there has always been the tedious and very long winded method of exporting data from InfoWorks ICM and then importing this into InfoAsset. This meant exporting data to separate tables (CSV, TAB, SHP etc.) from InfoWorks ICM and then importing these individually into InfoAsset via the Open Data Import Centre (ODIC). That is creating a configuration for each table and then going through the myriad clicks in InfoAsset ODIC to import one table at a time, which on top of the tedium, this manual method is also open to error.


So from all this demand (aiming to keep you all happy and avoid you tedium) as well as there now being a method to automate processes in InfoAsset and InfoWorks (Ruby Scripting within the Innovyze Workgroup Client) I have devised/scripted a method that will first export from an InfoWorks ICM Model into an InfoAsset Collection Network.



## Method
**Disclaimer: The RUBY Scripts used may not be the most efficient or comprehensive, they do however do what they say on the tin. They import most of the InfoWorks ICM objects into InfoAsset Manager (NB rivers, open channels and custom shapes are not considered) and the configuration file maps most of the relevant fields. If for any reason there are any that have been omitted or overlooked then contact Support.**

1. There are three files required:
    * *ICM_Model_Importer.cfg* – Import into InfoAsset configuration file.
    * *ICM_Out.rb* – InfoWorks ICM model export ruby script.
    * *InfoAsset_In.rb* – InfoAsset InfoWorks ICM model import ruby script.

2. Create a folder on a local or network drive (what it is named is unimportant), this is an import/export folder where temporary files are written to.

3. Copy the *ICM_Model_Importer.cfg* file into the folder.

4. Copy the script files into the same or a different folder.

5. This next part (applying scripts to user buttons) is optional since scripts can be run from the application interface (InfoWorks ICM & InfoAsset) interface, main menu > Network > Run Ruby script… I am suggesting applying the scripts to 'user custom actions' or 'shared custom actions'.

Read more about these user/shared custom actions in the ICM/InfoAsset HELP File.




For this example I am running InfoAsset Manager and InfoWorks ICM in the one interface together. So both custom user action are in this one InfoWorks ICM interface. Otherwise the **ICM_Out.rb** script needs to be within InfoWorks ICM and **InfoAsset_In.rb** within InfoAsset.

The image below shows how I've configured my custom user actions.
![Ruby Scripts on User or Shared Custom Actions](Image1.jfif)


6. In my example I open both Networks and initially focus on the InfoWorks ICM Model Network.
![InfoWorks ICM & InfoAsset GeoPlans](Image2.jfif)


7. Click on the 'ICM Out' custom action button. The script exports files to the default InfoWorks ICM csv format (manually main menu Network > Export > to CSV Files…). It allows for exporting of a selection. If 'yes' is selected and there is a selection of model objects the those objects only are exported. If there is no selection the export csv files are created with just the field headers (i.e. no objects exported). If 'no' is selected then the entire network is exported. The user is given the option to browser for an export folder. **This should be the folder created in step 2, containing the configuration file.**
![Exported CSV Files](Image3.jfif)


8. With the focus now on the InfoAsset Manager Collection Network, click on the 'InfoAsset In' custom action button. Note the message about the configuration file. Click 'yes' to continue the import (clicking 'no' or 'cancel' terminates the import process). Browse for the import folder containing the CSV files. Hitting OK will start the import process.
![Import into InfoAsset Manager](Image4.jfif)


9. Network imported.
![Network Imported](Image5.jfif)


![Network Imported Detail](Image6.jfif)




## Importing more/different objects from the ICM Model
The script example provided is configured to import in a few specific Model objects into pre-defined InfoAsset Manager object tables, if you wanted to change which IAM table an object is imported into and/or import other ICM objects into IAM you can do this by editing the *InfoAsset_In.rb* script.

Lines 454-463 (with help information on line 452) denote into which InfoAsset Manager object class [<InfoAsset Table Name>], the details from which ICM CSV file [<CSV File Name>] is imported into, using the field mapping config [<Configuration File Name>], with the callback class [<Callback Class>] (set to nil if not required for an object class).

Simply add more lines in the same format below the existing (or edit the existing lines) to add/change what is being imported.
You will also need to amend the existing field mapping config file (ICM_Model_Importer.cfg) or create addition config files for the field mappings as necessary.


### Changing what ICM fields are imported into IAM
If all you wanted to change was what fields from ICM are being imported into IAM, just edit the field mapping config file (ICM_Model_Importer.cfg) by loading it [Load Config] into the Open Data Import Centre in InfoAsset Manager and amend the field mappings as desired, then save the new mappings [Save Config] with the same filename to the relevant location (if you change the filename of the config file, you'll have to update the name in the script).