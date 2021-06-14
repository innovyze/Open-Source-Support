db = WSApplication.current_database
my_network = WSApplication.current_network
my_object = my_network.model_object
parent_id = my_object.parent_id

begin
	parent_object = db.model_object_from_type_and_id 'Model Group',parent_id
	puts parent_id
	puts parent_object
rescue
	parent_object = db.model_object_from_type_and_id 'Model Network',parent_id
	parent_id = parent_object.parent_id
	puts parent_id
	parent_object = db.model_object_from_type_and_id 'Model Group',parent_id
	puts parent_object
end