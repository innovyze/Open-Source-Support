# Initialize a hash to store numeric fields. The hash is structured as {table_name: {field_name: [values]}}
numeric_fields = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }

# Initialize a hash to store non-numeric fields. The hash is structured as {value: count}
non_numeric_fields = Hash.new(0)

# Iterate through each table in the current network
WSApplication.current_network.tables.each do |table|
  # For each table, iterate through each field
  table.fields.each do |field|
    # For each field, iterate through each row object
    WSApplication.current_network.row_objects(table.name).each do |row_object|
      # Get the value of the field for the current row object
      value = row_object[field.name]

      # Check if the value is numeric
      if value.is_a?(Numeric)
        # If the value is numeric, add it to the numeric_fields hash
        numeric_fields[table.name][field.name] << value
      else
        # If the value is not numeric, increment its count in the non_numeric_fields hash
        non_numeric_fields[value] += 1
      end
    end
  end
end

# Print a summary of the numeric fields
puts "Summary of numeric fields:"
numeric_fields.each do |table_name, fields|
  fields.each do |field_name, values|
    # Calculate statistics for the current field
    count = values.size
    sum = values.sum
    max_value = values.max
    min_value = values.min
    mean = sum / count if count > 0

    # Print the statistics for the current field
    puts sprintf("Table: %-35s Field: %-30s Count: %-15d Mean: %-15.4f Max: %-15.4f Min: %-15.4f", table_name, field_name, count, mean, max_value, min_value)
  end
end

# Print a summary of the non-numeric fields
puts "Summary of non-numeric fields:"
non_numeric_fields.each do |value, count|
  # Print the count for the current value
  puts "#{value}: #{count}"
end