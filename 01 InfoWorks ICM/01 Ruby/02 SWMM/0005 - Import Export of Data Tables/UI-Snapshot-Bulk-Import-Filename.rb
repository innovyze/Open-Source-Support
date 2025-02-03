#Import a file with a non-specific filename
#Import a .isfc file from the diretcory with 'survey' within the name

begin

# Open the current InfoAsset Manager Network.
nw=WSApplication.current_network


# Identify files in the directory & sub-directories and import
Dir.glob('C:/Temp/data/**/*'+'survey'+'*.isfc').each do |fname|
	puts "Importing #{fname}"
   nw.snapshot_import_ex(fname, nil)
end

puts "Import complete."

end