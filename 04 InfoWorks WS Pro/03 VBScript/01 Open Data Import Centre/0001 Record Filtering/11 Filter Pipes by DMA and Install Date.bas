Public Sub OnBeginRecordPipe()
	If (Importer.Field("DMAZone") <> "DMA1" And _
		Importer.Field("InstallDate") <= #01/01/2020#) Then
		Importer.WriteRecord = false
	end if
end Sub