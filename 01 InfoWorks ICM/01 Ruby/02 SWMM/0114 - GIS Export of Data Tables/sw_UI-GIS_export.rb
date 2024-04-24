nw=WSApplication.current_network

# Create an array for the tables to be exported
export_tables = ["sw_node","sw_conduit","sw_subcatchment"]

# Create a hash for the export options override the defaults
exp_options=Hash.new
exp_options['ExportFlags'] = false				# Boolean | Default = FALSE
exp_options['SkipEmptyTables'] = false			# Boolean | Default = FALSE
exp_options['Tables'] = export_tables			# Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.
#exp_options['Feature Dataset'] = 				# String | for GeoDatabases, the name of the feature dataset. Default=nil
#exp_options['UseArcGISCompatibility'] = false	# Boolean | Default = FALSE

# Export
nw.GIS_export(
	'SHP',							        # Format: SHP,TAB,MIF,GDB
	exp_options,				            # Specified options override the default options
	'C:\Temp\ICM_Ruby_Network\InfoSWMM'		# Export destination folder & filename prefix
)