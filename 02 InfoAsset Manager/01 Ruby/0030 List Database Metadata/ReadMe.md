# List Database Metadata

## [UI-ListCurrentNetworkFields.rb](./UI-ListCurrentNetworkFields.rb)
For the current network type, produce an output listing the object table name, field names, including blob fields.  
The output for this script would look similar to:
```
****cams_manhole
	node_id
	node_id_flag
	attachments
		 purpose
		 filename
		 description
		 db_ref
	node_type
	node_type_flag
```

## [UI-ListCurrentNetworkFieldStructure.rb](./UI-ListCurrentNetworkFieldStructure.rb)
For the current network type, produce an output listing the object table & descriptive name, field names, descriptive names, & field type, including blob fields.  
The output for this script would look similar to:
```
****Node, cams_manhole
	ID, node_id, String
	ID Flag, node_id_flag, Flag
	Attachments, attachments, WSStructure
		Purpose, purpose, String
		Original file name, filename, String
		Description, description, String
		Database ref, db_ref, String
	Type, node_type, String
	Type Flag, node_type_flag, Flag
```
