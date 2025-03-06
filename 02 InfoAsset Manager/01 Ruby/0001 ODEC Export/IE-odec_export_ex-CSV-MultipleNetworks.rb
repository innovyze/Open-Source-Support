## Export Mulitple networks

networks=Array.new
networks = [8,6]	## Network IDs for export into the array

db = WSApplication.open('//localhost:40000/Databasename')		## Database to connect to

errorFile = 'C:\\TEMP\\ExportErrors.txt'		## Error file for ODEC errors
params = Hash.new									## Hash for ODEC options
    params['Error File'] = errorFile                    # Default = nil
    #params['Export Selection'] = false                 # Boolean, True to export the selected objects only | Default = FALSE
    #params['Report Mode'] = false                      # Boolean, True to export in 'report mode' | Default = FALSE
    #params['Callback Class'] = Exporter	        	# Default = nil
    #params['Image Folder'] = nil						# Default = nil
    #params['Units Behaviour'] = 'Native'				# Native or User | Default = Native
    #params['Append'] = false							# Boolean, True to enable 'Append to existing data' | Default = FALSE	
    #params['Previous Version'] = 0                 	# Integer, Previous version, if not zero differences are exported | Default = 0
    #params['Don't Update Geometry'] = false			# Boolean | Default = FALSE

configPath = "C:\\TEMP\\"		## Folder containing *.cfg files

networks.each { |n|		## Run through the array of Network IDs
	nw=db.model_object_from_type_and_id('Collection Network',n)		## Define the Network to use
	on=nw.open														## Open the Network
	exportFile="C:\\Temp\\network_"+n.to_s+".csv"	    			## Export filename for this network - unique filename if not appending to the existing file
	on.odec_export_ex('CSV', configPath+'export.cfg', params, 'Pipe', exportFile)		## Run the ODEC export
	
	puts "Exported #{nw.id} #{nw.name}"
	on.close			## Close the Network
}