## Only export CCTV Survey Defect rows which have Details.detail_image reference

class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		cd=obj['details.detail_image']
		if cd != nil && cd != 0
			retval=true
		else
			retval=false
		end
		return retval
	end
end

