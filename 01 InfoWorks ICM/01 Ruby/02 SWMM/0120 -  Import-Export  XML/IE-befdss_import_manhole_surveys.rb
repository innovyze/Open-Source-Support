begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )

	log='C:\\temp\\log.txt'
	file='C:\\temp\\BEFDSS_01_01_M.xml'

	#nw.befdss_import_manhole_surveys(Filename,Flag,false,MatchExisting,GenerateIDsFrom,false,LogFile)
	nw.befdss_import_manhole_surveys(file,'KT',false,false,1,false,log)

end