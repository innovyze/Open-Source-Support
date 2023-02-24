Public Sub OnBeginRecordReservoir()
	If (Importer.Field("PressureZone") <> "PZ1" Or _
		Importer.Field("TankVolume") <= 4000) Then
		Importer.WriteRecord = false
	end if
end Sub