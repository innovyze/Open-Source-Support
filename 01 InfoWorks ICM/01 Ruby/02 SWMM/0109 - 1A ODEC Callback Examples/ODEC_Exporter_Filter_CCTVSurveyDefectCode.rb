## Only export CCTV Survey Defect rows which have Details.Code=B

class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		cd=obj['details.code'].upcase
		if cd=='B'
			retval=true
		else
			retval=false
		end
		return retval
	end
end

