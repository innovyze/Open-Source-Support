require 'csv'

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for InfoWorks network nodes
  database_fields = [
    'ground_level',
		'flood_level',
    'chamber_area',
    'shaft_area',
    'user_number_1',
    'user_number_2',
    'user_number_3',
    'user_number_4',
    'user_number_5',
    'user_number_6',
    'user_number_7',
    'user_number_8',
    'user_number_9',
    'user_number_10'
  ]

  open_net.clear_selection
  puts "Scenario     : #{open_net.current_scenario}"
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('hw_node').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end
  
  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      #puts "#{field} has no data!"
      next
    end

    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum
  
    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end


def import_node_loads(open_net)
  # Define the configuration and CSV file paths
  val = WSApplication.prompt "Manhole Loads for an InfoSewer Scenario", [
    ['Pick the Scenario Name that Matches the InfoSewer Dataset ', 'String', nil, nil, 'FOLDER', 'Manhole Folder']
  ], false

  # Exit the program if the user cancelled the prompt
  return if val.nil?

  csv = val[0] + "\\mhhyd.csv"
  puts csv

  # Initialize a hash to hold the rows
  rows = {}

  # Open and read the CSV file
  CSV.foreach(csv, headers: true) do |row|
    row_hash = {
      "ID" => row[0],
      "DIAMETER" => row[1],
      "RIM_ELEV" => row[2],
      "LOAD1" => row[4],
      "PATTERN1" => row[6],
      "LOAD2" => row[8],
      "PATTERN2" => row[10],
      "LOAD3" => row[12],
      "PATTERN3" => row[14],
      "LOAD4" => row[16],
      "PATTERN4" => row[18],
      "LOAD5" => row[20],
      "PATTERN5" => row[22],
      "LOAD6" => row[24],
      "PATTERN6" => row[26],
      "LOAD7" => row[28],
      "PATTERN7" => row[30],
      "LOAD8" => row[32],
      "PATTERN8" => row[34],
      "LOAD9" => row[36],
      "PATTERN9" => row[38],
      "LOAD10" => row[40],
      "PATTERN10" => row[42]
    }
    rows[row_hash["ID"].strip.downcase] = row_hash
  end

  # Save the rows to the nodes
  open_net.row_objects('hw_node').each do |ro|
    row = rows[ro.node_id.strip.downcase]
    next unless row

    ro.user_number_1 = row["DIAMETER"]
    ro.shaft_area = row["DIAMETER"]
    ro.chamber_area = row["DIAMETER"]
    ro.user_number_2 = row["RIM_ELEV"]
    ro.ground_level = row["RIM_ELEV"]
    ro.write
  end

  # Save the rows to the subcatchments
  open_net.row_objects('hw_subcatchment').each do |ro|
    row = rows[ro.subcatchment_id.strip.downcase]
    next unless row

    ro.system_type = 'Sanitary'
    ro.user_number_1 = row["LOAD1"]
    ro.user_number_2 = row["LOAD2"]
    ro.user_number_3 = row["LOAD3"]
    ro.user_number_4 = row["LOAD4"]
    ro.user_number_5 = row["LOAD5"]
    ro.user_number_6 = row["LOAD6"]
    ro.user_number_7 = row["LOAD7"]
    ro.user_number_8 = row["LOAD8"]
    ro.user_number_9 = row["LOAD9"]
    ro.user_number_10 = row["LOAD10"]
    ro.user_text_1 = row["PATTERN1"]
    ro.user_text_2 = row["PATTERN2"]
    ro.user_text_3 = row["PATTERN3"]
    ro.user_text_4 = row["PATTERN4"]
    ro.user_text_5 = row["PATTERN5"]
    ro.user_text_6 = row["PATTERN6"]
    ro.user_text_7 = row["PATTERN7"]
    ro.user_text_8 = row["PATTERN8"]
    ro.user_text_9 = row["PATTERN9"]
    ro.user_text_10 = row["PATTERN10"]
    ro.write
  end
end

#========================================================================
# Access the current open network in the application
open_net = WSApplication.current_network

open_net.transaction_begin
import_node_loads(open_net)
open_net.transaction_commit

# Call the print_csv_inflows_file method
print_csv_inflows_file(open_net)

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
