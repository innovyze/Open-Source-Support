# Export a selection which you create to CSV file(s) via csv_export method

# Use the current network
nw=WSApplication.current_network

# Make a selecion of objects based on type
nw.clear_selection
nw.row_objects('cams_cctv_survey').each do |ro|
	ro.selected=true
end

# Create a hash for the export options override the defaults
exp_options=Hash.new
#exp_options['Use Display Precision'] = true		# Boolean | Default = true
#exp_options['Field Descriptions'] = false			# Boolean | Default = false
#exp_options['Field Names'] = true					# Boolean | Default = true
#exp_options['Flag Fields '] = true					# Boolean | Default = true
#exp_options['Multiple Files'] = false				# Boolean | Default = false; Set to true to export to different files, false to export to the same file
#exp_options['Native System Types'] = false		# Boolean | Default = false
#exp_options['User Units'] = false					# Boolean | Default = false
#exp_options['Object Types'] = false				# Boolean | Default = false
exp_options['Selection Only'] = true				# Boolean | Default = false
#exp_options['Units Text'] = false					# Boolean | Default = false
#exp_options['Coordinate Arrays Format'] = 'Packed'	# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['Other Arrays Format'] = 'Packed'		# String | Default = Packed. Either: Packed, None, or Separate


# Export the data
nw.csv_export(
	'C:\Temp\network.csv',		# Export destination folder & filename
	exp_options					# Specified options override the default options
)