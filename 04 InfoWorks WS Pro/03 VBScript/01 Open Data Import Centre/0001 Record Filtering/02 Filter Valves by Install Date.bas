Option Explicit

Public Sub OnBeginRecordValve()
	If (Importer.Field("InstallDate") <= #01/01/2020#) Then
		Importer.WriteRecord = false
	end if
end Sub