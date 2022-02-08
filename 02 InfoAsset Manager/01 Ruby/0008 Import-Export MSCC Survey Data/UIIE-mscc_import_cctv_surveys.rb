## on.mscc_import_cctv_surveys(import_file, import_flag, import_images, id_gen, overwrite, log_file)
### import_file – String - filename to import from
### import_flag – String - flag for imported data
### import_images – Boolean – true to import images
### id_gen – Integer – the following values are allowed:
#### 1 – StartNodeRef, Direction, Date and Time
#### 2 – StartNodeRef, Direction and an index for uniqueness
#### 3 – US node ID, Direction, Date and Time
#### 4 – US node ID, Direction and an index for uniqueness
#### 5 – ClientDefined1
#### 6 – ClientDefined2
#### 7 – ClientDefined3
### overwrite – Boolean – To prevent the overwriting of existing surveys in the event of name clashes, set overwite to false
### log_file – String – log file path


if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',2		## Run on Collection Network #2 in IE
	net=dbnet.open
end

net.mscc_import_cctv_surveys('C:\\Temp\\import.xml','BDGR',true,1,false,'C:\\Temp\\mscc-import.log')
