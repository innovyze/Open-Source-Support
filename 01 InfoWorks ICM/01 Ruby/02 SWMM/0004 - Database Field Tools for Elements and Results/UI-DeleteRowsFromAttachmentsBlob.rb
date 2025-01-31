## Remove certain data rows from the Attachments blob of Manhole Survey objects.

net=WSApplication.current_network
net.transaction_begin
fields=Array.new
fieldsHash=Hash.new
net.table('cams_manhole_survey').fields.each do |f|
	if f.name=='attachments'
		n=0
		f.fields.each do |bf|
			fields << bf.name
			fieldsHash[bf.name]=n
			n+=1
		end
		break
	end
end
net.row_objects_selection('cams_manhole_survey').each do |s|
	attachments=s.attachments
	$allValues=Array.new
	if attachments.size>0
		(0...attachments.size).each do |i|
			values=Array.new
			#IF Attahcments.Description is not = '123' write into the array
			if attachments[i].description!='123'
			fields.each do |f|
				values << attachments[i][f]
				end
			$allValues << values
			end
		end
		#Alter the Attachments blob size 
		attachments.length = $allValues.length
		(0...$allValues.size).each do |i|
			j=0
			fields.each do |f|
				attachments[i][f]=$allValues[i][j]
				j+=1
			end
		end
		attachments.write
		s.write
	end	
end
net.transaction_commit