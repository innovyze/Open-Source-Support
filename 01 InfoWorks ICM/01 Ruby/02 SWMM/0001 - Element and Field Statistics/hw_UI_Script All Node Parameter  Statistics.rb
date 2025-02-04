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
#################################################################################################

# Define database fields for an ICM network Subcatchment object
database_fields = [
  "population",
  "base_flow",
  "trade_flow",
  "additional_foul_flow",
  "user_number_1",
  "user_number_2",
  "user_number_3",
  "user_number_4",
  "user_number_5",
  "user_number_6",
  "user_number_7",
  "user_number_8",
  "user_number_9",
  "user_number_10"
]

begin
  net = WSApplication.current_network
  net.clear_selection

 # Loop through each scenario
  net.scenarios do |s|
    
  current_scenario=net.current_scenario=s

  # Output the current scenario
  puts "Scenario     : #{net.current_scenario}"

  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Initialize the count of processed rows
  row_count = 0

  # Collect data for each field
  net.row_objects('hw_subcatchment').each do |ro|
    row_count += 1
    database_fields.each do |field|
      error_field = field # Update error_field with the current field
      value = ro[field] || 0 # Replace nil with 0 or handle it as needed
      fields_data[field] << value
    end
  end

  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    
    if data.empty?
      puts "#{field} has no data!"
      next
    end
    
    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum

    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, row_count, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end # End of scenario loop

rescue => e
  # Include the field name and number of processed rows in the error message
  puts "An error occurred with the field '#{field}' after processing #{row_count} rows: #{e.message}"
end
