# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
cn = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = cn.list_timesteps.count

# Get the list of timesteps
ts = cn.list_timesteps
puts ts

# Initialize an array to store 2D zone variables
zone_variables = []

# Loop through each 2D zone in the network
cn.row_objects('hw_2d_zone').each do |zone|
  # Add the 2D zone variables to the array
  # Each 2D zone is represented as a hash with keys corresponding to variable names and values corresponding to variable values
  zone_variables << {
    'Depth 2D' => zone.depth2d,
    'Speed 2D' => zone.speed2d
  }
end

# Print the column labels
# The labels are the keys of the first hash in the zone_variables array
# Each label is left-justified and padded with spaces on the right to a total width of 20 characters for the first two labels and 10 characters for the rest
puts zone_variables.first.keys.each_with_index.map { |key, index| index < 2 ? key[0, 20].ljust(20) : key[0, 10].ljust(10) }.join(", ")

# Print the zone variables
# For each hash in the zone_variables array, the values are printed as a single row
# Each value is left-justified and padded with spaces on the right to a total width of 20 characters for the first two values and 10 characters for the rest
zone_variables.each do |variables|
  row = variables.values.each_with_index.map { |value, index| index < 2 ? value.to_s[0, 20].ljust(20) : value.to_s[0, 10].ljust(10) }.join(", ")
  puts row
end

# Iterate through the selected objects in the network
cn.each_selected do |sel|
  begin
    # Try to get the row object for the current subcatchment
    ro = cn.row_object('hw_2d_zone', sel.id)
    
    # If ro is nil, then the object with the given id is not a subcatchment
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    # Iterate over each field name
    field_names.each do |res_field_name|
      begin
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
      time_int      = (ts[1] - ts[0]).abs
      time_interval =  time_int
      puts time_interval
      
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

       # If the field name is 'rainfall', adjust the total_integrated_over_time value
       total_integrated_over_time /= 3600.0  if res_field_name == 'rainfall' 
       total_integrated_over_time * sel.total_area * 10000.0  if res_field_name != 'rainfall' 
      
      # Print the total, total integrated over time, mean, max, and min values
      puts "Sub: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for subcatchment with ID #{sel.id}."
        next
      end
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    #puts "Error processing subcatchment with ID #{sel.id}. Error: #{e.message}"
  end
end
