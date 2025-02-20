
begin

## Open a database
db = WSApplication.open('localhost:40000/database',false)

## Get the network from the object type and id
nw = db.model_object_from_type_and_id('Collection Network',848) 

## Reserve the network to prevent other users from editing it
nw.reserve

## Open the network
net = nw.open

## Update the network
nw.update

puts 'Start import'


## Set options for import
options=Hash.new											## Type | Default | Notes
options['Error File'] = 'C:\Temp\ImportErrorLog.txt'		## String | blank | Path of error file
#options['Callback Class'] = ImporterClass					## String | blank | Class used for Ruby callback methods (ICM & InfoAsset only)
#options['Set Value Flag'] = 'SQL'							## String | blank | Flag used for fields set from data
#options['Default Value Flag'] = 'SQL'						## String | blank | Flag used for fields set from the default value column
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
'SQLSERVER',								# import data format
'C:\Temp\SQLConfig.cfg',					# field mapping config file
options,									# specified options override the default options

## table group
'node',							# the table name to import into
'T_MANHOLE',					# the table name in SQL Server
'sqlname',						# the server name
nil,							# the SQL Server instance name
'serverdb',						# the database name
false,							# integrated security (Boolean – true or false, true meaning integrated security)
'sqlun',						# user name
'sqlpw'							# password
)

nw.odic_import_ex(
'SQLSERVER',								# import data format
'C:\Temp\SQLConfig.cfg',					# field mapping config file
options,									# specified options override the default options

## table group
'pipe',							# the table name to import into
'T_PIPE',						# the table name in SQL Server
'sqlname',						# the SQL server name
nil,							# the SQL Server instance name
'serverdb',						# the database name
false,							# integrated security (Boolean – true or false, true meaning integrated security)
'sqlun',						# user name
'sqlpw'							# password
)

puts 'Import from SQLSERVER completed'

## Commit changes and unreserve the network
nw.commit('Date imported from SQLSERVER')
nw.unreserve
puts 'Committed'



## handle exceptions
rescue Exception => exception
puts "#{exception.to_s} (#{exception.backtrace})"

ensure

## roll back uncommitted changes if script fails
#nw.revert
#puts "Exception occurred - NETWORK REVERTED"

## unreserve the network on error, only if it has been reserved
nw.unreserve if nw

end