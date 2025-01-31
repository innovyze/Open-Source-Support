# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
  'qfoul', 'qtrade', 'rainfall', 'evaprate', 'grndstor', 'soilstor', 'qsoil',
  'qinfsoil', 'qrdii', 'qinfilt', 'qinfgrnd', 'qground', 'plowfw', 'plowsnow',
  'impfw', 'pervfw', 'impmelt', 'pervmelt', 'impsnow', 'pervsnow', 'losttogw',
  'napi', 'qcatch', 'q_lid_in', 'q_lid_out', 'q_lid_drain', 'q_exceedance',
  'rainprof', 'effrain', 'qbase', 'v_exceedance', 'runoff', 'qsurf01',
  'qsurf02', 'qsurf03', 'qsurf04', 'qsurf05', 'qsurf06', 'qsurf07', 'qsurf08',
  'qsurf09', 'qsurf10', 'qsurf11', 'qsurf12'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current subcatchment
    ro = net.row_object('_subcatchments', sel.id)
    
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
