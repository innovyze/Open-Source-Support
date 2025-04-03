## Reorder the CCTV Survey Defect codes if MH and WL are not in the correct order, re-order them.

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
codeIndex=fieldsHash['code']
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
		# go through all rows of the blob except the last
		# if the code in the current row is WL and the next is MH we have to swap them
		changed=false
		(0...allValues.size-1).each do |i|
			if allValues[i][codeIndex]=='WL' &&
			   allValues[i+1][codeIndex]=='MH'
			   # OK, we need to swap them so flag the object as changed and select it
			   changed=true
			   s.selected=true
			   j=0
			   # now swap the rows
			   fields.each do |f|
				   details[i][f]=allValues[i+1][j]
				   details[i+1][f]=allValues[i][j]
				   j+=1
			    end
			end
		end
		if changed
			details.write
			s.write
		end
	end
end
net.transaction_commit