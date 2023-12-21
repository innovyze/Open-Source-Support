require 'date'

NodeResultsDataFields = [
  'DEPNOD',
  'FloodDepth',
  'GLLYFLOW',
  'GTTRSPRD',
  'INLETEFF',
  'OVDEPNOD'
]

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Output the headers for the HEC22 comparison
header_fields = NodeResultsDataFields.map { |field| field.ljust(9) }.join(' ')
puts ";#{'Node_ID'.ljust(11)} #{'Time'.ljust(8)} #{header_fields} inlet_eff_value hec22_spread hec22_eff hec22_eff_diff ICM_NEW_T	ICM_OLD_T"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Get the row object for the current node using node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a node)
    next if ro.nil?

    # Initialize the counter for the timesteps
    count = 0

    # This loop should iterate through each timestep
    ts.each_with_index do |timestep, index|
      # Collect results for all specified fields
      all_field_results = NodeResultsDataFields.map do |field|
        field_results = ro.results(field)
        if field_results.empty?
          puts "Field '#{field}' does not exist for node ID #{sel.id}. Exiting script."
          exit
        elsif field_results.size == ts.size
          val = field_results[index].to_f # Get the value for the current timestep
          '%.4f' % val
        else
          'N/A' # Not available or mismatch in timestep count
        end
      end

      
      # Calculate the exact time for this result
      current_time = count * time_interval
       # Extract the DEPNOD value for the current index if it is one of the fields
       depnod_value = all_field_results[NodeResultsDataFields.index('FloodDepth')].nil? ? 0.0 : all_field_results[NodeResultsDataFields.index('DEPNOD')].to_f rescue 0.0
       depnode_value = depnod_value - 16.190
       inlet_eff_value = all_field_results[NodeResultsDataFields.index('INLETEFF')].nil? ? 0.0 : all_field_results[NodeResultsDataFields.index('INLETEFF')].to_f rescue 0.0
       inlet_flow_value = all_field_results[NodeResultsDataFields.index('GLLYFLOW')].nil? ? 0.0 : all_field_results[NodeResultsDataFields.index('GLLYFLOW')].to_f rescue 0.0      
   
      hec22_spread = 0.87*(inlet_flow_value**0.42)*0.0003802**0.3*(1.0/(0.013*0.02)**0.6)      #  =$P$10*(GLLYFLOW^0.42)*($P$8^0.3)*(1/(($P$9*$P$6)^0.6))    
      icm_spread = all_field_results[NodeResultsDataFields.index('GTTRSPRD')].to_f rescue 0.0

        # Check if depnod_value is greater than or equal to 0.0
        if depnod_value >= 0.0
          if depnod_value == 0.0
              # Handle the case where depnod_value is 0 to avoid division by zero
              # You can assign a default value or handle it as needed
              icm_spreadsheet = 0 # or some other appropriate handling
          else
              # Calculate icm_spreadsheet using the given formula
              icm_spreadsheet = 1.469 * ((inlet_flow_value ** 1.02) / (depnod_value ** 1.6))               # =$P$4*((B2^1.02)/(D2^1.6))
              icm_spread_old  = 1.469 * ((inlet_flow_value ** 1.02) / (depnod_value ** 1.6))*0.2 ** 0.6   # =$P$4*((B2^1.02)/(D2^1.6))*$P$6^0.6
          end
        else
          # Handle the case where depnod_value is negative if needed
          # For example, set icm_spreadsheet to nil or a specific error value
          icm_spreadsheet = nil # or some error handling
        end

        if hec22_spread > ro.opening_length
          hec22_eff = 1.0 - ( 1 - (ro.opening_length/hec22_spread)**1.8)    #   =IF(G2>$P$7,1-(1-($P$7/G2))^1.8,1)
        else
          hec22_eff = 1.0 # or appropriate handling for the case when hec22_spread is 0
          inlet_eff_value = 1.0
        end
      
      hec22_eff_diff = hec22_eff -  inlet_eff_value

      # Assuming current_time is in seconds
      days = current_time / (24 * 60 * 60) # Number of days
      remaining_seconds = current_time % (24 * 60 * 60)
      hours = remaining_seconds / (60 * 60) # Number of hours
      remaining_seconds %= (60 * 60) # Remaining seconds after hours
      minutes = remaining_seconds / 60 # Number of minutes
      seconds = remaining_seconds % 60 # Remaining seconds after minutes

      # Output the results for all fields on the same line
      puts "#{sel.id.ljust(10)} #{hours.to_i.to_s.rjust(2, '0')}:#{format('%02d', minutes)}:#{format('%02d', seconds)} " +
           "#{all_field_results.map { |result| result.ljust(10) }.join(' ')} #{'%10.4f' % inlet_eff_value} #{'%10.4f' % hec22_spread} #{'%10.4f' % hec22_eff} #{'%10.4f' % hec22_eff_diff} #{'%10.4f' % icm_spread_old} #{'%10.4f' % icm_spreadsheet}"
      count += 1 # Increment the counter after each iteration
    end
  rescue => e
    # Output error message if any error occurred during processing this node
    puts "Error processing node with ID #{sel.id}. Error: #{e.message}"
  end
end
