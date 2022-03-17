# Export to CSV file(s) via csv_export method

if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',2		## Run on Collection Network #2 in IE
	net=dbnet.open
end

# Create a hash for the export options override the defaults
exp_options=Hash.new
#exp_options['Use Display Precision'] = true		# Boolean | Default = true
#exp_options['Field Descriptions'] = false			# Boolean | Default = false
#exp_options['Field Names'] = true					# Boolean | Default = true
#exp_options['Flag Fields '] = true					# Boolean | Default = true
#exp_options['Multiple Files'] = false				# Boolean | Default = false; Set to true to export to different files, false to export to the same file
#exp_options['Native System Types'] = false			# Boolean | Default = false
#exp_options['User Units'] = false					# Boolean | Default = false
#exp_options['Object Types'] = false				# Boolean | Default = false
#exp_options['Selection Only'] = false				# Boolean | Default = false
#exp_options['Units Text'] = false					# Boolean | Default = false
#exp_options['Coordinate Arrays Format'] = 'Packed'	# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['Other Arrays Format'] = 'Packed'		# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['WGS84'] = false						# Boolean | Default = false; Set to true to convert coordinate values into WGS84


# Export the data
nw.csv_export(
	'C:\Temp\network.csv'		# Export destination folder & filename
	exp_options					# Specified options override the default options
)