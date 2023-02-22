Option Explicit

Public Sub OnBeginRecordHydrant()
	Dim DMA
	DMA = Importer.Field("DMAZone")
	If (DMA <> "EOH5P") Then
		Importer.WriteRecord = false
	end if
end Sub