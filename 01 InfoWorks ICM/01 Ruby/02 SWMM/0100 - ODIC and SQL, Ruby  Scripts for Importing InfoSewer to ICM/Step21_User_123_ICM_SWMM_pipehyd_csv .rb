# Access the current open network in the application
open_net = WSApplication.current_network

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'us_invert',
		'ds_invert',
    'length',
    'conduit_height',
    'conduit_width',
    'number_of_barrels',
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
  puts "Version      : #{WSApplication.version}"
  puts "Units        : #{WSApplication.use_user_units}"
  puts "Database     : #{WSApplication.current_database}"
  puts "Network      : #{WSApplication.current_network}" 
  
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('Sw_conduit').each do |ro|
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

# Call the print_csv_inflows_file method
print_csv_inflows_file(open_net)

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\dickinre\Desktop\NLV_Model_2021_09_16_final\NLV_Model_2021_09_16_final\MPU_MODEL_UPDATE_20210916.IEDB\Pipe\PIPE2050-2'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Conduit', 'Step21_User_123_ICM_SWMM_pipehyd_csv.cfg', 'pipehyd.csv']
] 

import_steps.each do |layer, cfg_file, csv_file|
  begin
    open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
    puts "Imported #{layer} layer from #{cfg_file}"
  rescue StandardError => e
    puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
  end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM SWMM"

# Call the print_csv_inflows_file method again
print_csv_inflows_file(open_net)

