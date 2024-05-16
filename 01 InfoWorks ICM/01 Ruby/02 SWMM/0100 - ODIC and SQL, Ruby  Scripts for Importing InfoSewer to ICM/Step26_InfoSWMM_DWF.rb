require 'csv'
require 'pathname'

def import_dwf(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt "Folder for an InfoSWMM Scenario", [
    ['Pick the ISDB Folder','String',nil,nil,'FOLDER','ISDB Folder']], false
  folder_path = val[0]
  puts "Folder path: #{folder_path}"

  # Check if folder path is given
  return unless folder_path

  # Initialize an empty array to hold the hashes
  rows = []

  scenario_csv = "#{folder_path}/dwf.csv"
  puts "Scenario CSV: #{scenario_csv}"

  # Headers to exclude
  exclude_headers = ["ALLOC_CODE","ITEM"]

  # Read the CSV file
  CSV.open(scenario_csv, 'r', headers: true) do |csv|
    puts csv.headers

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
end

# Access the current open network in the application
 cn = WSApplication.current_network

# Call the import_dwf method
rows = import_dwf(cn)
