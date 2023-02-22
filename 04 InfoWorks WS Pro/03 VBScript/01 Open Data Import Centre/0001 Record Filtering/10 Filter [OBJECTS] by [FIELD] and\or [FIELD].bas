Option Explicit

Public Sub OnBeginRecordValve()
	If (Importer.Field("DMAZone") <> "DMA1" And _
        Importer.Field("InstallDat") <= #01/01/2020#) Then
		Importer.WriteRecord = false
	end if
end Sub

Public Sub OnBeginRecordValve()
	If (Importer.Field("DMAZone") <> "DMA1" Or _
        Importer.Field("InstallDat") <= #01/01/2020#) Then
		Importer.WriteRecord = false
	end if
end Sub