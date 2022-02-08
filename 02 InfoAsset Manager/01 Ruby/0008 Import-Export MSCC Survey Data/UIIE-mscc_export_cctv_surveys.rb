## on.mscc_export_cctv_surveys(export_file, export_images, selection_only, log_file)
### export_file – String - filename to export to
### export_images – Boolean – true to export defect images to same folder as XML.
### selection_only - Boolean - limit the export to selected objects. 
### log_file – String – the location of a text file for errors.


if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',2		## Run on Collection Network #2 in IE
	net=dbnet.open
end

net.mscc_export_cctv_surveys('C:\\Temp\\export.xml',false,false,'C:\\Temp\\mscc-export.log')
