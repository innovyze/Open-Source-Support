Option Explicit

Public Sub OnBeginRecordValve()
	If (Importer.Field("InstallDat") <= #01/01/2020#) Then
		Importer.WriteRecord = false
	end if
end Sub