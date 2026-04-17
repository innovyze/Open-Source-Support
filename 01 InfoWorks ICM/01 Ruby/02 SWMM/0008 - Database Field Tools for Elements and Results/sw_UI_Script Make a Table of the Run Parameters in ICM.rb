# Access the current database and network, and then obtain the current model object
net = WSApplication.current_network

# Initialize the count of processed rows and prepare storage for baseline data
row_count = 0
baseline_data = []

# Collect baseline data from sw_node_additional_dwf
net.row_objects('sw_node').each do |ro|
  #ro.additional_dwf.size=0
    ro.additional_dwf.each do |additional_dwf|
        row_count += 1
          puts "#{ro.id}, #{ro.bf_pattern_1}"
        baseline_data << additional_dwf.baseline
  end
end

# Check if there is any data in baseline
if baseline_data.empty?
  puts "baseline has no data!"
else
  # Calculate statistics for baseline data
  min_value = baseline_data.min
  max_value = baseline_data.max
  sum = baseline_data.inject(0.0) { |accum, val| accum + val }
  mean_value = sum / baseline_data.size
  # Calculate the standard deviation
  sum_of_squares = baseline_data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
  standard_deviation = Math.sqrt(sum_of_squares / baseline_data.size)
  total_value = sum

  # Print statistics for baseline
  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
         "baseline, MGD", row_count, min_value, max_value, mean_value, standard_deviation, total_value)
  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
         "baseline, GPM", row_count, min_value*694.44, max_value*694.44, mean_value*694.44, standard_deviation*694.44, total_value*694.44)
end
