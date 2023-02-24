Option Explicit

Public Sub OnBeginRecordPipe()
	If (Importer.Field("DrawingNo") <> "D-1234") Then
		Importer.WriteRecord = false
	end if
end Sub