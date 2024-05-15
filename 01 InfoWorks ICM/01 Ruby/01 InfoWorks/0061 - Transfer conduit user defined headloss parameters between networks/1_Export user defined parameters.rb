require 'csv'

# Sets the current directory to a user-defined location
Dir.chdir 'D:/'

# Access the currently open network in the application
cn = WSApplication.current_network

# Begin a transaction
cn.transaction_begin

# Prepare an array to hold the data
data = []

# Access and iterate over all row_objects in the 'hw_conduit_defaults' table
cn.row_objects('hw_conduit_defaults').each do |ro|
    # Add the row data to the array
    data << [ro.us_headloss_type, ro.us_headloss_coeff, ro.ds_headloss_type, ro.ds_headloss_coeff]
end

# Commit the transaction
cn.transaction_commit

# Write the data to a CSV file
CSV.open("conduit_defaults.csv", "wb") do |csv|
    # Add the header row
    csv << ["us_headloss_type", "us_headloss_coeff", "ds_headloss_type", "ds_headloss_coeff"]

    # Add the data rows
    data.each do |row|
        csv << row
    end
end

# Print a confirmation message
puts "Data has been written to conduit_defaults.csv in the D:/ directory. You can now import this file into another model network."