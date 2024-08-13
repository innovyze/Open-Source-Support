require 'csv'

# Method to print statistics
def print_statistics(open_net)
  # Define the import fields
  database_fields = [
    'us_invert',
    'ds_invert',
    'conduit_length',
    'conduit_height',
    'conduit_width',
    'number_of_barrels',
    'bottom_roughness_N',
    'top_roughness_N',
    'bottom_roughness_HW',
    'top_roughness_HW'
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

# Method to import pipe hydraulics from a CSV file
def import_pipe_hydraulics(open_net, csv_path)
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
      "FROM_INV" => row["FROM_INV"],
      "TO_INV" => row["TO_INV"],
      "LENGTH" => row["LENGTH"],
      "DIAMETER" => row["DIAMETER"],
      "COEFF" => row["COEFF"],
      "PARALLEL" => row["PARALLEL"]
    }
    rows[row_hash["ID"].strip.downcase] = row_hash
  end

  # Update hw_conduit objects
  open_net.row_objects('hw_conduit').each do |ro|
    row = rows[ro.asset_id.strip.downcase]
    next unless row

    ro.us_invert = row["FROM_INV"]
    ro.ds_invert = row["TO_INV"]
    ro.conduit_length = row["LENGTH"]
    ro.conduit_height = row["DIAMETER"]
    ro.conduit_width = row["DIAMETER"]
    ro.bottom_roughness_N = row["COEFF"]
    ro.top_roughness_N = row["COEFF"]
    ro.bottom_roughness_HW = row["COEFF"]
    ro.top_roughness_HW = row["COEFF"]
    ro.roughness_type = 'N' # This is an assumption, if forcemain solution used, type should be 'HW'
    ro.us_headloss_type = 'NONE' # Headloss is applied to manholes in InfoSewer
    ro.ds_headloss_type = 'NONE' # Headloss is applied to manholes in InfoSewer
    ro.us_headloss_coeff = 0
    ro.ds_headloss_coeff = 0
    ro.number_of_barrels = row["PARALLEL"].to_i.zero? ? 1 : row["PARALLEL"].to_i
    ro.user_text_10 = 'Pipe'

    ro.write
  end
end

# Method to resolve the pipe set for a given scenario
def resolve_pipe_set(scenario_id, scenario_data)
  current_scenario = scenario_data[scenario_id]
  return "BASE" unless current_scenario # Default to "BASE" if scenario is not found

  pipe_set = current_scenario["PIPE_SET"].to_s.strip
  parent_scenario = current_scenario["PARENT"].to_s.strip

  # Traverse up the parent chain if PIPE_SET is blank
  while pipe_set.empty? && !parent_scenario.empty?
    parent_data = scenario_data[parent_scenario]
    break unless parent_data

    pipe_set = parent_data["PIPE_SET"].to_s.strip
    parent_scenario = parent_data["PARENT"].to_s.strip
  end

  pipe_set = "BASE" if pipe_set.empty?
  pipe_set
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
pipe_sets = {}

# Create paths for each scenario
scenario_data.each do |scenario_id, data|
  # Handle the specific case where 'BASE' in InfoSewer corresponds to 'Base' in ICM
  scenario_id = 'Base' if scenario_id == 'BASE'

  pipe_set = resolve_pipe_set(scenario_id, scenario_data)
  scenario_paths[scenario_id] = File.join(iedb_folder_path, "Pipe", pipe_set, "PIPEHYD.CSV")
  pipe_sets[scenario_id] = pipe_set
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
  pipe_set = pipe_sets[scenario_id]

  # Check if the csv_path is valid
  if csv_path.nil? || !File.exist?(csv_path)
    puts "\nWarning: No valid PIPEHYD.CSV file path for scenario '#{scenario_id}'. Skipping..."
    next
  end

  puts "\nImporting PIPEHYD to scenario '#{scenario_id}' from InfoSewer Pipe Set '#{pipe_set}'"
  open_net.transaction_begin
  begin
  import_pipe_hydraulics(open_net, csv_path)
  open_net.transaction_commit
  rescue => e
    open_net.transaction_rollback
    puts "Error importing pump hydraulic data for scenario '#{scenario_id}': #{e.message}"
  end

  # Call the method to print CSV inflows file statistics
  print_statistics(open_net)
end

# Indicate the completion of the import process
puts "\nFinished import of InfoSewer PIPEHYD scenario data to InfoWorks ICM"