net=WSApplication.current_network 	
puts 'running ruby for SWMM Networks'												# selects current active network
net.row_objects('sw_subcatchment').each do |subcatchment|							# loops through all subcatchment objects
    if subcatchment.selected?														# 'if' the catchment is selected
		net.transaction_begin														# start a 'transaction'
    	new_object = net.new_row_object('sw_subcatchment')							# create a new subcatchment object
    	new_object['subcatchment_id'] = subcatchment['subcatchment_id'] + "_copy" 	# name it with '_copy' suffix
    	new_object.table_info.fields.each do |field|								# for each column
    		if field.name != 'subcatchment_id'										# 'if' it's not the subcatchment name
    			new_object[field.name] = subcatchment[field.name]					# copy across the field value
    		end																		# end of 'if' condition 
    	end																			# end of column loop
    	new_object.write															# write changes
		net.transaction_commit												    	# end the 'transaction'
    end																				# end of 'if' condition
end																					# end of loop
puts 'ending ruby for SWMM Networks'	