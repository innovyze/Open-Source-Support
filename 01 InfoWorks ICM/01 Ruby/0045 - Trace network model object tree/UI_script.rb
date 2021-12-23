db = WSApplication.current_database
nw = WSApplication.current_network

my_object = nw.model_object
p_id = my_object.parent_id
p_type = my_object.parent_type
parent_object = db.model_object_from_type_and_id p_type, p_id

def object_specs(object)
    hash = Hash.new
    hash['type'] = object.type
    hash['id'] = object.id
    hash['name'] = object.name
    hash
end

genealogy = Array.new
genealogy << object_specs(my_object)

(1..999).each do |no|
	temp_p_id = parent_object.parent_id
	temp_p_type = parent_object.parent_type
    genealogy << object_specs(parent_object)
	break if temp_p_id == 0
	parent_object = db.model_object_from_type_and_id temp_p_type, temp_p_id
end

genealogy.reverse!.each_with_index do |mo,i|
    puts "level #{i}: #{mo}"
end