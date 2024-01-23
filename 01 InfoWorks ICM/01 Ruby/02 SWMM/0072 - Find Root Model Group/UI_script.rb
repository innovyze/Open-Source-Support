# Access the current database and network, and then obtain the current model object
db = WSApplication.current_database
my_network = WSApplication.current_network
my_object = my_network.model_object

# Get the parent ID and type of the current object
p_id = my_object.parent_id
p_type = my_object.parent_type

# Retrieve the parent object from the database
parent_object = db.model_object_from_type_and_id(p_type, p_id)

# Loop through the hierarchy of parent objects
(0..999).each do
  # Print the name of the current parent object
  puts "Parent Object: #{parent_object.name}"

  # Get the parent ID and type of the current parent object
  temp_p_id = parent_object.parent_id
  temp_p_type = parent_object.parent_type

  # Break the loop if the parent ID is 0, indicating the top of the hierarchy
  break if temp_p_id == 0

  # Retrieve the next parent object in the hierarchy
  parent_object = db.model_object_from_type_and_id(temp_p_type, temp_p_id)
end
