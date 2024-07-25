require 'date'

# Options
TIME_FORMAT = "%F %T"  # The format for time: 'YYYY-MM-DD HH:MM:SS'
PRECISION = 3  # The number of decimal places for the result values
TABLE = '_links'  # The table from which the row objects will be selected
FIELDS = ['us_flow', 'ds_flow', 'us_depth', 'ds_depth']  # The result fields to retrieve for each object

# Access the currently open network in the application
network = WSApplication.current_network
# Get the name of the network
network_name = network.network_model_object.name

# Prepare an array to hold the selected row objects
row_objects = network.row_objects_selection(TABLE)

# Check if any row objects have been selected
if row_objects.empty?
  puts "No row objects have been selected in the '#{TABLE}' table. Please make a selection before running this script."
  return
end

# Get the timesteps for the network
timesteps = network.list_timesteps

# Check if the simulation starts at time 0 or a real date
starts_at_zero = if timesteps[0].is_a?(Numeric)
                   timesteps[0] == 0
                 elsif timesteps[0].is_a?(DateTime)
                   timesteps[0] == DateTime.new(0)
                 end

# Iterate over each field
FIELDS.each do |field|
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

  # Create a file name based on the field and save to D:CSV/
  file = "D:/CSV/#{network_name}_#{field}.csv"

  # Write the CSV content to the file
  File.write(file, output, mode: 'w')

  # Print a confirmation message
  puts "Data for field '#{field}' has been written to #{file}"
end