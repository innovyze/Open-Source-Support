# Select database from this path
$project_path=File.dirname(__FILE__)
$db_name="2021.1.1_Standalone.icmm"
$db_file="#{$project_path}\\#{$db_name}"
$db=WSApplication.open $db_file,false

# Rerun all sims in the Model Group
$group=$db.model_object '>MODG~Model group'
$group.children.each do |run|
	$sims_array = Array.new
	if run.type=='Run'
		run.children.each { |sim| $sims_array << sim }
		WSApplication.connect_local_agent(1)
		WSApplication.launch_sims $sims_array,'.',false,0,0
	end
end
while $sims_array.any? { |sim| sim.status=='None' } 
	puts  'running'
	sleep 1
end