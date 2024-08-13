require 'csv'

# Method to print statistics
def print_statistics(open_net)
  # Define the import fields
  database_fields = [
    'user_text_1',
    'user_text_2',
    'user_text_3'
  ]

  # Clear any current selection in the open network
  open_net.clear_selection

  # Prepare a hash to store data for each field in database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Collect data for each field from hw_conduit
  open_net.row_objects('hw_conduit').each do |ro|
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
  end
end

# Method to import pipe splits from a CSV file
def import_pipe_splits(open_net, csv_path)
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
      "FIXED" => row["FIXED"],
      "CURVE" => row["CURVE"]
    }
    rows[row_hash["ID"].strip.downcase] = row_hash
  end

  # Update hw_conduit objects
  open_net.row_objects('hw_conduit').each do |ro|
    row = rows[ro.asset_id.strip.downcase]
    next unless row

    ro.user_text_1 = row["TYPE"]
    ro.user_text_2 = row["FIXED"]
    ro.user_text_3 = row["CURVE"]
    
    ro.write
  end
end

# Method to resolve the pipe split set for a given scenario
def resolve_split_set(scenario_id, scenario_data)
  current_scenario = scenario_data[scenario_id]
  return "BASE" unless current_scenario # Default to "BASE" if scenario is not found

  split_set = current_scenario["PISLT_SET"].to_s.strip
  parent_scenario = current_scenario["PARENT"].to_s.strip

  # Traverse up the parent chain if _SET is blank
  while split_set.empty? && !parent_scenario.empty?
    parent_data = scenario_data[parent_scenario]
    break unless parent_data

    split_set = parent_data["PISLT_SET"].to_s.strip
    parent_scenario = parent_data["PARENT"].to_s.strip
  end

  split_set = "BASE" if split_set.empty?
  split_set
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
split_sets = {}

# Create paths for each scenario
scenario_data.each do |scenario_id, data|
  # Handle the specific case where 'BASE' in InfoSewer corresponds to 'Base' in ICM
  scenario_id = 'Base' if scenario_id == 'BASE'

  split_set = resolve_split_set(scenario_id, scenario_data)
  scenario_paths[scenario_id] = File.join(iedb_folder_path, "Split", split_set, "PIPESPLT.CSV")
  split_sets[scenario_id] = split_set
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
  split_set = split_sets[scenario_id]

  # Check if the csv_path is valid
  if csv_path.nil? || !File.exist?(csv_path)
    puts "\nWarning: No valid PIPEHYD.CSV file path for scenario '#{scenario_id}'. Skipping..."
    next
  end

  puts "\nImporting PIPESPLT to scenario '#{scenario_id}' from InfoSewer Split Set '#{split_set}'"
  open_net.transaction_begin
  begin
  import_pipe_splits(open_net, csv_path)
  open_net.transaction_commit
  rescue => e
    open_net.transaction_rollback
    puts "Error importing pipe split data for scenario '#{scenario_id}': #{e.message}"
  end
end

# Indicate the completion of the import process
puts "\nFinished import of InfoSewer PIPESPLT scenario data to InfoWorks ICM"