
begin

nw=WSApplication.current_network

## Set options for import
options=Hash.new											## Type | Default | Notes
options['Error File'] = 'C:\Temp\ImportErrorLog.txt'		## String | blank | Path of error file
#options['Callback Class'] = ImporterClass					## String | blank | Class used for Ruby callback methods (ICM & InfoAsset only)
#options['Set Value Flag'] = 'ORA'							## String | blank | Flag used for fields set from data
#options['Default Value Flag'] = 'ORA'						## String | blank | Flag used for fields set from the default value column
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
#options['Import Images'] = false							## Boolean | false | Asset networks only
#options['Group Type'] = false								## Boolean | false | Asset networks only
#options['Group Name'] = false								## Boolean | false | Asset networks only


## Action the Import using odic_import_ex
nw.odic_import_ex(
'ORACLE',									# import data format
'C:\Temp\OracleConfig.cfg',					# field mapping config file
options,									# specified options override the default options

## table group
'node',							# the table name to import into
'T_MANHOLE',					# the source table in Oracle
'orahost/orcl',					# the Oracle connection string (e.g. host/service or //host/service)
nil,							# the owner (schema) of the source table
'oraun',						# user name
'orapw'							# password
)

nw.odic_import_ex(
'ORACLE',									# import data format
'C:\Temp\OracleConfig.cfg',					# field mapping config file
options,									# specified options override the default options

## table group
'pipe',							# the table name to import into
'T_PIPE',						# the source table in Oracle
'orahost/orcl',					# the Oracle connection string (e.g. host/service or //host/service)
nil,							# the owner (schema) of the source table
'oraun',						# user name
'orapw'							# password
)

puts 'Import from ORACLE completed'
