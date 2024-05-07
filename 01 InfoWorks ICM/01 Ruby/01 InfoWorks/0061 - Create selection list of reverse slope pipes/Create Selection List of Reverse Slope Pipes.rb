# Access the current network and database
net = WSApplication.current_network
db = WSApplication.current_database

# Clear any existing selection in the network
net.clear_selection

# Iterate through all conduits in 'hw_conduit'
# If a conduit has a negative gradient and its solution model is neither 'Pressure' nor 'ForceMain', select it
has_reverse_slope_pipes = false
net.row_objects('hw_conduit').each do |conduit|
  if conduit.gradient < 0 && conduit.solution_model != 'Pressure' && conduit.solution_model != 'ForceMain'
    conduit.selected = true
    has_reverse_slope_pipes = true
  end
end

# If no reverse slope pipes were found, inform the user and exit the script
unless has_reverse_slope_pipes
  puts "No reverse slope pipes in network. Selection list was not created."
  return
end

# Identify the parent model group of the current network
my_object = net.model_object
parent_id = my_object.parent_id

# Attempt to find the parent object assuming it's a 'Model Group'
# If unsuccessful, assume the parent object is a 'Model Network' and find its parent 'Model Group'
begin
  group = db.model_object_from_type_and_id 'Model Group', parent_id
rescue
  parent_object = db.model_object_from_type_and_id 'Model Network', parent_id
  parent_id = parent_object.parent_id
  group = db.model_object_from_type_and_id 'Model Group', parent_id
end

# Define the base name for the new selection list
base_name = 'Reverse Slope Pipes'
list_name = base_name
counter = 1

# Check if a selection list with the proposed name already exists within the model group
# If it does, append an integer to the base name and increment the counter until an unused name is found
group.children.each do |child|
  while child.name == list_name
    list_name = "#{base_name}_#{counter}"
    counter += 1
  end
end

# Create a new selection list with the available name in the parent model group
sl = group.new_model_object 'Selection List', list_name

# Save the currently selected conduits to the new selection list
net.save_selection sl