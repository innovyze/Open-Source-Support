require 'csv'

# Method to print statistical information for CSV inflows file
def print_csv_inflows_file(open_net)
  # Define the import fields
  database_fields = [
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

  # Clear any current selection in the open network
  open_net.clear_selection

  # Prepare a hash to store data for each field in database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Collect data for each field from hw_subcatchment
  open_net.row_objects('hw_subcatchment').each do |ro|
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
      "%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n",
      field, data.size, min_value, max_value, mean_value, standard_deviation, total_value
    )
  end
end

# Method to import node loads from a CSV file
def import_node_loads(open_net, csv_path)
  # Check if the file exists
  unless File.exist?(csv_path)
    puts "Error: The file at path '#{csv_path}' does not exist."
    return
  end

  # Initialize an empty hash to hold the CSV rows as hashes
  row_hash = {}

  # Open and read the CSV file
  begin
    CSV.foreach(csv_path, headers: true).with_index do |row, index|
      row_hash[row["ID"]] = {
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
    end
  rescue => e
    puts "Error reading CSV file: #{e.message}"
    return
  end

  # Create hashes for quick access to hw_node and hw_subcatchment objects
  node_hash = {}
  subcatchment_hash = {}

  open_net.row_objects('hw_node').each do |ro|
    node_hash[ro.node_id] = ro
  end

  open_net.row_objects('hw_subcatchment').each do |ro|
    subcatchment_hash[ro.node_id] = ro
  end

  # Update hw_node objects
  node_hash.each do |node_id, ro|
    row = row_hash[node_id]
    next unless row

    ro.user_number_1 = row["DIAMETER"]
    ro.user_number_2 = row["RIM_ELEV"]
    begin
      ro.write
    rescue => e
      puts "Error writing to hw_node for node_id #{node_id}: #{e.message}"
    end
  end

  # Update hw_subcatchment objects
  subcatchment_hash.each do |node_id, ro|
    row = row_hash[node_id]
    next unless row

    (1..10).each do |i|
      load_key = "LOAD#{i}"
      pattern_key = "PATTERN#{i}"
      user_number_key = "user_number_#{i}"
      user_text_key = "user_text_#{i}"

      ro.send("#{user_number_key}=", row[load_key])
      ro.send("#{user_text_key}=", row[pattern_key])
    end
    begin
      ro.write
    rescue => e
      puts "Error writing to hw_subcatchment for node_id #{node_id}: #{e.message}"
    end
  end
end

# Method to resolve the manhole set for a given scenario
def resolve_mh_set(scenario_id, scenario_data)
  current_scenario = scenario_data[scenario_id]
  return "BASE" unless current_scenario # Default to "BASE" if scenario is not found

  mh_set = current_scenario["MH_SET"].to_s.strip
  parent_scenario = current_scenario["PARENT"].to_s.strip

  # Traverse up the parent chain if MH_SET is blank
  while mh_set.empty? && !parent_scenario.empty?
    parent_data = scenario_data[parent_scenario]
    break unless parent_data

    mh_set = parent_data["MH_SET"].to_s.strip
    parent_scenario = parent_data["PARENT"].to_s.strip
  end

  mh_set = "BASE" if mh_set.empty?
  mh_set
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
mh_sets = {}

# Create paths for each scenario
scenario_data.each do |scenario_id, data|
  # Handle the specific case where 'BASE' in InfoSewer corresponds to 'Base' in ICM
  scenario_id = 'Base' if scenario_id == 'BASE'

  mh_set = resolve_mh_set(scenario_id, scenario_data)
  scenario_paths[scenario_id] = File.join(iedb_folder_path, "Manhole", mh_set, "MHHYD.CSV")
  mh_sets[scenario_id] = mh_set
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
  mh_set = mh_sets[scenario_id]

  # Check if the csv_path is valid
  if csv_path.nil? || !File.exist?(csv_path)
    puts "
Warning: No valid MHHYD.CSV file path for scenario '#{scenario_id}'. Skipping..."
    next
  end

  puts "
Importing MHHYD to scenario '#{scenario_id}' from InfoSewer Manhole Set '#{mh_set}'"
  open_net.transaction_begin
  begin
    import_node_loads(open_net, csv_path)
    open_net.transaction_commit
  rescue => e
    open_net.transaction_rollback
    puts "Error importing node loads for scenario '#{scenario_id}': #{e.message}"
  end

  # Call the method to print CSV inflows file statistics
  print_csv_inflows_file(open_net)
end

# Indicate the completion of the import process
puts "
Finished import of InfoSewer MHHYD scenario data to InfoWorks ICM"