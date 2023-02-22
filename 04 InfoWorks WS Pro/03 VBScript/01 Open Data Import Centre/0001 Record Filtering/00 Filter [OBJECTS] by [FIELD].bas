REM Filter records based on a value in a specified field:
Public Sub OnBeginRecord<OBJECT TYPE>()
	If (Importer.Field("<EXTERNAL FIELD NAME") <> "<VALUE>") Then
		Importer.WriteRecord = false
	end if
end Sub


REM Filter records based on a number value in a specified field:
Public Sub OnBeginRecord<OBJECT TYPE>()
	If (Importer.Field("<EXTERNAL FIELD NAME") = <NUMBER>) Then
		Importer.WriteRecord = false
	end if
end Sub


REM Filter records based on datetime values in a specified field:
Public Sub OnBeginRecord<OBJECT TYPE>()
	If (Importer.Field("<EXTERNAL FIELD NAME") <= #<DATETIME>#) Then
		Importer.WriteRecord = false
	end if
end Sub