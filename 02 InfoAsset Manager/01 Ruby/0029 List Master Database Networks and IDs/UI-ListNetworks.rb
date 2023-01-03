db=WSApplication.current_database
toProcess=Array.new
db.root_model_objects.each do |o|
	toProcess << o
end
while toProcess.size>0
	working=toProcess.delete_at(0)
	if working.type == "Model Network" || working.type == "Collection Network" || working.type == "Distribution Network" || working.type == "Asset Network" || working.type == "Ground Model" || working.type == "Gridded Ground Model"
		puts "#{working.id.to_s}	#{working.path}"
	end
	working.children.each do |c|
		toProcess << c
	end
end
