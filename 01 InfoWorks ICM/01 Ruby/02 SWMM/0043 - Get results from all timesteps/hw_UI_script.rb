# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps and gauge timesteps
ts_size = net.list_timesteps.count
ts_g_size = net.list_gauge_timesteps.count

# Get the list of timesteps and gauge timesteps
ts = net.list_timesteps
ts_g = net.list_gauge_timesteps

# Define the result field name to fetch the results (in this case, 'depnod')
res_field_name = 'QNODE'

# Iterate through the selected objects in the network (e.g., nodes)
net.each_selected do |sel|
  # Get the row object for the current node
  ro = net.row_object('hw_node', sel.node_id)

  # Get the count of results and gauge results for the specified field
  rs_size = ro.results(res_field_name).count
  rs_g_size = ro.gauge_results(res_field_name).count

  # Check if the count of gauge results matches the count of gauge timesteps
  if rs_g_size == ts_g_size
    puts "Gauge Results: #{sel.node_id}"
    i = 0
    # Iterate through the gauge results and print each one
    ro.gauge_results(res_field_name).each do |result|
      puts res_field_name,"#{ts_g[i]}: #{result}"
      i += 1
    end
  # Check if the count of results matches the count of timesteps
  elsif rs_size == ts_size
    puts "Results: #{sel.node_id}"

# Initialize variables to keep track of statistics
total = 0.0 # Added this line for the total sum
total_integrated_over_time = 0.0
min_value = Float::INFINITY
max_value = -Float::INFINITY
count = 0

# Assuming the time steps are evenly spaced, calculate the time interval in seconds
time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1

# Iterate through the results and print each one
ro.results(res_field_name).each_with_index do |result, time_step_index|
  # Update the total, total integrated over time, min, and max based on the current result
  total += result.to_f # Added this line to calculate the total sum
  total_integrated_over_time += result.to_f * time_interval
  min_value = [min_value, result.to_f].min
  max_value = [max_value, result.to_f].max
  count += 1 # Increment the count for calculating the mean
   end
end 

# Calculate the mean value if the count is greater than 0
mean_value = count > 0 ? total / count : 0

# Print the total, total integrated over time, mean, min, and max values
puts "Total Integrated Over Time:  #{'%.4f' % total_integrated_over_time}"
puts "Mean:                        #{'%.4f' % mean_value}"
puts "Min:                         #{'%.4f' % min_value}"
puts "Max:                         #{'%.4f' % max_value}"
puts res_field_name

  # Print an empty line for better readability
  puts ""
end




