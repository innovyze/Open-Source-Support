def print_table_results(cn)
  # Iterate over each table in the network
  cn.tables.each do |table|
    # Initialize an array to store the names of result fields
    results_array = []
    found_results = false

    # Check each row object in the current table
    cn.row_object_collection(table.name).each do |row_object|
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

    # Print the table name and each of its result fields on a separate row only if there are result fields
    unless results_array.empty?
      puts "Table: #{table.name.upcase}"
      results_array.each do |field|
        puts "Result field: #{field}"
      end
      puts
    end
  end
end

# Usage example
cn = WSApplication.current_network
print_table_results(cn)