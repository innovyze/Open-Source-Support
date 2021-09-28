## Only export CCTV Surveys which have Current=true

class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		if obj['current']==true
			return true
		end
	end
end
