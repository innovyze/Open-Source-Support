##Pipe Importation Choice Lists
class Importer
	def Importer.OnEndRecordPipe(obj)

		if obj['OpsStat'] == '0'										#If source field OpStat=0
			obj['status'] = 'AB'										#Set IAM Opertaional_status field as choice 'AB'
		elsif obj['OpsStat'] == '1'
			obj['status'] = 'INUSE'
		elsif obj['OpsStat'] == '2'
			obj['status'] = 'STANDBY'
		elsif obj['OpsStat'] == '3'
			obj['status'] = 'INUSE' and obj['user_text_1'] = 'Temp'		#Set IAM Opertaional_status field as choice 'INUSE' and UT1 as 'TEMP'
		end

		if obj['PipeUseCode'] == '0'				#If source field PipeUseCode=0
			obj['system_type'] = ''					#Set IAM system_type field as ''
		elsif obj['PipeUseCode'] == 'Fo'
			obj['system_type'] = 'F'
		elsif obj['PipeUseCode'] == 'Su'
			obj['system_type'] = 'S'
		elsif obj['PipeUseCode'] == 'Co'
			obj['system_type'] = 'C'
		elsif obj['PipeUseCode'] == 'Ov'
			obj['system_type'] = 'O'
		elsif obj['PipeUseCode'] == 'Culv'
			obj['system_type'] = 'W'
		elsif obj['PipeUseCode'] == 'Subs'
			obj['system_type'] = 'LD'
		elsif obj['PipeUseCode'] == 'Other'
			obj['system_type'] = 'U'
		else										#If none of the above IFs are met
			obj['system_type'] = 'U'				#Set IAM field as 'U'
		end

	end
end