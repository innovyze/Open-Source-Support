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
image=val[2].downcase.to_s
name=val[3].downcase.to_s

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


converter = lambda { |header| header.downcase }
CSV.foreach(exportfile, :headers=>true, header_converters: converter) do |row|
rn=$.
    if !row[image].to_s.strip.empty?
        currentFile = row[image].to_s.strip
        newName = row[name].to_s.strip.gsub(/[^0-9A-Za-z. _-]/, '')
        newName = File.basename(newName, ".*")
        if newName.empty?
            puts 'File "'+currentFile+'" not renamed, new filename "'+row[name]+'" has no valid characters after sanitisation'
            next
        end
        fileFrom = File.join(exportloc, currentFile)
        unless File.exist?(fileFrom)
            puts 'File "'+currentFile+'" not renamed, source file not found in folder'
            next
        end
        fileTo = File.join(exportloc, newName + File.extname(fileFrom))
		fileTo2 = File.join(exportloc, newName + '_' + rn.to_s + File.extname(fileFrom))
        
		filenew = newName
		filenew2 = newName + '_' + rn.to_s
		
		if !found.include? filenew
			File.rename(fileFrom, fileTo)
			found << filenew
			puts 'File "'+currentFile+'" renamed "'+filenew+'"'
			
		elsif !found.include? filenew2
			File.rename(fileFrom, fileTo2)
			found << filenew2
			puts 'File "'+currentFile+'" renamed "'+filenew2+'"'
		
		else
		puts 'File "'+currentFile+'" not renamed, possible duplicate of "'+newName+'"'
		end
    end
end

end

end