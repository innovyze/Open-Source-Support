# Export to Snapshot File via snapshot_export_ex method


exportloc = WSApplication.file_dialog(false,'isfc','Collection Network Snapshot File','snapshot',false,false) # Save As dialog for export
if exportloc==nil
	WSApplication.message_box('Export location required','OK','!',nil)
else

nw=WSApplication.current_network

# Create an array for the tables to be exported
export_tables = ["cams_cctv_survey","cams_manhole_survey"]

# Create a hash for the export options override the defaults
exp_options=Hash.new
exp_options['SelectedOnly'] = true									# Boolean | Default = FALSE
exp_options['IncludeImageFiles'] = 	true							# Boolean | Default = FALSE
#exp_options['IncludeGeoPlanPropertiesAndThemes'] = 	false		# Boolean | Default = FALSE
#exp_options['ChangesFromVersion'] = 								# Integer | Default = 0
#exp_options['Tables'] = export_tables								# Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.

# Export
nw.snapshot_export_ex(
	exportloc,			# Export destination file
	exp_options        	# Specified options override the default options
)

end