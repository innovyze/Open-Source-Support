## Only export Pipes where the system_type field is as set below

class Exporter
	def Exporter.onFilterRecordPipe(obj)
		if obj['system_type']=='C'
			return true
		end
	end
end