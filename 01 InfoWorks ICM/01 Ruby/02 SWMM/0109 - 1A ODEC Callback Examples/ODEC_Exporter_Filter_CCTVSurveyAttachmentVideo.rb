class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		cd=obj['attachments.purpose'].upcase
		if cd=='CCTV VIDEO'
			retval=true
		else
			retval=false
		end
		return retval
	end
end