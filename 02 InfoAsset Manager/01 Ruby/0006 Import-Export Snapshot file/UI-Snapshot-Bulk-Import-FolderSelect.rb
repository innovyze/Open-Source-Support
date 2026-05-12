begin

# Open the current InfoAsset Manager Network.
nw=WSApplication.current_network

# Choose import source parent directory using a folder browser dialog. Subfolders will be included.
dir = WSApplication.folder_dialog('Select the import source folder', true)

# Exit gracefully if the user cancels the dialog.
if dir.nil?
  puts "No folder selected. Import cancelled."
  return
end

# Normalise to forward slashes (Windows paths may use backslashes) and ensure trailing slash.
dir = dir.gsub('\\', '/')
dir = dir.end_with?('/') ? dir : dir + '/'

# State which file type extensions are to be used. Separate each by a comma(,).
ext = 'isfc,isf'

# Create a hash for the options of the import method
options=Hash.new
options['AllowDeletes'] = true									#Boolean
options['ImportGeoPlanPropertiesAndThemes'] = false				#Boolean
options['UpdateExistingObjectsFoundByID'] = false 				#Boolean
options['UpdateExistingObjectsFoundByUID'] = true				#Boolean
options['ImportImageFiles'] = true								#Boolean

# Start a transaction so all files imports are one transaction,. not available for all methods
#nw.transaction_begin

puts "Data location: #{dir}"

# Identify files in the directory and sub-directories
Dir.glob(dir+'**/*.{'+ext+'}').each do |fname|
	puts "Importing #{fname}"
   nw.snapshot_import_ex(fname, options)	# Set the import method and parameters. Currently: snapshot_import_ex
end

puts "Import complete."

#nw.transaction_commit

end
