## Only export CCTV Survey Defect rows which are *not* Details.Code=BCD or BCE

class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		if !obj['details.code'].nil?
			cd=obj['details.code'].upcase
			if cd!='BCD' && cd!='BCE'
				retval=true
			else
				retval=false
			end
		else
			retval=true
		end
		return retval
	end
end
