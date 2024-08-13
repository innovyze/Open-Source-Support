require 'csv'

# Method to print statistics
def print_statistics(open_net)
  # Define the import fields
  database_fields = [
    'discharge'
  ]

  # Clear any current selection in the open network
  open_net.clear_selection

  # Prepare a hash to store data for each field in database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Collect data for each field from hw_pump
  open_net.row_objects('hw_pump').each do |ro|
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end

  # Print statistical data for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      puts "#{field} contains no data"
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

    # Print statistical information
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n",
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

# Method to import pump hydraulics from a CSV file
def import_pump_hydraulics(open_net, csv_path)
  # Check if the file exists
  unless File.exist?(csv_path)
    puts "Error: The file at path '#{csv_path}' does not exist."
    return
  end

  # Initialize an empty hash to hold the CSV rows as hashes
  rows = {}

  # Open and read the CSV file
  CSV.foreach(csv_path, headers: true) do |row|
    row_hash = {
      "ID" => row["ID"],
      "TYPE" => row["TYPE"],
      "PARALLEL" => row["PARALLEL"],
      "CAPACITY" => row["CAPACITY"],
      "SHUT_HEAD" => row["SHUT_HEAD"],
      "DSGN_HEAD" => row["DSGN_HEAD"],
      "DSGN_FLOW" => row["DSGN_FLOW"],
      "HIGH_HEAD" => row["HIGH_HEAD"],
      "HIGH_FLOW" => row["HIGH_FLOW"]
    }
    rows[row_hash["ID"].strip.downcase] = row_hash
  end

  # Update hw_pump objects
  open_net.row_objects('hw_pump').each do |ro|
    row = rows[ro.asset_id.strip.downcase]
    next unless row

    ro.discharge = row["CAPACITY"]
    ro.user_number_1 = row["CAPACITY"]
    ro.user_number_2 = row["SHUT_HEAD"]
    ro.user_number_3 = row["DSGN_HEAD"]
    ro.user_number_4 = row["DSGN_FLOW"]
    ro.user_number_5 = row["HIGH_HEAD"]
    ro.user_number_6 = row["HIGH_FLOW"]
    ro.user_text_10 = 'Pump'

    ro.write
  end
end

# Method to resolve the pump set for a given scenario
def resolve_pump_set(scenario_id, scenario_data)
  current_scenario = scenario_data[scenario_id]
  return "BASE" unless current_scenario # Default to "BASE" if scenario is not found

  pump_set = current_scenario["PUMP_SET"].to_s.strip
  parent_scenario = current_scenario["PARENT"].to_s.strip

  # Traverse up the parent chain if PUMP_SET is blank
  while pump_set.empty? && !parent_scenario.empty?
    parent_data = scenario_data[parent_scenario]
    break unless parent_data

    pump_set = parent_data["PUMP_SET"].to_s.strip
    parent_scenario = parent_data["PARENT"].to_s.strip
  end

  pump_set = "BASE" if pump_set.empty?
  pump_set
end

# Prompt for the IEDB folder location
val = WSApplication.prompt("Please enter the path to the main IEDB folder:", [['IEDB Folder Path', 'String', nil, nil, 'FOLDER', 'IEDB Folder']], false)
return if val.nil? # Exit if the user cancels the prompt

iedb_folder_path = val[0]

# Check if the provided folder path is valid
unless Dir.exists?(iedb_folder_path)
  puts "Error: The provided folder path '#{iedb_folder_path}' does not exist."
  return
end

# Read the SCENARIO.CSV file and create a hash for scenario paths
scenario_csv_path = File.join(iedb_folder_path, "SCENARIO.CSV")

# Check if the SCENARIO.CSV file exists
unless File.exist?(scenario_csv_path)
  puts "Error: The SCENARIO.CSV file at path '#{scenario_csv_path}' does not exist."
  return
end

scenario_data = {}
CSV.foreach(scenario_csv_path, headers: true) do |row|
  scenario_id = row["ID"]
  scenario_data[scenario_id] = row
end

scenario_paths = {}
pump_sets = {}

# Create paths for each scenario
scenario_data.each do |scenario_id, data|
  # Handle the specific case where 'BASE' in InfoSewer corresponds to 'Base' in ICM
  scenario_id = 'Base' if scenario_id == 'BASE'

  pump_set = resolve_pump_set(scenario_id, scenario_data)
  scenario_paths[scenario_id] = File.join(iedb_folder_path, "Pump", pump_set, "PUMPHYD.CSV")
  pump_sets[scenario_id] = pump_set
end

# Access the current open network in the application
open_net = WSApplication.current_network

# Iterate through each scenario in the network
open_net.scenarios do |scenario|
  open_net.current_scenario = scenario
  scenario_id = open_net.current_scenario

  # Handle the specific case where 'BASE' in InfoSewer corresponds to 'Base' in ICM
  scenario_id = 'Base' if scenario_id == 'BASE'

  csv_path = scenario_paths[scenario_id]
  pump_set = pump_sets[scenario_id]

  # Check if the csv_path is valid
  if csv_path.nil? || !File.exist?(csv_path)
    puts "\nWarning: No valid PUMPHYD.CSV file path for scenario '#{scenario_id}'. Skipping..."
    next
  end

  puts "\nImporting PUMPHYD to scenario '#{scenario_id}' from InfoSewer Pump Set '#{pump_set}'"
  open_net.transaction_begin
  begin
  import_pump_hydraulics(open_net, csv_path)
  open_net.transaction_commit
  rescue => e
    open_net.transaction_rollback
    puts "Error importing pump hydraulic data for scenario '#{scenario_id}': #{e.message}"
  end

  # Call the method to print statistics
  print_statistics(open_net)
end

# Indicate the completion of the import process
puts "\n
User numbers were assigned values from InfoSewer fields as follows:
  user_number_1 = CAPACITY
  user_number_2 = SHUT_HEAD
  user_number_3 = DSGN_HEAD
  user_number_4 = DSGN_FLOW
  user_number_5 = HIGH_HEAD
  user_number_6 = HIGH_FLOW"
puts "\nFinished import of InfoSewer PUMPHYD scenario data to InfoWorks ICM"