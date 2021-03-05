# Select database from this path
$project_path=File.dirname(__FILE__)
$db_name="2021.1.1_Standalone.icmm"
$db_file="#{$project_path}\\#{$db_name}"
$db=WSApplication.open $db_file,false

# Start script
group=$db.model_object '>MODG~Model group'
group.children.each do |run|
	if run.type=='Run'
		id = run['Model Network']
		commit = run['Model Network Commit ID']
		puts "Run parameters:"
		puts "=> Model network id:          #{id}"
		puts "=> Model network name:        #{$db.model_object_from_type_and_id('Model Network',id).name}"
		puts "=> Model commit version:      #{commit}"
		puts "=> Simulation duration:       #{run['Duration']}"
	end
end