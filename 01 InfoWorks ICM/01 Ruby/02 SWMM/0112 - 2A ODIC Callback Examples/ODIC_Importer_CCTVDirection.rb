## Set the CCTV Survey Start & Finish Manhole references based on the Direction
class Importer
	def Importer.OnEndRecordCCTVSurvey(obj)

		if obj['Direction'].downcase == 'u'															#If source field Direction=U
			obj['start_manhole'] = obj['DS Manhole'] and obj['finish_manhole'] = obj['US Manhole']	#Set IAM start_manhole/finish_manhole to SOURCE field value 
		elsif obj['Direction'].downcase == 'd'
			obj['start_manhole'] = obj['US Manhole'] and obj['finish_manhole'] = obj['DS Manhole']
		end
		
	end
end