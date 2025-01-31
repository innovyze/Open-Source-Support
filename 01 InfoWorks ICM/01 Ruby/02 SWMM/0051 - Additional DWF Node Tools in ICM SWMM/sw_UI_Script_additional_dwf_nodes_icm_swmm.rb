# Access the current database and network, and then obtain the current model object
cn = WSApplication.current_network

# Initialize the count of processed rows and prepare storage for baseline data and base_flow data
row_count = 0
baseline_data = []
base_flow_data = []

# Collect baseline data and base_flow data from sw_node_additional_dwf
cn.row_objects('sw_node').each do |ro|
  base_flow_data << ro.base_flow
  row_count += 1
  ro.additional_dwf.each do |additional_dwf|
    baseline_data << additional_dwf.baseline
  end
end

# Define a method to calculate and print statistics for a given data set
def print_stats(name, data, row_count)
  if data.empty?
    puts "#{name} has no data!"
  else
    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |accum, val| accum + val }
    mean_value = sum / data.size
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum

    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           "#{name}, MGD", row_count, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

# Print statistics for baseline and base_flow
print_stats("base_flow", base_flow_data, row_count)
print_stats("additional_baseline", baseline_data, row_count)
# Concatenate base_flow_data and baseline_data
combined_data = base_flow_data + baseline_data
# Print statistics for the combined data
print_stats("Combined", combined_data, row_count)
