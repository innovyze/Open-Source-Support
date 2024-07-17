#Get database object
db=WSApplication.open

#Get the waste water model object
ww_mo= db.model_object_from_type_and_id("Waste water",2)

#Get the parent folder of the waste water model object which will be used to create a new model object
parent_folder=db.model_object_from_type_and_id(ww_mo.parent_type,ww_mo.parent_id)

# The path variable stores the file path of the CSV file to be exported.
path = 'C:\Users\lakeshc\OneDrive - Autodesk\002_ICM\Ruby\004 Exporting Event Objects\WW_export.wwg'
# The export method is used to export the event object to a CSV file.
ww_mo.export path , ''

# Import the exported CSV file to create a new model object
parent_folder.import_new_model_object('Waste water', 'Imported Waste Water File', '', path)