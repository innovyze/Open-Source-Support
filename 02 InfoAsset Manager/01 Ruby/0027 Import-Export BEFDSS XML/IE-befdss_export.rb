begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )

	log='C:\\temp\\log.txt'
	file='C:\\temp\\export.xml'

	#nw.befdss_export(Filename,Type,Images,SelectedSurveysOnly,LogFile)
	nw.befdss_export(file,'DP',true,false,log)

end