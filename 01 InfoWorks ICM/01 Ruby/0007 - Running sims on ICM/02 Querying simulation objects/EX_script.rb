# Select database from this path
$project_path=File.dirname(__FILE__)
$db_name="2021.1.1_Standalone.icmm"
$db_file="#{$project_path}\\#{$db_name}"
$db=WSApplication.open $db_file,false

# Start script
group=$db.model_object '>MODG~Model group'
group.children.each do |run|
	if run.type=='Run'
		model_id = run['Model Network']
		level_id = run['Level']
		commit = run['Model Network Commit ID']
		puts "Run parameters:"
		puts "=> Model network name:        #{$db.model_object_from_type_and_id('Model Network',model_id).name}"
		puts "=> Model commit version:      #{commit}"
		puts "=> Level file used:           #{$db.model_object_from_type_and_id('Level',level_id).name}"
		puts "=> Simulation duration:       #{run['Duration']}"
	end
end