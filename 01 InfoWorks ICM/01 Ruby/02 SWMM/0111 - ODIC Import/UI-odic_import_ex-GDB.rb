
begin

nw=WSApplication.current_network

## Set options for import
options=Hash.new											## Type | Default | Notes
options['Error File'] = 'C:\Temp\ImportErrorLog.txt'		## String | blank | Path of error file
#options['Callback Class'] = ImporterClass					## String | blank | Class used for Ruby callback methods (ICM & InfoAsset only)
#options['Set Value Flag'] = 'GDB'							## String | blank | Flag used for fields set from data
#options['Default Value Flag'] = 'GDB'						## String | blank | Flag used for fields set from the default value column
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


## Action the Import using odic_import_ex
nw.odic_import_ex(
'GDB',										# import data format => ESRI GeoDatabase
'C:\Temp\GDBConfig.cfg',					# field mapping config file
options,									# specified options override the default options

## table group
'node',										# import to table name
'NodeClass',								# import from feature class
'C:\Temp\Geodatabase.gdb'					# import from file geodatabase name
)

puts 'Import from GDB completed'