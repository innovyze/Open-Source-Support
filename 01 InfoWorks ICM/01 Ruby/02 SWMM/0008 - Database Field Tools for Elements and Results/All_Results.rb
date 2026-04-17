
# Initialize variables
numeric_fields = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }
non_numeric_fields = Hash.new(0)

# Iterate through each table in the current network
WSApplication.current_network.tables.each do |table|
  puts "Processing table: #{table.name}"
  # For each table, iterate through each row object
  WSApplication.current_network.row_objects(table.name).each do |row_object|
    # Check if the row object has results fields
    if row_object.table_info.results_fields
      # For each results field, iterate
      row_object.table_info.results_fields.each do |field|
        puts "Table: #{table.name} Field: #{field.name}"
        # Check if the field exists in the row object
        if row_object.has_field?(field.name)
          value = row_object[field.name]

          if value.is_a?(Numeric)
            numeric_fields[table.name][field.name] << value
          else
            non_numeric_fields[value] += 1
          end
        else
          puts "Field #{field.name} does not exist in table: #{table.name}"
        end
      end
    else
      puts "No results fields for table: #{table.name}"
    end
  end
end

# Print summary of numeric fields
puts "Summary of numeric fields:"
numeric_fields.each do |table_name, fields|
  fields.each do |field_name, values|
    count = values.size
    sum = values.sum
    max_value = values.max
    min_value = values.min
    mean = sum / count if count > 0

    puts sprintf("Table: %-35s Field: %-30s Count: %-15d Mean: %-15.4f Max: %-15.4f Min: %-15.4f", table_name, field_name, count, mean, max_value, min_value)
  end
end

# Print summary of non-numeric fields
puts "Summary of non-numeric fields:"
non_numeric_fields.each do |value, count|
  puts "#{value}: #{count}"
end

# Print summary of numeric fields
puts "Summary of numeric fields:"
numeric_fields.each do |table_name, fields|
  fields.each do |field_name, values|
    count = values.size
    sum = values.sum
    max_value = values.max
    min_value = values.min
    mean = sum / count if count > 0

    puts sprintf("Table: %-35s Field: %-30s Count: %-15d Mean: %-15.4f Max: %-15.4f Min: %-15.4f", table_name, field_name, count, mean, max_value, min_value)
  end
end

# Print summary of non-numeric fields
puts "Summary of non-numeric fields:"
non_numeric_fields.each do |value, count|
  puts "#{value}: #{count}"
end