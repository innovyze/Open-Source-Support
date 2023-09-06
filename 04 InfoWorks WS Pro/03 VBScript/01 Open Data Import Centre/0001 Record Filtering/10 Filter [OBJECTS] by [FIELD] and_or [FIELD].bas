REM Filter records based on matching all conditions from multiple fields (this AND that AND that are true)
Public Sub OnBeginRecord[OBJECT TYPE]()
	If (Importer.Field("[EXTERNAL FIELD NAME]") <> "[STRING VALUE]" And _
		Importer.Field("[EXTERNAL FIELD NAME]") <= [NUMBER VALUE] And _
		Importer.Field("[EXTERNAL FIELD NAME]") >= #[DATETIME VALUE]#) Then
		Importer.WriteRecord = false
	end if
end Sub

REM Filter records based on matching one condition from multiple fields (this OR that OR that is true)
Public Sub OnBeginRecord[OBJECT TYPE]()
	If (Importer.Field("[EXTERNAL FIELD NAME]") <> "[STRING VALUE]" Or _
		Importer.Field("[EXTERNAL FIELD NAME]") <= [NUMBER VALUE] Or _
		Importer.Field("[EXTERNAL FIELD NAME]") >= #[DATETIME VALUE]#) Then
		Importer.WriteRecord = false
	end if
end Sub