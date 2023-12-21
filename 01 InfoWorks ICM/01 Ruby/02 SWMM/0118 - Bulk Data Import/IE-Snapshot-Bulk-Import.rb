begin

# Open an InfoAsset Manager database.
db = WSApplication.open('localhost:40000/IA_2020.2',false)

# Choose Network to Import into.
nw = db.model_object_from_type_and_id('Collection Network', 32)

# Choose import source parent directory, subfolders will be included.
dir = 'C:/Temp/Data/'

# State which file type extensions are to be used. Separate each by a comma(,).
ext = 'isfc,isf'


# Open the network
on = nw.open

# Update network before importing snapshot files
nw.update

# Create a hash for the options of the import method
options=Hash.new
options['AllowDeletes'] = true									#Boolean
options['ImportGeoPlanPropertiesAndThemes'] = false				#Boolean
options['UpdateExistingObjectsFoundByID'] = false 				#Boolean
options['UpdateExistingObjectsFoundByUID'] = true				#Boolean
options['ImportImageFiles'] = true								#Boolean


puts "Data location: #{dir}"

# Identify files in the directory and import
Dir.glob(dir+'**/*.{'+ext+'}').each do |fname|
	puts "Importing #{fname}"
    on.snapshot_import_ex(fname, options)	# Set the import method. Currently: snapshot_import_ex
end

puts "Import complete."


# Commit network
nw.commit("#{ext} data imported from #{dir}")

puts "Network committed."

end
