# Require necessary libraries
require 'csv'
require 'pathname'

# Define the method to import scenarios
def import_scenario(open_net)
  # Prompt the user to select a folder
  val = WSApplication.prompt "Import InfoSewer or InfoSWMM Scenarios", [['Select the IEDB or ISDB Folder','String',nil,nil,'FOLDER','IEDB or ISDB Folder']], false
  folder_path = val[0]
  # Print the selected folder path
  puts "Folder path: #{folder_path}"

  # If no folder path is given, exit the method
  return unless folder_path

  # Initialize an array to hold the rows from the CSV file
  rows = []

  # Define the path to the scenario CSV file
  scenario_csv = "#{folder_path}/scenario.csv"
  puts "\nScenario CSV: #{scenario_csv}"

  # Define the headers to exclude when reading the CSV file
  exclude_headers = ["FAC_TYPE", "USECLIMATE", "USE_REPORT", "USE_OPTION","PISLT_SET"]

  # Open and read the CSV file
  CSV.open(scenario_csv, 'r', headers: true) do |csv|
    # Process each row in the CSV file
    csv.each do |row|
      # Initialize a string to hold the row data
      row_string = ""
      # Process each header in the row
      row.headers.each do |header|
        # If the header is not in the exclude list, add its data to the string
        unless row[header].nil? || exclude_headers.include?(header)
          row_string += sprintf("%s: %s, ", header, row[header])
        end
      end
      # Print the row data
      puts row_string

      # Add the row data to the rows array as a hash
      rows << row.to_h
    end
  end

  # Prompt the user to optionally enter a custom order for the scenarios
  val = WSApplication.prompt("OPTIONAL: Customize Scenario Order (comma-separated)", [['Enter the IDs of the scenarios in the desired order', 'String']], false)

  # Check if the user has entered a custom order
  if val[0].nil? || val[0].strip.empty?
    # If not, keep the scenarios in their original order
    sorted_rows = rows
  else
    # If so, split the user's input into an array of IDs
    order = val[0].split(',').map(&:strip)

    # Sort the scenarios based on the user's order
    sorted_rows = rows.sort_by { |row| order.index(row['ID']) || Float::INFINITY }
  end

  # Return the sorted scenarios
  return sorted_rows
end

# Access the current network in the application
open_net = WSApplication.current_network

# Call the method to import scenarios
sorted_rows = import_scenario(open_net)

# Initialize a counter for the number of scenarios added
added_scenarios_count = 0

# Delete all existing scenarios except 'Base'
open_net.scenarios do |scenario|
 if scenario != 'Base'
  open_net.delete_scenario(scenario)
 end
end

# Print that all existing scenarios have been deleted
puts "\nAll existing scenarios deleted"
puts "\n"

# Add the imported scenarios
puts "Added scenarios in the following order:"
sorted_rows.each do |scenario|
  # Skip the 'Base' scenario
  if scenario['ID'] != 'BASE'
    # Print the ID of the scenario being added
    puts "#{scenario['ID']}"
    # Add the scenario
    open_net.add_scenario(scenario['ID'],nil,'')
    # Increment the counter for the number of scenarios added
    added_scenarios_count += 1
  end
end

# Print the total number of scenarios added
puts "\nTotal scenarios added: #{added_scenarios_count}"