require 'csv'
require 'pathname'

def import_scenario(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt "Folder for an InfoSewer or InfoSWMM Scenario", [
    ['Pick the IEDB or ISDB Folder - All existing scenarios will be deleted','String',nil,nil,'FOLDER','IEDB or ISDB Folder']], false
  folder_path = val[0]
  puts "Folder path: #{folder_path}"

  # Check if folder path is given
  return unless folder_path

  # Initialize an empty array to hold the hashes
  rows = []

  scenario_csv = "#{folder_path}/scenario.csv"
  puts "Scenario CSV: #{scenario_csv}"

  # Headers to exclude
  exclude_headers = ["USE_TIME", "TIME_SET", "USE_REPORT", "REPORT_SET", "USE_OPTION", "OPTION_SET","PISLT_SET"]

  # Read the CSV file
  CSV.open(scenario_csv, 'r', headers: true) do |csv|

  # Process the rows
  csv.each do |row|
    row_string = ""
    row.headers.each do |header|
      unless row[header].nil? || exclude_headers.include?(header)
        row_string += sprintf("%-15s: %s, ", header, row[header])
      end
    end
    puts row_string

      # Add the row to the array as a hash
      rows << row.to_h
    end
  end

  rows
end

# Access the current open network in the application
open_net = WSApplication.current_network

# Call the import_scenario method
rows = import_scenario(open_net)

added_scenarios_count = 0

# Delete all scenarios except 'Base'
open_net.scenarios do |scenario|
 if scenario != 'Base'
  open_net.delete_scenario(scenario)
 end
end

puts "All scenarios deleted"

# Add new scenarios from the CSV file
rows.each do |scenario|
 if scenario['ID'] != 'BASE'
   puts "Adding scenario #{scenario['ID']}"
   open_net.add_scenario(scenario['ID'],nil,'')
   added_scenarios_count += 1
 end
end

# Print the total number of scenarios added
puts "Total scenarios added: #{added_scenarios_count}"