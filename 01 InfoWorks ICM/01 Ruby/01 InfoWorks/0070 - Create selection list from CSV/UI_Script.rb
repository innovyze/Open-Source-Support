# Required libraries
require 'csv'
require 'pathname'

# Function to create a selection list from CSV files
def create_selection_list_from_csv(open_net, parent_object)
  # Prompt the user to select the folder containing the CSV files
  folder_path = WSApplication.prompt("Selection list data location", [
    ['Pick the folder containing selection list data', 'String', nil, nil, 'FOLDER', 'Folder Path'],
  ], false)

  # If the user cancels the prompt, end the function
  return if folder_path.nil?

  folder_path = folder_path[0]

  # Check if all required file locations are provided
  if folder_path.nil? || folder_path.empty?
    WSApplication.message_box("Folder location not provided. Script aborted.", "OK", "!", false)
   return
  end

  # Define the paths to the CSV files
  csv_files = {
    node: "#{folder_path}/Nodes.csv",
    link: "#{folder_path}/Links.csv",
    subcatchment: "#{folder_path}/Subcatchments.csv"
  }

  # Check if at least one CSV file exists to proceed
  unless csv_files.values.any? { |file| File.exist?(file) }
    WSApplication.message_box("No valid CSV files found in the provided folder. Script aborted.", "OK", "!", false)
    return
  end

  # Clear any existing selection in the network
  open_net.clear_selection

  # Iterate over each CSV file
  csv_files.each do |type, csv_file|
    # Skip the file if it doesn't exist
    next unless File.exist?(csv_file)

    # Select entities using the IDs from the CSV file
    puts "\nSelected #{type}s:"
    CSV.foreach(csv_file, headers: true) do |row|
      id = row["#{type.capitalize} ID"]
      if entity = open_net.row_object("_#{type}s", id)
        entity.selected = true
        entity.write
        puts "#{id}"
      end
    end
  end

  # Prompt the user for the name of the new selection list
  list_name = WSApplication.prompt("Selection list name", [
    ['Enter a name for the selection list', 'String'],
  ], false)

  list_name = list_name[0].to_s

  # Ensure the selection list name is unique by appending '!' to the end of the name until it is unique
  group = parent_object
  group.children.each do |child|
    while child.name == list_name
      list_name += '!'
    end
  end

  # Create and save the selection list
  sl = parent_object.new_model_object 'Selection List', list_name
  open_net.save_selection sl

end

# Access the current network
open_net = WSApplication.current_network

# Fetch the parent object
db = WSApplication.current_database
current_network_object = open_net.model_object
parent_id = current_network_object.parent_id

# Attempt to find the parent object assuming it's a 'Model Group'
# If unsuccessful, assume the parent object is a 'Model Network' and find its parent 'Model Group'
begin
  parent_object = db.model_object_from_type_and_id 'Model Group', parent_id
rescue
  parent_object = db.model_object_from_type_and_id 'Model Network', parent_id
  parent_id = parent_object.parent_id
  parent_object = db.model_object_from_type_and_id 'Model Group', parent_id
end

# Start a transaction and call the function to create the selection list
open_net.transaction_begin
if create_selection_list_from_csv(open_net, parent_object)
  puts "Selection list data location: #{folder_path}"
  puts "\nSelection List '#{list_name}' has been created within model group '#{group.name}'."
  puts "Refresh the database to view the new selection list in the database tree."
end

open_net.transaction_commit