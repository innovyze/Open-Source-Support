## Export from a selection a specific amount of surveys to seperate files
### Remove "_selection" from line #16 to run on all surveys

exportloc='C:\\Temp\\pacp_'		## Export folder/filename prefix
outputmax=5						## How many Surveys per export file?

if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',2		## Run on Collection Network #2 in IE
	net=dbnet.open
end

toProcess=Array.new
net.row_objects_selection('cams_cctv_survey').each do |o|
	toProcess << o.id
end

myHash=Hash.new
myHash["Selection Only"]=true
myHash["Images"]=false
myHash["Imperial"]=true
myHash["InfoAsset"]=nil
myHash["Format"]="7"

total=toProcess.count
count=0
filecount=0

net.clear_selection
while count<total
	working=Array.new
	working=toProcess.first(outputmax)
	toProcess.shift(outputmax)
	
	working.each do |cc|
		ro=net.row_object('cams_cctv_survey',cc)
		ro.selected=true
	end
	
	myHash["LogFile"]=exportloc+filecount.to_s+'-log.txt'
	export=exportloc+filecount.to_s+'.mdb'
	net.PACP_export export,myHash
	
	puts "#{working} >> #{export}"
	
	net.clear_selection
	count=count+outputmax
	filecount=filecount+1
end

puts "\nExport complete - check log files (if any) for errors."
puts "File count: #{filecount}"