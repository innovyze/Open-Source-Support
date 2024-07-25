require 'csv'

# Define the method to import scenarios
def import_scenario(open_net)
  # Prompt the user to select a folder
  val = WSApplication.prompt "Import InfoSewer or InfoSWMM Scenarios", [['Select the IEDB or ISDB Folder','String',nil,nil,'FOLDER','IEDB or ISDB Folder']], false
  folder_path = val[0]
  
  # Print the selected folder path
  puts "Folder path: #{folder_path}"

  # If no folder path is given, exit the method
  return [] unless folder_path

  # Define the path to the scenario CSV file
  scenario_csv = File.join(folder_path, "scenario.csv")
  puts "\nScenario CSV: #{scenario_csv}"

  # Define the headers to exclude when reading the CSV file
  exclude_headers = ["FAC_TYPE", "USECLIMATE", "USE_REPORT", "USE_OPTION", "PISLT_SET"]

  # Read and process the CSV file
  rows = CSV.read(scenario_csv, headers: true).map do |row|
    row_data = row.to_h.reject { |header, value| value.nil? || exclude_headers.include?(header) }
    puts row_data.map { |header, value| "#{header}: #{value}" }.join(", ")
    row_data
  end

  # Prompt the user to optionally enter a custom order for the scenarios
  val = WSApplication.prompt("OPTIONAL: Customize Scenario Order (comma-separated)", [['Enter the IDs of the scenarios in the desired order', 'String']], false)

  # Sort the scenarios based on user input or keep original order
  order = val[0].to_s.strip.split(',').map(&:strip)
  sorted_rows = order.empty? ? rows : rows.sort_by { |row| order.index(row['ID']) || Float::INFINITY }

  sorted_rows
end

# Main execution
begin
  open_net = WSApplication.current_network

  sorted_rows = import_scenario(open_net)

  # Delete all existing scenarios except 'Base'
  open_net.scenarios { |scenario| open_net.delete_scenario(scenario) if scenario != 'Base' }
  puts "\nAll existing scenarios deleted\n\n"

  # Add the imported scenarios
  puts "Added scenarios in the following order:"
  added_scenarios_count = sorted_rows.count do |scenario|
    next if scenario['ID'] == 'BASE'
    puts scenario['ID']
    open_net.add_scenario(scenario['ID'], nil, '')
    true
  end

  puts "\nTotal scenarios added: #{added_scenarios_count}"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
  puts e.backtrace
end