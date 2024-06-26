## Only export CCTV Survey Defect rows which have Details.detail_image reference and have a Structural Score >= 4.

class Exporter
	def Exporter.onFilterRecordCCTVSurvey(obj)
		return true
	end
	def Exporter.onFilterBlobCCTVSurvey(obj,n,m)
		ci=obj['details.detail_image']
		if ci != nil && ci != 0
			cd=obj['details.structural_score']
			if cd>=4
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