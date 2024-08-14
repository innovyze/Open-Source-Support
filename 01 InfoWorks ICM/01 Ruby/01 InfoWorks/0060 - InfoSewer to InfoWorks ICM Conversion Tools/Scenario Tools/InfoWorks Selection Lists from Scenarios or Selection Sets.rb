# This script creates selection lists for active elements in each scenario (Scenario folder)
# It can also create selection lists for each selection set (Select/SS folder)

# DBF files must be converted to CSV files prior to running the script

# Required libraries
require 'csv'
require 'pathname'

# Method to import active nodes (anode) and links (alink) from CSV files
def import_anode_and_alink(open_net, parent_object)
  # Prompt the user to select the Scenario folder
  val = WSApplication.prompt("Active or Selected Elements", [
    ['Pick the Scenario or Select/SS Folder', 'String', nil, nil, 'FOLDER', 'Scenario/Selection Folder']
  ], false)

  # End function if user cancels the prompt
  return if val.nil?

  folder_path = val[0]
  puts "Selected folder: #{folder_path}"
  puts "\nNote: If the selection list is empty for a scenario, all nodes and links may be active in the InfoSewer/InfoSWMM Scenario."
  puts "\n"

  # Hashes to store links, nodes, and subcatchments
  id_to_link = {}
  id_to_node = {}
  id_to_subcatchment = {}

  # Populate the hashes with network objects
  open_net.row_objects('_links').each { |ro| id_to_link[ro.id] = ro }
  open_net.row_objects('_nodes').each { |ro| id_to_node[ro.node_id] = ro }
  open_net.row_objects('_subcatchments').each { |ro| id_to_subcatchment[ro.subcatchment_id] = ro }

  # Hash to store Asset ID to Link ID mapping from link tables
  asset_to_link_id = {}
  open_net.row_objects('_links').each do |ro|
    asset_to_link_id[ro.asset_id] = ro.us_node_id + '.' + ro.link_suffix
  end

  # Clear any existing selection in the network
  open_net.clear_selection

  # Iterate over all subdirectories in the selected folder
  Pathname.new(folder_path).children.select(&:directory?).each do |dir|
    # Clear selection before processing each subdirectory
    open_net.clear_selection

    # Create a new selection list for each subdirectory
    selection_set = Pathname.new(dir).basename.to_s
    sl = parent_object.new_model_object 'Selection List', selection_set

    ['anode.csv', 'alink.csv'].each do |filename|
      csv_path = "#{dir}/#{filename}"

      # Check if the CSV file exists
      if File.exist?(csv_path)
        begin
          # Try opening the file
          File.open(csv_path, 'a') {}
        rescue IOError => e
          # Handle file open error
          puts "File #{filename} is already open"
        end
      end

      # Array to hold the CSV rows
      rows = []

      # Read the CSV file and store rows in the array
      CSV.foreach(csv_path, headers: true) do |row|
        row_hash = row.to_h
        # Add directory and source to the hash
        row_hash["dir_source"] = File.basename(dir.to_s) + "_" + File.basename(filename, '.*')
        rows << row_hash
      end

      # Process each row and update selections
      rows.each do |row|
        # Add links with converted Link IDs
        if filename == 'alink.csv' && asset_to_link_id.key?(row["ID"])
          link_id = asset_to_link_id[row["ID"]]
          if ro = id_to_link[link_id]
            ro.selected = true
            ro.write
          end
        end

        # Add nodes from anode.csv
        if filename == 'anode.csv' && ro = id_to_node[row["ID"]]
          ro.selected = true
          ro.write
        end

        # Add subcatchments (assumed to be same as nodes)
        if ro = id_to_subcatchment[row["ID"]]
          ro.selected = true
          ro.write
        end
      end
    end

    # Save the selection list
    open_net.save_selection(sl)
    puts "Created selection list: #{sl.name}\n"
  end
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
begin
  import_anode_and_alink(open_net, parent_object)
  open_net.transaction_commit
rescue => e
  open_net.transaction_rollback
  puts "Error importing active elements: #{e.message}"
end

# Clear any existing selection in the network
open_net.clear_selection

# Print completion message
puts "\nFinished the creation of ICM Selection Lists from InfoSewer or InfoSWMM Scenarios or Selection Sets."
puts "\nRefresh the database to view the new selection lists in the database tree."