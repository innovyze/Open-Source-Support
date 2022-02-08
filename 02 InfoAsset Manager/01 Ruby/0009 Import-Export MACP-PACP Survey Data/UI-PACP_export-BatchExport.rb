## Export from a selection a specific amount of surveys to seperate files
### Remove "_selection" from line #18 to run on all surveys

exportloc='C:\\Temp\\pacp_'		## Export folder/filename prefix
outputmax=5						## How many Surveys per export file?

net=WSApplication.current_network

myHash=Hash.new
myHash["Selection Only"]=true
myHash["Images"]=false
myHash["Imperial"]=true
myHash["InfoAsset"]=nil
myHash["Format"]="7"


toProcess=Array.new
net.row_objects_selection('cams_cctv_survey').each do |o|
	toProcess << o.id
end

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
puts "Object count: #{total}"
puts "File count: #{filecount}"