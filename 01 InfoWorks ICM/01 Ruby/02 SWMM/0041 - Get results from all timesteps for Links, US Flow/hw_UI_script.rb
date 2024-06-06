# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

  # Ensure there's more than one timestep before proceeding
  if ts.size <= 1
      puts "Not enough timesteps available!"
      return # or some other form of early exit appropriate for your application
    end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]) * 24 * 60 * 60

# Define the result field name
res_field_name = 'us_flow'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

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
      
      # Print the statistics
      puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    # puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
