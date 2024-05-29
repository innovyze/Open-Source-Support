# INTERFACE SCRIPT
# Export CCTV Surveys & Manhole Surveys to GIS file via GIS_export method

cn=WSApplication.current_network

# Get the name of the network
network_name = cn.network_model_object.name

# Create an array for the tables to be exported
export_tables = ["hw_node","hw_conduit","hw_subcatchment"]

# Create a hash for the export options override the defaults
exp_options=Hash.new
exp_options['ExportFlags'] = false				# Boolean | Default = FALSE
exp_options['SkipEmptyTables'] = false			# Boolean | Default = FALSE
exp_options['Tables'] = export_tables			# Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.
#exp_options['Feature Dataset'] = 				# String | for GeoDatabases, the name of the feature dataset. Default=nil
#exp_options['UseArcGISCompatibility'] = false	# Boolean | Default = FALSE

# Prompt the user to pick a folder 
val = WSApplication.prompt "Folder for the SHP File", [
    ['Pick the Folder','String',nil,nil,'FOLDER','Folder']], false
folder_path = val[0]

# Export
cn.GIS_export(
    'SHP',							            # Format: SHP,TAB,MIF,GDB
    exp_options,				            	# Specified options override the default options
    "#{folder_path}/"		                   # Export destination folder & filename prefix
)