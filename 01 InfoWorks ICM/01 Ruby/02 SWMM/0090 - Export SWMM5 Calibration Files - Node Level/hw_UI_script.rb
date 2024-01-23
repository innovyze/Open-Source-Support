# Import the 'date' library
require 'date'

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

# Define the result field name
res_field_name = 'DEPNOD'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Nodes for Node Level"
puts ";         Day      Time  DEPNOD"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end