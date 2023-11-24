def print_table_results(net)
  # Iterate over each table in the network
  net.tables.each do |table|
    # Initialize an array to store the names of result fields
    results_array = []
    found_results = false

    # Check each row object in the current table
    net.row_object_collection(table.name).each do |row_object|
      # Check if the row object has a 'results_fields' property and results have not been found yet
      if row_object.table_info.results_fields && !found_results
        # If yes, add the field names to the results_array
        row_object.table_info.results_fields.each do |field|
          results_array << field.name
        end
        found_results = true  # Set flag to true after finding the first set of results
        break  # Exit the loop after processing the first row with results
      end
    end

    # Print the table name and its result fields only if there are result fields
    unless results_array.empty?
      puts "Table: #{table.name.upcase}"
      puts "Results fields: #{results_array.join(', ')}"
      puts
    end
  end
end

# Usage example
net = WSApplication.current_network
print_table_results(net)
