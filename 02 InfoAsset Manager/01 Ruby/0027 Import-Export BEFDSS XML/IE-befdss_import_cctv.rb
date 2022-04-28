begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )

	err='C:\\temp\\error.txt'
	file='C:\\temp\\BEFDSS_01_01_DP.xml'

	#nw.befdss_import_cctv(Filename,Flag,Images,MatchExisting,GenerateIDsFrom,DuplicateIDs,LogFile)
	nw.befdss_import_cctv(file,'KT',true,false,1,false,err)

end