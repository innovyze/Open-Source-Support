# Get the current database
db = WSApplication.current_database

# Get the current network
my_network = WSApplication.current_network

# Get the model object of the current network
my_object = my_network.model_object

# Get the parent ID and parent type of the current model object
p_id = my_object.parent_id
p_type = my_object.parent_type

# Get the parent object using the parent ID and parent type
parent_object = db.model_object_from_type_and_id p_type, p_id

# Iterate through a range of numbers from 0 to 999
(0..999).each do
	# Get the parent ID and parent type of the parent object
	temp_p_id = parent_object.parent_id
	temp_p_type = parent_object.parent_type

	# Print the name of the parent object
	puts parent_object.name

	# Break the loop if the parent ID is 0
	break if temp_p_id == 0

	# Get the new parent object using the new parent ID and parent type
	parent_object = db.model_object_from_type_and_id temp_p_type, temp_p_id
end