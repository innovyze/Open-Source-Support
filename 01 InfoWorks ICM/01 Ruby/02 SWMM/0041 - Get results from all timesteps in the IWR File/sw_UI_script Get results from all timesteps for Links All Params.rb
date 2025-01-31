# Import the 'date' library
require 'date'
 
# Get the current network object from ICM SWMM
net = WSApplication.current_network
 
# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count
 
# Get the list of timesteps
ts = net.list_timesteps
 
# Define the result field names to fetch the results for all selected links
field_names = [
    'FLOW',  'MAX_FLOW',   'DEPTH',     'VELOCITY',   'MAX_VELOCITY',  'HGL',     'FLOW_VOLUME',     'FLOW_CLASS',
    'CAPACITY',  'MAX_CAPACITY',   'SURCHARGED',     'ENTRY_LOSS',     'EXIT_LOSS'
]
  # Initialize an empty array to store the results
  results = []
 
# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link
    ro = net.row_object('_links', sel.id)
    next if ro.nil?
    diameter = ro.conduit_height / 1000.0
    full_flow = 3.14159 * (diameter/2.0) * (diameter/2.0)

    # Iterate over each field name
    field_names.each do |res_field_name|
      begin  # Nested begin for inner operations
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
            if ['FLOW'].include?(res_field_name)
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
 
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.5f' % max_value} | Min: #{'%15.5f' % min_value} | Steps: #{'%15d' % count}"
        if ['DEPTH'].include?(res_field_name)
          puts "Link: #{'%-12s' % sel.id} | Field: d/D          | Sum: #{'%15.4f' % (total_integrated_over_time/diameter)} | Mean: #{'%15.4f' % (mean_value/diameter)} | Max: #{'%15.5f' % (max_value/diameter)} | Min: #{'%15.5f' % (min_value/diameter)} | Diameter: #{'%12.3f' % diameter}"
          end
          if ['FLOW'].include?(res_field_name)
            puts "Link: #{'%-12s' % sel.id} | Field: q/Q          | Sum: #{'%15.4f' % (total_integrated_over_time/full_flow)} | Mean: #{'%15.4f' % (mean_value/full_flow)} | Max: #{'%15.5f' % (max_value/full_flow)} | Min: #{'%15.5f' % (min_value/full_flow)} | Full Flow: #{'%11.3f' % full_flow}"
          end         
      end
 
      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for link with ID #{sel.id}."
        next
      end
    end
 
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}. Error: #{e.message}"
  end
end