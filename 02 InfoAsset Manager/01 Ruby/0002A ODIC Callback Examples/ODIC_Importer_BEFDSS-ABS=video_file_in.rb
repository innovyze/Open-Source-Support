#If running IAM in French, uncomment line 4 by removing the '#' and comment-out line 3. // Si vous exécutez IAM en Français, décommentez la ligne 4 en supprimant le '#' et en commentant la ligne 3.
class Importer
	def Importer.OnEndRecordCCTVSurvey(obj)
	#def Importer.OnEndRecordITV(obj)
		obj['video_file_in']=obj['ABS']
		obj['id']=obj['FULL_POSITIONING_FINDING/AAB']+'_'+obj['AAK']+'_'+obj['ABF'][0,4]+obj['ABF'][5,2]+obj['ABF'][8,2]+'_'+obj['ABG'][0,2]+obj['ABG'][3,2]
	end
end