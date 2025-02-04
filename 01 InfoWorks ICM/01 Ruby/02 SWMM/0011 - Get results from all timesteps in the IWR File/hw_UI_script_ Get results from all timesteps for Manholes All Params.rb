# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps and gauge timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs
# Print the time interval in seconds and minutes
puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60.0]

# Define the result field names to fetch the results for all selected nodes
result_field_names = [
  'depnod', 'dmaxd', 'volume', 'flooddepth', 'floodvolume', 'flvol',
  'qinfnod', 'qnode', 'qrain', 'flooddepth', 'floodvolume', 'flvol',
  'gllyflow', 'gttrsprd', 'inleteff', 'ovdepnod', 'ovqnode', 'ovvolume',
  'twoddepnod', 'twodflow', 'twodfloodflow', 'ctwodflow', 'q_limited',
  'q_limited_volume', 'q_limited_volume_rate'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current node
    ro = net.row_object('hw_node', sel.node_id) 
    
    # If ro is nil, then the object with the given id is not a node
    raise "Object with ID #{sel.node_id} is not a node." if ro.nil?

    # Iterate through each result field name
    result_field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        # Check if the count of results matches the count of timesteps
        if rs_size == ts_size

          # Initialize variables to keep track of statistics
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0

          # Iterate through the results and calculate statistics
          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            
            if ['qnode', 'qinfnod', 'qrain'].include?(res_field_name)
              total_integrated_over_time += result.to_f * time_interval
            else
              total_integrated_over_time = result.to_f
            end

            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          # Calculate the mean value if the count is greater than 0
          mean_value = count > 0 ? total / count : 0
          
          # Print the total, total integrated over time, mean, max, min values, and count
          if ['qnode', 'qinfnod', 'qrain'].include?(res_field_name)
          puts "Node: #{'%-12s' % sel.node_id} | #{'%-16s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
          else
          puts "Node: #{'%-12s' % sel.node_id} | #{'%-16s' % res_field_name} | End: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
          end 
        end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for node with ID #{sel.node_id}."
        next
      end
    end

      rescue => e
        # Output error message if any error occurred during processing this object
        #puts "Error processing node with ID #{sel.node_id}. Error: #{e.message}"
      end
    end
