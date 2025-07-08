require 'csv'

# Method to print statistics
def print_statistics(open_net)
  # Define the import fields
  database_fields = [
    'chamber_floor',
    'ground_level',
    'shaft_area',
    'chamber_area'
  ]

  # Clear any current selection in the open network
  open_net.clear_selection

  # Prepare a hash to store data for each field in database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Collect data for each field from hw_node
  open_net.row_objects('hw_node').each do |ro|
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
    printf(
      "%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f\n",
      field, data.size, min_value, max_value)
  end
end

# Method to import wetwell hydraulics from a CSV file
def import_ww_hydraulics(open_net, csv_path)
  # Check if the file exists
  unless File.exist?(csv_path)
    puts "Error: The file at path '#{csv_path}' does not exist."
    return
  end

  # Initialize an empty hash to hold the CSV rows as hashes
  row_hash = {}
  rows = {}

  # Open and read the CSV file
  CSV.foreach(csv_path, headers: true) do |row|
    row_hash = {
      "ID" => row["ID"],
      "TYPE" => row["TYPE"],
      "BTM_ELEV" => row["BTM_ELEV"],
      "HEADLOSS" => row["HEADLOSS"],
      "MIN_LEVEL" => row["MIN_LEVEL"],
      "MAX_LEVEL" => row["MAX_LEVEL"],
      "INIT_LEVEL" => row["INIT_LEVEL"],
      "DIAMETER" => row["DIAMETER"],
      "CURVE" => row["CURVE"]
    }
    rows[row_hash["ID"].strip.downcase] = row_hash
  end

  # Create hashes for quick access to hw_node objects
  node_hash = {}
 
  open_net.row_objects('hw_node').each do |ro|
    node_hash[ro.node_id] = ro
  end

  # Update hw_node objects
  node_hash.each do |node_id, ro|
    row = row_hash[node_id]
    next unless row

    ro.chamber_floor = row["BTM_ELEV"]
    ro.ground_level = row["MAX_LEVEL"] + row["BTM_ELEV"] # Calculation
    ro.shaft_area = row["DIAMETER"] * row["DIAMETER"] * 3.14159 / 4 # Calculation of area
    ro.chamber_area = row["DIAMETER"] * row["DIAMETER"] * 3.14159 / 4 # Calculation of area
    ro.user_number_1 = row["DIAMETER"]
    ro.user_number_2 = row["BTM_ELEV"]
    ro.user_number_3 = row["MIN_LEVEL"]
    ro.user_number_4 = row["MAX_LEVEL"]
    ro.user_number_5 = row["INIT_LEVEL"]
    ro.user_text_10 = 'WW'
    begin
      ro.write
    rescue => e
      puts "Error writing to hw_node for node_id #{node_id}: #{e.message}"
    end
  end
end

# Method to resolve the wetwell set for a given scenario
def resolve_well_set(scenario_id, scenario_data)
  current_scenario = scenario_data[scenario_id]
  return "BASE" unless current_scenario # Default to "BASE" if scenario is not found

  well_set = current_scenario["WELL_SET"].to_s.strip
  parent_scenario = current_scenario["PARENT"].to_s.strip

  # Traverse up the parent chain if WELL_SET is blank
  while well_set.empty? && !parent_scenario.empty?
    parent_data = scenario_data[parent_scenario]
    break unless parent_data

    well_set = parent_data["WELL_SET"].to_s.strip
    parent_scenario = parent_data["PARENT"].to_s.strip
  end

  well_set = "BASE" if well_set.empty?
  well_set
end

# Prompt for the IEDB folder location
val = WSApplication.prompt("Please enter the path to the main IEDB folder:", [['IEDB Folder Path', 'String', nil, nil, 'FOLDER','IEDB Folder']], false)
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
begin
  CSV.foreach(scenario_csv_path, headers: true) do |row|
    scenario_id = row["ID"]
    scenario_data[scenario_id] = row
  end
rescue => e
  puts "Error reading SCENARIO.CSV file: #{e.message}"
  return
end

scenario_paths = {}
well_sets = {}

# Create paths for each scenario
scenario_data.each do |scenario_id, data|
  # Handle the specific case where 'BASE' in InfoSewer corresponds to 'Base' in ICM
  scenario_id = 'Base' if scenario_id == 'BASE'

  well_set = resolve_well_set(scenario_id, scenario_data)
  scenario_paths[scenario_id] = File.join(iedb_folder_path, "Wetwell", well_set, "WWELLHYD.CSV")
  well_sets[scenario_id] = well_set
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
  well_set = well_sets[scenario_id]

  # Check if the csv_path is valid
  if csv_path.nil? || !File.exist?(csv_path)
    puts "
Warning: No valid WWELLHYD.CSV file path for scenario '#{scenario_id}'. Skipping..."
    next
  end

  puts "
Importing WWELLHYD to scenario '#{scenario_id}' from InfoSewer Wetwell Set '#{well_set}'"
  open_net.transaction_begin
  begin
    import_ww_hydraulics(open_net, csv_path)
    open_net.transaction_commit
  rescue => e
    open_net.transaction_rollback
    puts "Error importing wetwell data for scenario '#{scenario_id}': #{e.message}"
  end

  # Call the method to print statistics
  print_statistics(open_net)
end

# Indicate the completion of the import process
puts "
Finished import of InfoSewer WWELLHYD scenario data to InfoWorks ICM"