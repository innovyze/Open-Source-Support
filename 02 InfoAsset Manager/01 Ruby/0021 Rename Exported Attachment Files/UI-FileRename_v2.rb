require 'csv'

val=WSApplication.prompt "Rename Files",
[
['FOLDER containing files to be renamed:','String',nil,nil,'FOLDER','Files folder'],
['CSV filename mapping file:','String',nil,nil,'FILE',true,'csv','CSV mapping file',false],
['CURRENT filename column header:','String'],
['NEW filename column header:','String'],
],false
if val==nil
	WSApplication.message_box("Parameters dialog closed\nScript cancelled",'OK','!',nil)
else
puts "[Files Folder, CSV Mappings file, CURRENT filename column, NEW filename column]\n"+val.to_s

exportloc=val[0].to_s
exportfile=val[1].to_s
image=val[2].to_s
name=val[3].to_s

if val[0]==nil
	WSApplication.message_box("Files folder required\nScript cancelled",'OK','!',nil)
elsif val[1]==nil
	WSApplication.message_box("Mapping file required\nScript cancelled",'OK','!',nil)
elsif val[2]==nil || val[3]==nil
	WSApplication.message_box("Column mappings incomplete\nScript cancelled",'OK','!',nil)
else


files = Dir.foreach(exportloc).select { |x| File.file?("#{exportloc}/#{x}") }
found=[]
files.each do |a|
	b=File.basename(a, ".*")
	found << b
end


CSV.foreach(exportfile, :headers=>true) do |row|
    if (row[image].length)
        fileFrom = File.join(exportloc, row[image])
        fileTo = File.join(exportloc, row[name] + File.extname(fileFrom))
        
		filenew = row[name]
		unless found.include? filenew
			File.rename(fileFrom, fileTo)
			found << filenew
		else
		puts 'File "'+row[image]+'" not renamed, possible duplicate of "'+row[name]+'"'
		end
    end
end

end

end