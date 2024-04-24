require 'csv'

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'us_invert',
		'ds_invert',
    'conduit_length',
    'conduit_height',
    'conduit_width',
    'number_of_barrels',
    'bottom_roughness_N',
    'top_roughness_N',
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
  
  # Define the data fields
  data_fields = ["ID", "FROM_INV", "TO_INV", "LENGTH", "DIAMETER", "COEFF", "PARALLEL"]

  open_net.clear_selection
  puts "Reading Scenario : #{open_net.current_scenario}"
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('hw_conduit').each do |ro|
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

def import_pipe_hydraulics(open_net)    
  # Define the configuration and CSV file paths
  val=WSApplication.prompt "Pipe Hydraulics for an InfoSewer Scenario",
  [
  ['Pick the Scenario Name that Matches the InfoSewer Dataset ','String',nil,nil,'FOLDER','Pipe Folder']
  ],false
    # Exit the program if the user cancelled the prompt
    return  if val.nil?
  csv  = val[0] + "\\pipehyd.csv"
  puts csv

  # Initialize an empty array to hold the hashes
  rows = []

  # Open and read the CSV file
  CSV.foreach(csv, headers: true).with_index do |row, index|

    # Add the row to the array as a hash
    rows << {
      "ID" => row[0],
      "FROM_INV" => row[1],
      "TO_INV" => row[2],
      "LENGTH" => row[3],
      "DIAMETER" => row[4],
      "COEFF" => row[5],
      "PARALLEL" => row[6]
    }
  end

  # Print the rows
  rows.each do |row|
    open_net.row_objects('hw_conduit').each do |ro|
      if ro.asset_id == row["ID"] then
        ro.user_number_1 = row["FROM_INV"]
        ro.user_number_2 = row["TO_INV"]
        ro.user_number_3 = row["LENGTH"]
        ro.user_number_4 = row["DIAMETER"]
        ro.user_number_5 = row["COEFF"]
        ro.user_number_6 = row["PARALLEL"]
        if ro.user_number_6 == 0 then ro.user_number_6 = 1 end
        ro.us_invert =row["FROM_INV"]
        ro.ds_invert =row["TO_INV"]
        ro.conduit_length = row["LENGTH"]
        roconduit_height = row["DIAMETER"]
        ro.bottom_roughness_N = row["COEFF"]
        ro.top_roughness_N = row["COEFF"]
        ro.number_of_barrels = ro.user_number_6
        ro.write
        break
      end
    end
  end
end

# Access the current open network in the application
open_net = WSApplication.current_network

open_net.scenarios do |scenario|
  open_net.current_scenario = scenario
  text = WSApplication.message_box("Scenario #{open_net.current_scenario} to Import", 'OK', 'Information', nil)
    puts "Importing for Scenario #{open_net.current_scenario}"
    open_net.transaction_begin
    import_pipe_hydraulics(open_net)
    open_net.transaction_commit
    # Call the print_csv_inflows_file method
    print_csv_inflows_file(open_net)
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
