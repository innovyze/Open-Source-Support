# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define a hash to store the mean us_flow for each link
mean_us_flows = {}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs
# Print the time interval in seconds and minutes
puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60.0]

# Define the result field names
res_field_names = [ "us_depth", "us_flow",  "us_froude",  "us_totalhead", "us_vel","ds_depth", "ds_flow", 
"ds_depth", "ds_flow", "ds_froude", "ds_totalhead", "ds_vel",  "volume", "HYDGRAD"]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?
    res_field_names.each do |res_field_name|
      # Get the results for the specified field
      results = ro.results(res_field_name)
  
      # Ensure we have results for all timesteps
      if results.size == ts.size
        # Initialize variables for statistics
        total = 0.0
        count = 0
        total_integrated_over_time = 0.0
        min_value = results.first.to_f
        max_value = results.first.to_f

        # Iterate through the results and update statistics
        results.each do |result|
          val = result.to_f

          total += val
          total_integrated_over_time += val * time_interval
          min_value = [min_value, val].min
          max_value = [max_value, val].max
          count += 1
        end

        # Calculate the mean value
        mean_value = total / count

        # Store the mean us_flow for the current link
        mean_us_flows[sel.id] = mean_value if res_field_name == 'us_flow'

        # Print the statistics
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Mean: #{'%15.5f' % mean_value} | Max: #{'%15.5f' % max_value} | Min: #{'%15.5f' % min_value} | Steps: #{'%10d' % count} | Sum: #{'%12.5e' % total_integrated_over_time}"
      else
        puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
      end
    end
  rescue => e
    # Output error message if any error occurred during processing this object
     #puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end

# Sort the mean_us_flows hash by value in descending order and select the top ten links
top_ten_links = mean_us_flows.sort_by { |_, v| -v }.first(10).map { |k, _| k }

# Print the top ten links with the largest mean us_flow
puts
puts "Top ten links with the largest mean us_flow:"
top_ten_links.each { |link| puts link }

# Select the top ten links on the geoplan
net.clear_selection
top_ten_links.each { |link| net.row_object('_links', link).selected = true }
