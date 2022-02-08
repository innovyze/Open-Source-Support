## The MACP_import method is available in InfoAsset Manager (+Exchange) V2022.1 & later

if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',2		## Run on Collection Network #2 in IE
	net=dbnet.open
end

myHash=Hash.new
myHash['IDs']='ManholeNumberDateAndTime'		## String, field or fields to use for IDs – choices are: 'ManholeNumberDateAndTime', 'ManholeNumberAndIndex', 'InspectionID', 'CustomField'
#myHash['CustomField']=10						## Integer, ID of custom field. Needed if IDs is set to 'CustomField'
#myHash['IfBlankUseInspectionID']=true			## Boolean, if blank use Inspection ID | Default=false
myHash['UpdateDuplicates']=false				## Boolean, update duplicates. (UpdateDuplicates may not be false if IDs is set to 'ManholeNumberAndIndex') | Default=false
myHash['Images']=true							## Boolean, import images | Default=false
myHash['LogFile']='C:\\Temp\\MACPimport.log'	## String, path of log file (if blank then no log file) | Default=blank (i.e. no log file)
myHash['Flag']='BDGR'							## String, flag to use for imported fields | Default=blank
net.MACP_import "C:\\Temp\\macp.mdb",myHash