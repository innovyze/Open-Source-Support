## Reverse the order of all CCTV Survey Defect Codes

# get the network
net=WSApplication.current_network
# we are changing things so we need a transaction
net.transaction_begin
# we need a list of the names of the fields in the blob
# we have to get the 'details' field by looping through the 
# fields of the CCTV survey
fields=Array.new
fieldsHash=Hash.new
net.table('cams_cctv_survey').fields.each do |f|
	if f.name=='details'
		# OK, we have found it so set up an array of the fields
		n=0
		f.fields.each do |bf|
			fields << bf.name
			fieldsHash[bf.name]=n
			n+=1
		end
		break
	end
end
# now we iterate through all the CCTV surveys
net.row_objects('cams_cctv_survey').each do |s|
	# get the details
	details=s.details
	# phase 1, get and store the values...
	# create an array, for each detail create an array
	# containing all the field values (which we look up by name)
	# then add that to the array of all details i.e. 
	# we end up with an array of arrays containing all the values for that survey
	allValues=Array.new
	if details.size>0
		(0...details.size).each do |i|
			values=Array.new
			fields.each do |f|
				values << details[i][f]
			end
			allValues << values
		end
		# phase 2 
		# put the values back into the blob in the reverse order
		# for each value in the array (which corresponds to a detail)
		# we go through all the fields setting the value for the detail (counting backwards)
		# to that value (notice that we use field names when setting and values in the 
		# array when getting
		(0...allValues.size).each do |i|
			j=0
			puts "survey=#{s.id},index=#{i},code=#{allValues[i][fieldsHash['code']]}"
			fields.each do |f|
				details[allValues.size-i-1][f]=allValues[i][j]
				j+=1
			end
		end
		details.write
		s.write
	end	
end
net.transaction_commit