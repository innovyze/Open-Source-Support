## The PACP_export method is available in InfoAsset Manager (+Exchange) V2022.1 & later

if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',1		## Run on Collection Network #1 in IE
	net=dbnet.open
end

export='C:\\Temp\\PACP123.mdb'		## Export to .mdb file

myHash=Hash.new
myHash["Selection Only"]=false				## Boolean, true for selection only, all objects otherwise | Default=false
myHash["Images"]=false						## Boolean, if true the images are exported to same location as .mdb | Default=false
myHash["Imperial"]=true						## Boolean, true for imperial values (the WSApplication setting for units is ignored) | Default=false
myHash["InfoAsset"]=nil						## nil or an Integer, if an integer must be between 1 and 10 – corresponds to the dialog setting | Default=nil
myHash["Format"]="7"						## String, PACP db version format (must be "6" or "7") | Default=7
myHash["LogFile"]='C:\\Temp\\PACP-log.txt'	## String, path of a log file, if nil or blank then nothing is logged to the file | Default=nil

net.PACP_export export,myHash