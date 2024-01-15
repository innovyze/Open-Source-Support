## When exporting a datetime field (year_laid), adjust the value for time zone differences

require 'Date'
class Exporter
	def Exporter.InstalledDate(obj)
		if !obj['year_laid'].nil?						# If the field is not null
			yearlaid=obj['year_laid'] - (1.0/24)		# Convert field value - increase by one hour
			return yearlaid.strftime('%F %T') 			# Export this 
		end
	end
end