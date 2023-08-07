# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected links
field_names = [
  'us_depth', 'ds_depth',  'us_flow', 'ds_flow', 
  'us_froude', 'ds_froude',  'us_vel', 'ds_vel', 'us_totalhead',
  'ds_totalhead','hydgrad',
  'surcharge', 'volume', 'qlink', 'qinflnk', 
  'surcharge', 
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link
    ro = net.row_object('_links', sel.id)

    # Iterate over each field name
    field_names.each do |res_field_name|
      # Get the count of results for the current field
      rs_size = ro.results(res_field_name).count

      # If the count of results matches the count of timesteps, proceed with calculations
      if rs_size == ts_size
        # Initialize variables to keep track of statistics
        total = 0.0
        total_integrated_over_time = 0.0
        min_value = Float::INFINITY
        max_value = -Float::INFINITY
        count = 0
        
        # Assuming the time steps are evenly spaced, calculate the time interval in seconds
        time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1
        
        # Iterate through the results and update statistics
        ro.results(res_field_name).each_with_index do |result, time_step_index|
          total += result.to_f
          total_integrated_over_time += result.to_f * time_interval
          min_value = [min_value, result.to_f].min
          max_value = [max_value, result.to_f].max
          count += 1
        end

        # Calculate the mean value if the count is greater than 0
        mean_value = count > 0 ? total / count : 0
        
        # Print the total, total integrated over time, mean, max, and min values
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
      end
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end


