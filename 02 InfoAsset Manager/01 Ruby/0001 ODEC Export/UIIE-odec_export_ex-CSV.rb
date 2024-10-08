if WSApplication.ui?
    $net = WSApplication.current_network
else
	$db = WSApplication.open('localhost:40000/IA_DATABASE')
    $nw = $db.model_object_from_type_and_id('Collection Network',4)
    $net = $nw.open
    WSApplication.use_arcgis_desktop_licence()
end

errorFile = 'C:\\Data\\CSVExport\\ExportErrors.txt'
params = Hash.new
    params['Error File'] = errorFile                    # Default = nil
    #params['Export Selection'] = false                 # Boolean, True to export the selected objects only | Default = FALSE
    #params['Report Mode'] = false                      # Boolean, True to export in 'report mode' | Default = FALSE
    #params['Callback Class'] = Exporter	        	# Default = nil
    #params['Image Folder'] = nil						# Default = nil
    #params['Units Behaviour'] = 'Native'				# Native or User | Default = Native
    #params['Append'] = false							# Boolean, True to enable 'Append to existing data' | Default = FALSE	
    #params['Previous Version'] = 0                 	# Integer, Previous version, if not zero differences are exported | Default = 0
    #params['WGS84'] = false							# Boolean | Default = FALSE
    #params['Don't Update Geometry'] = false			# Boolean | Default = FALSE

configPath = 'C:\\Data\\CSVExport\\'

exportPath = 'C:\\Data\\CSVExport\\'

$net.odec_export_ex( 
    'CSV',						# export data format 
    configPath+'export.cfg',	# field mapping config file
    params,						# specified options override the default options
    'Node',						# InfoAsset Table to export
    exportPath+'node.csv'		# path of the file to export
)
puts 'Exported Nodes'

$net.odec_export_ex( 'CSV', configPath+'export.cfg', params, 'Pipe', exportPath+'pipe.csv')
puts 'Exported Pipes'