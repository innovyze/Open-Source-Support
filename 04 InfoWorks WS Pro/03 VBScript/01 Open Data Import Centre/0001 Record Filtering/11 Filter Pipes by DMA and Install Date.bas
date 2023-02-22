Option Explicit

Public Sub OnBeginRecordPipe()
	If (Importer.Field("DMAZone") <> "DMA1" And _
        Importer.Field("InstallDat") <= #01/01/2020#) Then
		Importer.WriteRecord = false
	end if
end Sub