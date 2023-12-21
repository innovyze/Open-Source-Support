class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		file=obj['attachments.purpose'].upcase
		if file=='MSCC XML' || file=='MSCC XML (PROCESSED)'
			retval=true
		else
			retval=false
		end
		return retval
	end
end