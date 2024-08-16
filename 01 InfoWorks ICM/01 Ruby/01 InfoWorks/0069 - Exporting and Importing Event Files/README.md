# Exporting and Importing Wastewater Files and Event Files
This ruby script utilizes the ".export" method of a model object to export data from the model object to an Infoworks event file. It then employs the ".import_new_model_object" method to import the event file into the database. Users can adopt this workflow to modify any event file. This modification can be achieved by exporting the event file to a CSV or Infoworks format file, and subsequently editing the exported file using Ruby or any third-party program. Once editing is complete, the user can import the file back into the ICM database.

Refer below help Documentation for more details

[Help | export](https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=Innovyze_Exchange_Classes_ICM_wsmodelobject_html#export)

[Help | import_new_model_object](https://help.autodesk.com/view/IWICMS/2025/ENU/?guid=Innovyze_Exchange_Classes_ICM_wsmodelobject_html#import_new_model_object)

![Gif 1](gif001.gif)


