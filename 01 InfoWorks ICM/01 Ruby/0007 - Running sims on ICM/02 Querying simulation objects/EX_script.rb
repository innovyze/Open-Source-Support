# Select database from this path
$project_path=File.dirname(__FILE__)
$db_name="2021.1.1_Standalone.icmm"
$db_file="#{$project_path}\\#{$db_name}"
$db=WSApplication.open $db_file,false

def find_name(type,id)
	$db.model_object_from_type_and_id(type,id).name
end

# Start script
group=$db.model_object '>MODG~Model group'
group.children.each do |run|
	if run.type=='Run'
		net_id = run['Model Network']
		lev_id = run['Level']
		commit = run['Model Network Commit ID']
		rainfalls=Array.new
		run.children.each { |sim| rainfalls << sim['Rainfall event'] }
		puts "Run parameters:"
		puts "=> Model network name: #{find_name('Model network',net_id)}"
		puts "=> Model commit version: #{commit}"
		puts "=> Level file used: #{find_name('Level',lev_id)}"
		rainfalls.each do |rain_id| 
			puts "=> Rainfall file: #{find_name('Rainfall Event',rain_id)}"
		end
		puts "=> Simulation duration: #{run['Duration']}"
	end
end