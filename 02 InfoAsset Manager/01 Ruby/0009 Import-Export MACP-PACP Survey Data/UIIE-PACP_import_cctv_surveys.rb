## The pacp_import_cctv_surveys method is available in InfoAsset Manager (+Exchange) V2022.1 & later

## pacp_import_cctv_surveys(filename,flag,images,generateIDsFrom,duplicateIDs,importPACP,importLACP,logFile,[markImportedSurveysAsCompleted]
## Filename – String - filename to import from
## Flag – String - flag for imported data
## Images – Boolean – true to import images
## GenarateIDsfrom – Integer – the following values are allowed:
### 1 – Upstream Direction + Date + Time
### 2 – Upstream Direction + Index
### 3 – Inspection ID
### 4 – 13 – Custom (4 = custom field 1, 5 = custom field 2 etc.)
## DuplicateIds – String – ignore / update / overwrite
## ImportPACP – Boolean – true to import PACP data
## ImportLACP – Boolean – true to import LACP data
## LogFile – String – log file path
## MarkImportedSurveysAsCompleted – Boolean – true to mark imported surveys as completed
## It is necessary to run this within a transaction.

if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',1		## Run on Collection Network #1 in IE
	net=dbnet.open
end

net.transaction_begin
net.pacp_import_cctv_surveys('C:\\Temp\\PACP.mdb','BDGR',true,1,true,true,true,'C:\\Temp\\pacp-import.log',true)
net.transaction_commit
