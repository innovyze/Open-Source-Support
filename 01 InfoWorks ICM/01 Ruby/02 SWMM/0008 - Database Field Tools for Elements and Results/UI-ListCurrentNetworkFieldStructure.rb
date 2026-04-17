# Get the current network
on=WSApplication.current_network

# Iterate over each table in the network
on.tables.each do |i|
  # Print the table description and name
  puts "****#{i.description}, #{i.name}"
  field_counter = 1
  # Iterate over each field in the table
  i.fields.each do |j|
    # Skip if the field's name or description contains the word "flag", "user", "nodes", or "hyperlinks"
    next if j.name.include?('flag') || j.description.include?('flag') || j.name.include?('user') || j.description.include?('user') || j.name.include?('notes') || j.description.include?('notes') || j.name.include?('hyperlinks') || j.description.include?('hyperlinks')

    # Print the field description, name, and data type
    puts  "\t#{field_counter}. #{j.description}, #{j.name}, #{j.data_type}"
    field_counter += 1
    # Check if the field's data type is 'WSStructure'
    if j.data_type=='WSStructure'
      if j.fields.nil?
        puts "\t\t***badger***"
      else
        # Iterate over each field in the 'WSStructure' data type
        j.fields.each do |bf|
          # Skip if the blob field's name or description contains the word "flag", "user", "notes", or "hyperlinks"
          next if bf.name.include?('flag') || bf.description.include?('flag') || bf.name.include?('user') || bf.description.include?('user') || bf.name.include?('notes') || bf.description.include?('notes') || bf.name.include?('hyperlinks') || bf.description.include?('hyperlinks')

          # Print the blob field description, name, and data type
          puts "\t\t#{bf.description}, #{bf.name}, #{bf.data_type}"
        end
      end
    end
  end
end

# Get the current network again
on=WSApplication.current_network

# Iterate over each table in the network
on.tables.each do |i|
  # Skip if the table name does not contain "sw_" or "hw_"
  next unless i.name.include?('sw_') || i.name.include?('hw_')
  # Print the table description and name
  puts "#{i.description}, #{i.name}"
end

# Initialize an array to hold table names
table_names = []
puts
# Iterate over each table in the network
on.tables.each do |i|
  # Add to the array if the table name contains "sw_" or "hw_"
  table_names << i.name if i.name.include?('sw_') || i.name.include?('hw_')
end

# Print the table names on one line separated by a comma
puts table_names.join(', ')
puts