#Exports images from Manhole Surveys to a chosen folder, renames them to the Original File Name or Description, moves them to sub-folders based on the Survey id

require 'csv'
require 'fileutils'

nw=WSApplication.current_network

$list=["filename","description"]

val=WSApplication.prompt "Rename Files",
[
['FOLDER to export files to:','String',nil,nil,'FOLDER','Files folder'],
['CSV filename mapping file:','String',nil,nil,'FILE',false,'csv','CSV mapping file',false],
['Rename to Original File Name or Description:','String',nil,nil,'LIST',$list],
],false
puts "[Files Folder, CSV Mappings file, Original File Name or Description]\n"+val.to_s

exportloc=val[0].to_s
exportfile=val[1].to_s
exportname=val[2].to_s
config = File.dirname(WSApplication.script_file)

if val==nil
	WSApplication.message_box("Parameters dialog closed\nScript cancelled",'OK','!',nil)
	abort("Invalid parameters.")
	exit
elsif val[0]==nil
	WSApplication.message_box("Files folder required\nScript cancelled",'OK','!',nil)
elsif val[1]==nil
	WSApplication.message_box("Mapping file required\nScript cancelled",'OK','!',nil)
elsif val[2]==nil
	WSApplication.message_box("New file name required\nScript cancelled",'OK','!',nil)
else


options=Hash.new
options['Error File'] = exportloc+'\ErrorLog.txt'		# Default = nil
options['Image Folder'] = exportloc						# Default = nil
options['Append'] = false								# Boolean, True to enable 'Append to existing data' | Default = FALSE
options['Export Selection'] = true						# Boolean, True to export the selected objects only | Default = FALSE

nw.odec_export_ex('csv',config+'\\locationsketch.cfg',options,'ManholeSurvey',exportfile)
options['Append'] = true
nw.odec_export_ex('csv',config+'\\locationimage.cfg',options,'ManholeSurvey',exportfile)
nw.odec_export_ex('csv',config+'\\internalview.cfg',options,'ManholeSurvey',exportfile)
nw.odec_export_ex('csv',config+'\\plansketch.cfg',options,'ManholeSurvey',exportfile)
nw.odec_export_ex('csv',config+'\\attachments.cfg',options,'ManholeSurvey',exportfile)

files = Dir.foreach(exportloc).select { |x| File.file?("#{exportloc}/#{x}") }
found=[]
files.each do |a|
	b=File.basename(a, ".*")
	found << b
end

CSV.foreach(exportfile, :headers=>true) do |row|
    if !row["db_ref"].nil?
		if !row[exportname].nil?
		
			fileFolder = exportloc+'\\'+(row["id"].gsub(/[^0-9A-Za-z. _-]/, ''))
			unless Dir.exists?(fileFolder)
				Dir.mkdir(fileFolder)
			end
		
			fileFrom = File.join(exportloc, row["db_ref"])
			filename = row[exportname]
			fileTo = File.join(fileFolder, filename.gsub(/[^0-9A-Za-z. _-]/, '') + File.extname(fileFrom))
			
			filenew = fileTo#row[exportname]
			unless found.include? fileTo
				File.rename(fileFrom, fileTo)
				puts 'File "'+row["db_ref"]+'" >> "'+fileTo+'"'
				found << fileTo
			else
				puts 'ERROR: File "'+row["db_ref"]+'" not renamed, possible duplicate of "'+row[exportname]+'"'
				FileUtils.mv(fileFrom,File.join(fileFolder,row["db_ref"]))
			end
		else
			puts 'ERROR: File "'+row["db_ref"]+'" not renamed, no new name in column "'+exportname+'"'
		end
    end
end

end