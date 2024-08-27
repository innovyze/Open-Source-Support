Public Sub OnBeginRecordHydrant()
	If (Importer.Field("DMAZone") <> "DMA123") Then
		Importer.WriteRecord = false
	end if
end Sub