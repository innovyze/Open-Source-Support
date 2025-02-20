if WSApplication.ui?
    $net = WSApplication.current_network
else
	$db = WSApplication.open('localhost:40000/IA_DATABASE')
    $nw = $db.model_object_from_type_and_id('Collection Network',4)
    $net = $nw.open
    WSApplication.use_arcgis_desktop_licence()
end

errorFile = 'C:\\Data\\Geodatabase\\ExportErrors.txt'
params = Hash.new
    params['Error File'] = errorFile                    # Default = nil
    #params['Export Selection'] = false                 # Boolean, True to export the selected objects only | Default = FALSE
    #params['Report Mode'] = false                      # Boolean, True to export in 'report mode' | Default = FALSE
    #params['Callback Class'] = Exporter	        	# Default = nil
    #params['Image Folder'] = nil						# Default = nil
    #params['Units Behaviour'] = 'Native'				# Native or User | Default = Native
    #params['Append'] = false							# Boolean, True to enable 'Append to existing data' | Default = FALSE	
    #params['Previous Version'] = 0                 	# Integer, Previous version, if not zero differences are exported | Default = 0
    #params['Don't Update Geometry'] = false			# Boolean | Default = FALSE

configPath = 'C:\\Data\\Geodatabase\\CFGs\\'

gdb = 'C:\\Data\\Geodatabase\\Geodatabase1.gdb'

cfgPath = File.join(configPath,'Node_GDB.cfg')
$net.odec_export_ex( 
    'GDB',          # export data format 
    cfgPath,        # field mapping config file
    params,         # specified options override the default options
    'Node',         # InfoAsset Table to export
    'Manholes2',    # Export to Feature class - unqualified name
    'Node',         # Export to Feature Dataset - fully qualified name
    true,           # true to update, false otherwise. If true the feature class must exist
    nil,            # ArcSDE configuration keyword – nil for Personal / File GeoDatabases, and ignored for updates
    gdb             # Filename (for personal and file GeoDatabases, connection name for SDE)
)
puts 'Exported Nodes'

cfgPath = File.join(configPath,'Pipe_GDB.cfg')
$net.odec_export_ex( 'GDB', cfgPath, params, 'Pipe', 'Pipes2', 'Pipe', true, nil, gdb)
puts 'Exported Pipes'