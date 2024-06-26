## Similar to the IE-odec_export_ex-SQLSERVER.rb script, but this example will only export the differences between a previously exported database commit version (line 62) pulled from a text file (line 38) and the current commit version.

begin

    currtime = Time.now.strftime("%Y-%m-%d %T")
    currdate = Time.now.strftime("%Y%m%d")
    
    puts "#{currtime} Starting Export"
    
    # Open an InfoAsset Manager database
    db = WSApplication.open('localhost:40000/database',false)
    
    # Get the network from the object type and id
    nw = db.model_object_from_type_and_id('Collection Network', 4)
    
    # Define the local export cache
    export_directory = 'C:\\Export\\'
    # Error File location/name
    errorfile = export_directory + currdate + '_ExportErrorLog.txt'
    
    # Open the network
    open_network = nw.open
    
    # Identify network commit version numbers
    current_commit_id = nw.current_commit_id	# Working folder network commit id
    latest_commit_id = nw.latest_commit_id		# Database network commit id
    
    # Update network local copy before exporting
    currtime = Time.now.strftime("%Y-%m-%d %T")
    if(latest_commit_id > current_commit_id) then
        puts "#{currtime} Updating from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
        nw.update
        current_commit_id = nw.current_commit_id
    else
        puts "#{currtime} Network is up to date"
    end
    
    # Read previous export commit ID from file
    previous_commit_file = File.open(export_directory + "Previous_export_commit_id.txt")
    previous_commit_id = previous_commit_file.read
    
    currtime = Time.now.strftime("%Y-%m-%d %T")
    puts "#{currtime} Previous Export Commit ID: #{previous_commit_id}  | Current Commit ID: #{current_commit_id}"
    
    
    # Create a hash for the export options
    options = Hash.new
    options['Use Display Precision'] = true		# default=true
    options['Field Descriptions']    = false	# default=false
    options['Field Names']           = true		# default=true    
    options['Flag Fields']           = false	# default=true
    options['Multiple Files']        = false    	# default=false
    options['User Units']            = false    	# default=false
    options['Units Behaviour']       = 'Native' 	# use native units
    options['Object Types']          = false    	# default=false
    options['Units Text']            = false    	# default=false
    options['Selection Only']        = false    	# export selected objects only?
    options['Create Primary Key']	 = false     	# create a primary key
    options['Error File'] 			 = export_directory + 'Export Error Log.txt' # logs export errors
    options['Coordinate Arrays Format'] = 'Unpacked'  # values='Packed'(default), 'None', 'Unpacked'
    options['Other Arrays Format']      = 'Separate'  # values='Packed'(default), 'None', 'Separate'
    
    options['Previous Version'] = previous_commit_id.to_i
    
    
    # If a newer network version available export
    currtime = Time.now.strftime("%Y-%m-%d %T")
    if previous_commit_id.to_i < current_commit_id.to_i
        then
            puts "#{currtime} Exporting Network"
            
            # export network data to SQL Server format
            nw.odec_export_ex(
            'SQLSERVER', 							#sql server backup
            export_directory+'config.cfg',   	# field mapping config file
            options,                				# export options
    
            # table group
            'node',  			# table to export
            'TABLENAME', 		# export to SQL server table name
            'SERVER',			# export to server
            'INSTANCE',			# export to SQL server instance
            'DATABASE',			# export to SQL server database
            true,				# export update? if true, then the export target must exist
            false,				# integrated security?
            'USERNAME',			# SQL username (or ARGV[1] to take user name from input parameter)
            'PASSWORD',	 		# SQL password (or ARGV[2] to take password from input parameter)
            )
            
            currtime = Time.now.strftime("%Y-%m-%d %T")
            puts "#{currtime} Export Complete"
            # Update previous commit id file
            File.write(previous_commit_file, "#{current_commit_id}") 
                
        else
            puts "#{currtime} Skipping Export - The previous and current commits are the same."
    
    # Export finished
    end
    
    
# Rescue from ifs
rescue Exception => exception
puts "[#{exception.backtrace}] #{exception.to_s}"
    
    
# End of whole process
end