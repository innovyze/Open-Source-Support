class Exporter

	def Exporter.PipeStatus(obj)
		if obj['status'] == 'AB'			# IF the field 'Status' value is 'AB'
			return '0'						# export the value '0'
		elsif obj['status'] == 'INUSE'
			return '1'
		elsif obj['status'] == 'STANDBY'
			return '2'
		elsif obj['status'] == 'OTHER'
			return '3'
		elsif obj['status'] == nil			# If the value is null
			return '4'						# export '4'
		else								# If the value doesn't match any of the above ifs
			return '5'						# export '5'
		end
	end

	def Exporter.PipeOwner(obj)
		if !obj['owner'].nil?				# If the 'owner' field is not null
			return obj['owner'].upcase		# Export the field 'owner' in UPPERCASE
		end
	end

end
