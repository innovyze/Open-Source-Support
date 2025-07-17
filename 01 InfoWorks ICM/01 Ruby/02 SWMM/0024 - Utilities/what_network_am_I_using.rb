# Get the current active network from the application
net = WSApplication.current_network

# Define the default message
result_message = "Could not determine the network type. The network may be empty."

# Check if the network object is valid before proceeding
if net
  # Get the list of all data table names in the network
  table_names = net.table_names

  # Iterate through each table name to find a characteristic prefix
  table_names.each do |name|
    if name.start_with?('hw_')
      result_message = "This is an InfoWorks Network."
      break # Stop searching once an InfoWorks table is found
    elsif name.start_with?('sw_')
      result_message = "This is a SWMM Network."
      break # Stop searching once a SWMM table is found
    end
  end
else
  result_message = "No network is currently open."
end
#
# Display the final result to the user in a prompt (message box)
#
#
WSApplication.message_box(result_message, 'OK', 'Information', nil)
