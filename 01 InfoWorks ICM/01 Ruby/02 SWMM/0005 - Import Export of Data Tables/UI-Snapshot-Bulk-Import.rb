begin

# Open the current InfoAsset Manager Network.
nw=WSApplication.current_network

# Choose import source parent directory, subfolders will be included.
dir = "C:/Temp/Data/"

# State which file type extensions are to be used. Separate each by a comma(,).
ext = 'isfc,isf'
#ext = 'xml'


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
   #nw.mscc_import_cctv_surveys(fname, 'KT', false, 2, false, dir)
end

puts "Import complete."

#nw.transaction_commit

end

