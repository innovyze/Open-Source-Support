## Select CCTV Surveys where the details.code starts with a 'T' and the details.remarks contains a 'X' at any position.

net=WSApplication.current_network
obj=net.row_object_collection('cams_cctv_survey')

obj.each do |ro|
	if !ro.details.nil? && ro.details.size>0	## if details row is not null
		rb=ro.details
		rb.each do |d|
			if d.code.upcase.match(/^T.*/) && d.remarks.upcase.match(/.*X.*/)		## match where the details.code starts with a 'T' and the details.remarks contains a 'X' at any position.
				ro.selected = true
			end
		end
	end
end
