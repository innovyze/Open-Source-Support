# Import required libraries
require 'CSV'
require 'date'

# Get the current network
on = WSApplication.current_network

# Record the start time
start_time = Time.now

# Begin a transaction on the network
on.transaction_begin

# Initialize a counter for the number of reset SUDS controls
reset_count = 0

# Iterate over each subcatchment in the network
on.row_objects('_subcatchments').each do |ro|
  # If the subcatchment has any SUDS controls, reset them
  if ro.suds_controls.size > 0
    ro.suds_controls.size = 0
    ro.suds_controls.write
    ro.write
    # Increment the reset counter
    reset_count += 1
  end
end

# Commit the transaction
on.transaction_commit

# Output the number of reset SUDS controls
puts "Number of reset SUDS controls: #{reset_count}"