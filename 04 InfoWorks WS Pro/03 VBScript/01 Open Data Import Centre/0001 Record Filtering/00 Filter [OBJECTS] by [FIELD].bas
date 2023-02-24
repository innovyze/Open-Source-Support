REM Filter records based on a string value in a specified field:
Public Sub OnBeginRecord<OBJECT TYPE>()
	If (Importer.Field("<EXTERNAL FIELD NAME>") <> "<STRING VALUE>") Then
		Importer.WriteRecord = false
	end if
end Sub


REM Filter records based on a number value in a specified field:
Public Sub OnBeginRecord<OBJECT TYPE>()
	If (Importer.Field("<EXTERNAL FIELD NAME>") = <NUMBER VALUE>) Then
		Importer.WriteRecord = false
	end if
end Sub


REM Filter records based on datetime values in a specified field:
Public Sub OnBeginRecord<OBJECT TYPE>()
	If (Importer.Field("<EXTERNAL FIELD NAME>") <= #<DATETIME VALUE>#) Then
		Importer.WriteRecord = false
	end if
end Sub