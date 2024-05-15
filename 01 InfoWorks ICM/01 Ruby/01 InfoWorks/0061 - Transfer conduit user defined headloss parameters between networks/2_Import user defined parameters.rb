require 'csv'

# Access the currently open network in the application
cn = WSApplication.current_network

# Begin a transaction
cn.transaction_begin

# Get the full path to the CSV file
csv_file = 'D:/conduit_defaults.csv'

# Open the CSV file
CSV.foreach(csv_file, headers: true) do |row|
  # Access the 'hw_conduit_defaults' table
  conduit_defaults = cn.row_objects('hw_conduit_defaults')

  # Update the fields with the values from the CSV row
  conduit_defaults.each do |ro|
    ro.us_headloss_type = row['us_headloss_type']
    ro.us_headloss_coeff = row['us_headloss_coeff']
    ro.ds_headloss_type = row['ds_headloss_type']
    ro.ds_headloss_coeff = row['ds_headloss_coeff']
    ro.write
  end
end

# Commit the transaction
cn.transaction_commit

# Print a confirmation message
puts "Data from D:/conduit_defaults.csv has been imported into the 'hw_conduit_defaults' table."