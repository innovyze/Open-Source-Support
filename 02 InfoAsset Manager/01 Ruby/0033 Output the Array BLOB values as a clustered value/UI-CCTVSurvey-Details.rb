net=WSApplication.current_network
ro=net.row_objects('cams_cctv_survey')
ro.each do |s|
	if !s.details.nil? && s.details.size>0              ## If the details table has a value
		jp=s.details
		join=Array.new             ## Create an array for the values
		jp.each do |j|           ## Run on the details table
			if !j.structural_score.nil? && j.structural_score>0          ## If the structural_score field value is not null or zero
				join<<j.distance.to_s+' '+j.code+' '+j.remarks             ## Insert the field values into the array
			end
		end
		unless join.empty?              ## If the array is not empty
			puts "#{s.id} :	#{join.join('; ')}"             ## Output the values with the object id, each value in the array is seperated by a semicolon
		end
	end
end