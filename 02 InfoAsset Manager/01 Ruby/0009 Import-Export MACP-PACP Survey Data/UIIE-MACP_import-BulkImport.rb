begin

	if WSApplication.ui?
		net=WSApplication.current_network		## Uses current open network when run in UI
	else
		db=WSApplication.open
		dbnet=db.model_object_from_type_and_id 'Collection Network',1405		## Run on Collection Network #1 in IE
		net=dbnet.open
	end
	
	# Choose import source parent directory, all subfolders will be included.
	dir = "C:/Temp/junk/"
	
	# State which file type extension(s) are to be used. Separate each by a comma(,).
	ext = 'mdb'
	
	
	# Create a hash for the options of the import method
	options=Hash.new
	options['IDs']='ManholeNumberDateAndTime'		## String, field or fields to use for IDs – choices are: 'ManholeNumberDateAndTime', 'ManholeNumberAndIndex', 'InspectionID', 'CustomField'
	#options['CustomField']=10						## Integer, ID of custom field. Needed if IDs is set to 'CustomField'
	#options['IfBlankUseInspectionID']=true			## Boolean, if blank use Inspection ID | Default=false
	options['UpdateDuplicates']=false				## Boolean, update duplicates. (UpdateDuplicates may not be false if IDs is set to 'ManholeNumberAndIndex') | Default=false
	options['Images']=true							## Boolean, import images | Default=false
	options['Flag']='BDGR'							## String, flag to use for imported fields | Default=blank
	
	puts "Data location: #{dir}"
	
	# Identify files in the directory and sub-directories, run import method on each file
	Dir.glob(dir+'**/*.{'+ext+'}').each do |fname|
		options['LogFile']=File.dirname(WSApplication.script_file)+'\\MACPimport_'+File.basename(fname)+'.log'		## String, path of log file (if blank then no log file) | Default=blank (i.e. no log file) ~ Logfile for each import to script location, filename contains source mdb filename.
		puts "Importing #{fname}"
		net.MACP_import(fname,options)
	end
	
	puts "Import complete."
	
end
	