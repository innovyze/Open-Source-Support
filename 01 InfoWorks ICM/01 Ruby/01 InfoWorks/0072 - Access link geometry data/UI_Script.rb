# Access the currently open network in the application
net = WSApplication.current_network

# Prepare an array to hold the data
data = []

# Access and iterate over all row_objects within '_links'
net.row_objects('_links').each do |ro|
    # Add the row data to the array
    data << [ro.id, ro.point_array.join(', ')]
end

# Print the data
data.each do |row|
    puts "#{row[0]}: #{row[1]}"
end