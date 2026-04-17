begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )
	net=nw.open

	dir='C:/source/'	## Folder containing XML files to import

	puts "Data location: #{dir}"

	Dir.glob(dir+'**/*.xml').each do |fname|
		log='log_'+File.basename(fname)+'.txt'
		puts "Importing #{fname}"
		net.befdss_import_cctv(fname,'KT',false,false,1,false,log)
	end

end