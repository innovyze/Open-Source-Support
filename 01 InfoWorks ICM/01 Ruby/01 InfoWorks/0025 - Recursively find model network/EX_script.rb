$path_project = File.dirname(__FILE__)
puts "Opening master database..."
$db_name = "standalone.icmm"
$db_file = "#{$path_project}\\#{$db_name}"
$db = WSApplication.open $db_file,false
$toProcess = Array.new
$db.root_model_objects.each do |o|
	$toProcess << o
end
while $toProcess.size>0
	working = $toProcess.delete_at(0)
	if working.type == "Model Network"
		puts working.name
		puts working.path
		puts ""
	end
	working.children.each do |c|
		$toProcess << c
	end
end
