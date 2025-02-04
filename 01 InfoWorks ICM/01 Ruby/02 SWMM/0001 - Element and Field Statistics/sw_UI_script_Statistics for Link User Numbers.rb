def print_csv_inflows_file(net)
	
	# Define database fields for SWMM network nodes
	database_fields = [
		'us_invert',
		'ds_invert',
		'length',
		'conduit_height',
		'conduit_width',
		'number_of_barrels',
		'user_number_1',
		'user_number_2',
		'user_number_3',
		'user_number_4',
		'user_number_5',
		'user_number_6',
		'user_number_7',
		'user_number_8',
		'user_number_9',
		'user_number_10'
	]

	net.clear_selection
	puts "Scenario     : #{net.current_scenario}"
  
	# Prepare hash for storing data of each field for database_fields
	fields_data = {}
	database_fields.each { |field| fields_data[field] = [] }
  
	# Initialize the count of processed rows
	row_count = 0
	total_expected = 0.0
  
	# Collect data for each field from sw_node
	net.row_objects('sw_conduit').each do |ro|
	  row_count += 1
	  database_fields.each do |field|
		fields_data[field] << ro[field] if ro[field]
	  end
	end
  
	# Print min, max, mean, standard deviation, total, and row count for each field
	database_fields.each do |field|
	  data = fields_data[field]
	  if data.empty?
		#puts "#{field} has no data!"
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
			 field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
	end
end
  
  # Usage example
  net = WSApplication.current_network
  print_csv_inflows_file(net)