net = WSApplication.current_network
config = File.dirname(WSApplication.script_file)+'\Config.cfg'	# Config File name - within same directory of this script
exportloc = File.dirname(WSApplication.script_file) # Change this to a different folder for the export location if required
address1 = File.dirname(WSApplication.script_file)+'\CrossSectionLines.csv' # CSV file containing the object IDs
address2 = File.dirname(WSApplication.script_file)+'\CrossSectionData.csv'  # CSV file containing the section data

## Set options for import
#options=Hash.new											## Type | Default | Notes
#options['Subtable'] = 'Cross section line : Section Data'		## String | blank | Path of error file
#options['Callback Class'] = ImporterClass					## String | blank | Class used for Ruby callback methods (ICM & InfoAsset only)
#options['Set Value Flag'] = 'CSV'							## String | blank | Flag used for fields set from data
#options['Default Value Flag'] = 'CSV'						## String | blank | Flag used for fields set from the default value column
#options['Image Folder'] = 'C:\Temp\'						## String | blank | Folder to import images from (Asset networks only)
#options['Duplication Behaviour'] = 'Merge'					## String | Merge | One of Duplication Behaviour:'Overwrite','Merge','Ignore'
#options['Units Behaviour'] = 'Native'						## String | Native | One of 'Native','User','Custom'
#options['Update Based On Asset ID'] = false				## Boolean | false
#options['Update Only'] = false								## Boolean | false
#options['Delete Missing Objects'] = false					## Boolean | false
#options['Allow Multiple Asset IDs'] = false				## Boolean | false
#options['Update Links From Points'] = false				## Boolean | false
#options['Blob Merge'] = false								## Boolean | false
#options['Use Network Naming Conventions'] = false			## Boolean | false
#options['Import images'] = false							## Boolean | false | Asset networks only
#options['Group Type'] = false								## Boolean | false | Asset networks only
#options['Group Name'] = false								## Boolean | false | Asset networks only

net.odic_import_ex(
'CSV',										
config,					
nil,									
'CrossSectionLine',										
address1
)
# this creates a new 'cross section line' object into which the section data can be imported
puts 'Cross section object import completed'
    
net.odic_import_ex(
'CSV',										
config,					
nil,									
'CrossSectionLineSectionData',										
address2
)
# this imports the cross section data into the newly created cross section line objects
puts 'Cross section data import completed'

