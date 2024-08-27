Public Sub OnBeginRecordPipe()
	If (Importer.Field("DrawingNo") <> 1234) Then
		Importer.WriteRecord = false
	end if
end Sub