## Only export CCTV Survey Defect rows which have Details.detail_image reference and are for Details.Code='B' / 'H' / 'C'

class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		ci=obj['details.detail_image']
		if ci != nil && ci != 0
			cd=obj['details.code'].upcase
			if cd=='B' || cd=='H' || cd=='C'
				retval=true
			else
				retval=false
			end
		else
			retval=false
		end
		return retval
	end
end

