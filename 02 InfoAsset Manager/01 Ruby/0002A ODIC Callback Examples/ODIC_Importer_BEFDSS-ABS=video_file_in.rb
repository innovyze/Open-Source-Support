#If running IAM in French, comment-out line 3 by removing the '#' and comment-out line 4. // Si vous exécutez IAM en français, commentez la ligne 3 en supprimant le '#' et commentez la ligne 4.
class Importer
	def Importer.OnEndRecordCCTVSurvey(obj)
	#def Importer.OnEndRecordITV(obj)
		obj['video_file_in']=obj['ABS']
		obj['id']=obj['FULL_POSITIONING_FINDING/AAB']+'_'+obj['AAK']+'_'+obj['ABF'][0,4]+obj['ABF'][5,2]+obj['ABF'][8,2]+'_'+obj['ABG'][0,2]+obj['ABG'][3,2]
	end
end