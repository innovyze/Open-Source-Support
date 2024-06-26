## Set the IAM field video_file_in to be the 'ABS' field in the BEFDSS XML file - this is workable once the primary data has been imported from the XML using the standard dialog with the Survey ID option of "AAB, AAK, ABF, ABG", this callback is then used in the ODIC to import just the video_file_in field (just the ID needs to be set in the Field Mapping Configuration).
### If running IAM in French, uncomment line 5 by removing the '#' and comment-out line 4.  
### Si vous exécutez IAM en Français, décommentez la ligne 5 en supprimant le '#' et en commentant la ligne 4.  
class Importer
	def Importer.OnEndRecordCCTVSurvey(obj)
	#def Importer.OnEndRecordITV(obj)
		obj['video_file_in']=obj['ABS']
		obj['id']=obj['FULL_POSITIONING_FINDING/AAB']+'_'+obj['AAK']+'_'+obj['ABF'][0,4]+obj['ABF'][5,2]+obj['ABF'][8,2]+'_'+obj['ABG'][0,2]+obj['ABG'][3,2]
	end
end