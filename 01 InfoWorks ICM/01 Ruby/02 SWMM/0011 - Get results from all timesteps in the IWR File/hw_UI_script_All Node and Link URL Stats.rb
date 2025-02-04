# Define the result fields for the HW_NODE table
hw_node_fields = ["depnod", "flood_level", "flooddepth", "floodvolume", "flvol", "max_depnod",
 "max_flooddepth", "max_floodvolume", "max_flvol", "max_qinfnod", "max_qnode", "max_qrain", 
 "qincum", "qinfnod", "qnode", "qrain", "vflood", "vground", "max_volume", "volbal", "volume", "pcvolbal"]

# Define the result fields for the HW_CONDUIT table
hw_conduit_fields = ["height", "HYDGRAD", "length", "max_qinflnk", "max_qlink", "max_Surcharge",
 "max_us_depth", "max_us_flow", "max_us_froude", "max_us_totalhead", "max_us_vel", "maxsurchargestate", 
 "pfc", "qinflnk", "qlicum", "qlink", "Surcharge", "type", "us_depth", "us_flow", "us_froude", "us_invert", 
 "us_qcum", "us_totalhead", "us_vel", "volume", "ds_depth", "ds_flow", "ds_froude", "ds_invert", "ds_qcum", 
 "ds_totalhead", "ds_vel", "max_ds_depth", "max_ds_flow", "max_ds_froude", "max_ds_totalhead", "max_ds_vel"]

 # Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

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
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
