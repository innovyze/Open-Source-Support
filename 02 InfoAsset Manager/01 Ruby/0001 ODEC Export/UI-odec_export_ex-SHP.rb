# INTERFACE SCRIPT
# Export Nodes and Pipes to SHP File via odec_export_ex method

nw=WSApplication.current_network

config = File.dirname(WSApplication.script_file)+'\odec_export_ex-SHP.cfg'	# Config File name - within same directoyr of this script
exportloc = File.dirname(WSApplication.script_file) # Change this to a different folder for the export location if required

options=Hash.new
#options['Callback Class'] = nil					# Default = nil
#options['Error File'] = File.dirname(WSApplication.script_file)+'\ErrorLog.txt'		# Default = nil
#options['Image Folder'] = nil					# Default = nil
#options['Units Behaviour'] = 'Native'			# Native or User | Default = Native
#options['Report Mode'] = false					# Boolean, True to export in 'report mode' | Default = FALSE
#options['Append'] = false						# Boolean, True to enable 'Append to existing data' | Default = FALSE
#options['Export Selection'] = false			# Boolean, True to export the selected objects only | Default = FALSE
#options['Previous Version'] = false			# Integer, Previous version, if not zero differences are exportedy | Default = 0
#options['WGS84'] = false						# Boolean | Default = FALSE
#options['Don’t Update Geometry'] = false		# Boolean | Default = FALSE


nw.odec_export_ex(
	'SHP',                      				# Export data format = SHP File
	config,         							# Field mapping config file
	options,                   					# Specified options override the default options
	'node',                     				# InfoAsset table to export
	exportloc+'\node.SHP',							# Export destination file
)

nw.odec_export_ex(
	'SHP',                      				# Export data format = SHP File
	config,         							# Field mapping config file
	options,                   					# Specified options override the default options
	'pipe',                     				# InfoAsset table to export
	exportloc+'\pipe.SHP',							# Export destination file
)