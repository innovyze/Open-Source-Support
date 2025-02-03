# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Initialize a hash to store the top ten values for each link
top_values = {}
# Initialize a hash to store the maximum values for each link
max_values = {}

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
res_field_names = [ "us_depth", "us_flow", "ds_depth", "ds_flow"]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Initialize arrays for us_d_over_D and us_q_over_Qfull
    us_d_over_D_values = []
    us_q_over_Qfull_values = []
    ds_d_over_D_values = []
    ds_q_over_Qfull_values = []

    res_field_names.each do |res_field_name|
      # Get the results for the specified field
      results = ro.results(res_field_name)
  
      # Ensure we have results for all timesteps
      if results.size == ts.size
        # Initialize variables for statistics
        total = 0.0
        count = 0
        min_value = results.first.to_f
        max_value = results.first.to_f

        # Iterate through the results and update statistics
        results.each do |result|
          val = result.to_f
          total += val
          min_value = [min_value, val].min
          max_value = [max_value, val].max
          count += 1

          # Calculate us_d_over_D and us_q_over_Qfull and store them in the arrays
          if res_field_name == 'us_depth'
            us_d_over_D_values << val / (ro.conduit_height / 100.0)
          elsif res_field_name == 'us_flow'
            us_q_over_Qfull_values << val / ro.capacity
          elsif res_field_name == 'ds_depth'
            ds_d_over_D_values << val / (ro.conduit_height / 100.0)
          elsif res_field_name == 'ds_flow'
            ds_q_over_Qfull_values << val / ro.capacity
          end
        end

        # Calculate the mean value
        mean_value = total / count

        # Print the statistics
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-19s' % res_field_name} | Mean: #{'%15.5f' % mean_value} | Max: #{'%15.5f' % max_value} | Min: #{'%15.5f' % min_value} | Steps: #{'%10d' % count}"
      else
        puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
      end
    end

    # Calculate and print the statistics for us_d_over_D and us_q_over_Qfull
    if us_d_over_D_values.any?
      mean = us_d_over_D_values.sum / us_d_over_D_values.size
      min, max = us_d_over_D_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_d_over_D         | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_d_over_D_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if us_q_over_Qfull_values.any?
      mean = us_q_over_Qfull_values.sum / us_q_over_Qfull_values.size
      min, max = us_q_over_Qfull_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_q_over_Qfull     | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_q_over_Qfull_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if us_d_over_D_values.any?
      mean = us_d_over_D_values.sum / us_d_over_D_values.size
      min, max = us_d_over_D_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_d_over_D         | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_d_over_D_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if us_q_over_Qfull_values.any?
      mean = us_q_over_Qfull_values.sum / us_q_over_Qfull_values.size
      min, max = us_q_over_Qfull_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_q_over_Qfull     | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_q_over_Qfull_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if ds_d_over_D_values.any?
      mean = ds_d_over_D_values.sum / ds_d_over_D_values.size
      min, max = ds_d_over_D_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: ds_d_over_D         | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % ds_d_over_D_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if ds_q_over_Qfull_values.any?
      mean = ds_q_over_Qfull_values.sum / ds_q_over_Qfull_values.size
      min, max = ds_q_over_Qfull_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: ds_q_over_Qfull     | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % ds_q_over_Qfull_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end

      # Calculate the maximum for us_d_over_D and ds_d_over_D
      if us_d_over_D_values.any?
        max_us_d_over_D = us_d_over_D_values.max
        max_values[sel.id] = { 'us_d_over_D' => max_us_d_over_D }
      end
      if ds_d_over_D_values.any?
        max_ds_d_over_D = ds_d_over_D_values.max
        max_values[sel.id] = { 'ds_d_over_D' => max_ds_d_over_D }
      end

  rescue => e
    # Output error message if any error occurred during processing this object
    #puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
net.clear_selection
# Find the top ten links for us_d_over_D and ds_d_over_D
top_links_us = max_values.select { |id, fields| fields['us_d_over_D'] }.sort_by { |id, fields| -fields['us_d_over_D'] }.first(10).map(&:first)
top_links_ds = max_values.select { |id, fields| fields['ds_d_over_D'] }.sort_by { |id, fields| -fields['ds_d_over_D'] }.first(10).map(&:first)

# Select the top ten links in the network
net.row_objects('hw_conduit').each do |ro|
  top_links_us.each do |id|
    if ro.id == id then ro.selected = true end
  end
end
net.row_objects('hw_conduit').each do |ro|
  top_links_ds.each do |id|
    if ro.id == id then ro.selected = true end
  end
end

# Print the top ten links for us_d_over_D and ds_d_over_D
puts "Top 10 links for us_d_over_D: #{top_links_us.join(', ')}"
puts "Top 10 links for ds_d_over_D: #{top_links_ds.join(', ')}"
 