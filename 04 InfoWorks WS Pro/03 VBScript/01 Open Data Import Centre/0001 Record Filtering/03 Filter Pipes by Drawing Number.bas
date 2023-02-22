Option Explicit

Public Sub OnBeginRecordPipe()
	Dim DrawNo
	DrawNo = Importer.Field("DrawingNo")
	If (DrawNo <> "W9443-11") Then
		Importer.WriteRecord = false
	end if
end Sub