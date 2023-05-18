db = WSApplication.current_database
my_network = WSApplication.current_network
my_object = my_network.model_object

p_id = my_object.parent_id
p_type = my_object.parent_type
parent_object = db.model_object_from_type_and_id p_type, p_id

(0..999).each do
	temp_p_id = parent_object.parent_id
	temp_p_type = parent_object.parent_type
	puts parent_object.name
	break if temp_p_id == 0
	parent_object = db.model_object_from_type_and_id temp_p_type, temp_p_id
end