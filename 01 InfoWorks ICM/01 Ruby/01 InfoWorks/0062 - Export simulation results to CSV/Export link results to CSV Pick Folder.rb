require 'date'
require 'csv'

# Options
TIME_FORMAT = "%F %T"  # The format for time: 'YYYY-MM-DD HH:MM:SS'
PRECISION = 3  # The number of decimal places for the result values
TABLE = '_links'  # The table from which the row objects will be selected
FIELDS = ['us_flow', 'ds_flow', 'us_depth', 'ds_depth', 'us_froude', 'ds_froude', 'us_totalhead', 'ds_totalhead', 'us_vel', 'ds_vel']

start_time=Time.now

# Access the currently open network in the application
cn = WSApplication.current_network
# Get the name of the network
network_name = cn.network_model_object.name

    # Check each row object in the current table
    # Initialize an array to store the names of result fields
        results_array = []
        found_results = false
    cn.row_object_collection('HW_CONDUIT').each do |row_object|
      # Check if the row object has a 'results_fields' property and results have not been found yet
      if row_object.table_info.results_fields && !found_results
        # If yes, add the field names to the results_array
        row_object.table_info.results_fields.each do |field|
          results_array << field.name
        end
        found_results = true  # Set flag to true after finding the first set of results
        break  # Exit the loop after processing the first row with results
      end
    end

    # Print the table name and each of its result fields on a separate row only if there are result fields
    unless results_array.empty?
      puts "Table: HW_CONDUIT"
      results_array.each do |field|
        puts "Result field: #{field}"
      end
      puts
    end

# Prepare an array to hold the selected row objects
row_objects = cn.row_objects_selection(TABLE)

# Check if any row objects have been selected
if row_objects.empty?
  puts "Oops! It looks like you haven't selected any row objects in the '#{TABLE}' table." 
  puts "Please select some rows and try running this script again. Thanks!"
  return
end

# Get the timesteps for the network
timesteps = cn.list_timesteps

# Check if the simulation starts at time 0 or a real date
starts_at_zero = if timesteps[0].is_a?(Numeric)
                   timesteps[0] == 0
                 elsif timesteps[0].is_a?(DateTime)
                   timesteps[0] == DateTime.new(0)
                 end
# Prompt the user to pick a folder instead of hardcoding the path                       
val = WSApplication.prompt "Destination Folder for the CSV File",
[
  ['Pick the Folder','String',nil,nil,'FOLDER','Folder'],
    ['This script exports the results of a HW simulation from', 'String'],
    ['an InfoWorks network model to CSV files.', 'String'],
    ['The user is prompted to select a folder where the CSV', 'String'],
    ['files will be saved.', 'String'],
    ['The script then iterates over each field (e.g., us_flow,', 'String'],
    ['ds_flow, etc.) and each timestep, and writes the result', 'String'],
    ['values for each selected row object to the CSV file.', 'String'],
    ['Time Formatting: The script uses a specific time format', 'String'],
    ['(YYYY-MM-DD HH:MM:SS) for the output CSV files.', 'String'],
    ['Precision: The script formats the result values to a', 'String'],
    ['specified number of decimal places.', 'String'],
    ['Table Selection: The script retrieves row objects from a', 'String'],
    ['specified table or (_links).', 'String'],
    ['Field Selection: The script retrieves specific result', 'String'],
    ['fields (us_flow, ds_flow, us_depth, ds_depth) for each', 'String'],
    ['Row Object Selection: The script checks if any row', 'String'],
    ['objects have been selected in the specified table. If not,', 'String'],
    ['it provides a message to the user and exits.', 'String'],
    ['Timestep Handling: The script retrieves the timesteps for', 'String'],
    ['the network and checks if the simulation starts at time 0', 'String'],
    ['or a real date.', 'String'],
    ['CSV Construction: The script constructs the CSV content,', 'String'],
    ['starting with a header that includes the IDs of the selected', 'String'],
    ['row objects. It then iterates over each timestep and adds', 'String'],
    ['the result values for each object to the CSV content.', 'String']
], false
folder_path = val[0]

# Iterate over each field
FIELDS.each do |field|
  puts "Exporting data for field '#{field}'"
  # Start constructing the CSV content, beginning with the header
  output = "Time"

  # Add each object's ID to the CSV header
  row_objects.each { |object| output << ",#{object.id}" }

  # Finish the CSV header
  output << "\n"

  # Iterate over each timestep
  timesteps.each_with_index do |ts, i|
    if ts.is_a?(Numeric)
      if starts_at_zero
        # Determine the days, hours, minutes, and seconds from the absolute timestep
        ts = ts.abs
        days = ts / 86400
        hours = (ts % 86400) / 3600
        minutes = (ts % 3600) / 60
        seconds = ts % 60

        # Build the time string and add it to the CSV content
        output << sprintf("00/%02d/0000 %02d:%02d:%02d", days, hours, minutes, seconds)
      else
        # Convert the timestep to a date and time string, and add it to the CSV content
        output << Time.at(ts).utc.strftime(TIME_FORMAT)
      end
    elsif ts.is_a?(DateTime)
      if starts_at_zero
        output << "00/00/0000 00:00:00"
      else
        output << ts.strftime(TIME_FORMAT)
      end
    end

    # Iterate over each selected row object and add the result value for the current field and timestep to the CSV content
    row_objects.each { |object| output << ",#{object.results(field)[i].round(PRECISION)}" }

    # Finish the CSV row
    output << "\n"
  end

  # Use the selected folder when creating the file path
  file = "#{folder_path}/#{network_name}_#{field}.csv"
  puts file

  # Write the CSV content to the file
  File.write(file, output, mode: 'w')

  # Print a confirmation message
  puts "Data for field '#{field}' has been written to #{file}"
end

end_time=Time.now
net_time= end_time - start_time
puts
puts "Script Runtime: #{format('%.2f', net_time)} sec"