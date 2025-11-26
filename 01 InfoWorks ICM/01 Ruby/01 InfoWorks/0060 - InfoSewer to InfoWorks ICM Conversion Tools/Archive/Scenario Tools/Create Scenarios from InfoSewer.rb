require 'csv'
require 'pathname'

# Define the method to import scenarios
def import_scenarios(current_network)
  # Prompt the user to select the folder containing the CSV files
  folder_selection = WSApplication.prompt "Import InfoSewer Scenario Names from CSVs", [['Select the IEDB Folder', 'String', nil, nil, 'FOLDER', 'IEDB Folder']], false

  # Check if the user clicked 'Cancel' or didn't provide a folder path
  if folder_selection.nil? || folder_selection.empty?
    WSApplication.message_box("Import process was canceled. No scenarios were created. Script canceled.", "OK", "!", false)
    return
  end

  folder_path = folder_selection[0]
  puts "Selected folder path: #{folder_path}"

  # Validate the provided folder path
  if folder_path.nil? || folder_path.empty?
    WSApplication.message_box("Invalid folder path provided. Script canceled.", "OK", "!", false)
    return
  end

  # Define the path to the scenario CSV file
  scenario_csv_path = "#{folder_path}/Scenario.csv"
  puts "Scenario CSV file path: #{scenario_csv_path}"

  # Check if the scenario CSV file exists
  unless File.exist?(scenario_csv_path)
    WSApplication.message_box("Scenario.csv not found in the provided folder. Script canceled.", "OK", "!", false)
    return
  end

  # Initialize an array to hold the rows from the CSV file
  csv_rows = []

  # Define the headers to exclude when reading the CSV file
  exclude_headers = ["FAC_TYPE", "USECLIMATE", "USE_TIME", "USE_REPORT", "USE_OPTION"]

  # Open and read the CSV file
  CSV.foreach(scenario_csv_path, headers: true) do |row|
    # Add the row data to the csv_rows array, excluding specified headers
    row_data = row.headers.reject { |header| exclude_headers.include?(header) || row[header].nil? }
                          .map { |header| "#{header}: #{row[header]}" }
                          .join(", ")
    csv_rows << row.to_h
  end

  # Extract the scenario names in their original order, excluding BASE
  scenario_names = csv_rows.map { |row| row['ID'] }.reject { |name| name.upcase == 'BASE' }

  # Alphabetize the scenario names
  scenario_names.sort!

  # Prompt the user to select scenarios they wish to import, including 'Select All' option
  scenario_names_with_options = [["Select all", 'Boolean']] + scenario_names.map { |name| [name, 'Boolean'] }

  puts "\nInfoSewer scenarios:"
  scenario_names.each { |name| puts "- #{name}" }

  selected_scenarios_prompt = WSApplication.prompt("Select scenarios to create", scenario_names_with_options, true)

  # Handle cases where the prompt result might be nil or the user clicked 'Cancel'
  if selected_scenarios_prompt.nil? || selected_scenarios_prompt.empty?
    WSApplication.message_box("Scenario selection was canceled. No scenarios were created.", "OK", "!", false)
    return
  end

  # Extract the 'Select All' option
  select_all = selected_scenarios_prompt[0] == true

  # Select all scenarios if 'Select All' is chosen
  selected_scenarios_prompt = scenario_names_with_options.map.with_index { | _, i | i == 0 ? false : select_all } if select_all

  # Extract indices of selected scenarios
  selected_indices = selected_scenarios_prompt.each_index.select { |i| i > 0 && selected_scenarios_prompt[i] == true }

  # Map selected indices to scenario names
  selected_scenarios = selected_indices.map { |i| scenario_names[i - 1] } # Adjust index to consider "Select All"

  puts "\nSelected scenarios:"
  selected_scenarios.each { |scenario| puts "- #{scenario}" }

  # Collect existing scenarios into an array
  existing_scenario_names = []
  current_network.scenarios do |scenario|
    existing_scenario_names << scenario
  end

  # Check for name conflicts with existing scenarios
  conflicting_scenarios = selected_scenarios & existing_scenario_names

  if conflicting_scenarios.any?
    user_choice = WSApplication.message_box("Scenarios with the following names already exist in this network: #{conflicting_scenarios.join(', ')}. Do you want to delete all existing scenarios and proceed? Click 'Yes' to delete or 'No' to cancel the script.", "YesNo", "?", false)

    if user_choice != "Yes"
      WSApplication.message_box("No scenarios were created. Script canceled.", "OK", "!", false)
      return
    end

    # Delete all non-"Base" scenarios
    existing_scenario_names.each do |scenario|
      current_network.delete_scenario(scenario) unless scenario == 'Base'
    end
  end

  # Filter rows based on selected scenarios
  chosen_scenarios_rows = csv_rows.select { |row| selected_scenarios.include?(row['ID']) }

  # Return the filtered scenarios
  chosen_scenarios_rows
end

# Access the current network in the application
current_network = WSApplication.current_network

# Call the method to import scenarios
chosen_scenarios_rows = import_scenarios(current_network)

# If chosen_scenarios_rows is nil, exit the script gracefully
return if chosen_scenarios_rows.nil?

# Initialize a counter for the number of scenarios added
added_scenarios_count = 0

# Add the imported scenarios
chosen_scenarios_rows.each do |scenario|
  current_network.add_scenario(scenario['ID'], nil, scenario['DESCRIPT'])
  added_scenarios_count += 1
end

# Print the total number of scenarios added
puts "\nTotal scenarios added: #{added_scenarios_count}"
puts "\nNote: This script simply makes copies of the Base scenario and renames them to the corresponding InfoSewer scenario names. It does not import the scenario data from InfoSewer datasets."
