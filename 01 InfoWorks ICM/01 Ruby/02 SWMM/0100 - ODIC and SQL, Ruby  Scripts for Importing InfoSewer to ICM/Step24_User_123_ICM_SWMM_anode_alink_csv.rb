#This script can be used to create selection lists for active elements in each scenario (Scenario folder)
#This script can also be used to create seleciton lists for each selection set from InfoSWMM (Selection folder)

# Required libraries
require 'csv'
require 'pathname'

# Method to import anode
def import_anode(open_net, parent_object)
  # Prompt the user for folder selection
  val = WSApplication.prompt("Facility for an InfoSWMM Scenario", [
    ['Pick the Scenario Folder', 'String', nil, nil, 'FOLDER', 'Scenario Folder']
  ], false)

  # End function if user cancels the prompt
  return if val.nil?

  folder_path = val[0]
  puts "Selected folder: #{folder_path}"
  puts "\nNote: If the CSV File is empty, it means all nodes or links are active in the InfoSWMM Scenario."
  puts "\n"

  # Hashes to store links, nodes, and subcatchments
  id_to_link = {}
  id_to_node = {}
  id_to_subcatchment = {}

  # Populate the hashes
  open_net.row_objects('_links').each { |ro| id_to_link[ro.id] = ro }
  open_net.row_objects('_nodes').each { |ro| id_to_node[ro.node_id] = ro }
  open_net.row_objects('_subcatchments').each { |ro| id_to_subcatchment[ro.subcatchment_id] = ro }

  # Iterate over all subdirectories in the folder
  Pathname.new(folder_path).children.select(&:directory?).each do |dir|
    ['anode.csv', 'alink.csv'].each do |filename|
      puts "Subdirectory: #{Pathname.new(dir).basename}"
      $selection_set = Pathname.new(dir).basename
      puts "Filename: #{filename}"
      csv_path = "#{dir}/#{filename}"

      # Check if the CSV file exists
      if File.exist?(csv_path)
        begin
          # Try opening the file
          File.open(csv_path, 'a') {}
          puts "Located #{filename} in #{csv_path}"
        rescue IOError => e
          # Handle file open error
          puts "File #{filename} is already open"
        end
      end

      # Array to hold the CSV rows
      rows = []

      # Read the CSV file
      CSV.foreach(csv_path, headers: true) do |row|
        row_hash = row.to_h
        # Add directory and source to the hash
        row_hash["dir_source"] = File.basename(dir.to_s) + "_" + File.basename(filename, '.*')
        row_hash = row.to_h
        rows << row_hash
      end

      puts "Row count: #{rows.count}"

      # Update links, nodes, and subcatchments
      rows.each do |row|
        # Update links
        if ro = id_to_link[row["ID"]]
          ro.id_flag = 'ISAC'
          ro.write
        end

        # Update nodes
        if ro = id_to_node[row["ID"]]
          ro.node_id_flag = 'ISAC'
          ro.write
        end

        # Update subcatchments
        if ro = id_to_subcatchment[row["ID"]]
          ro.subcatchment_id_flag = 'ISAC'
          ro.write
        end
      end
    end

    # Clear selection and select new elements
    open_net.clear_selection
    open_net.run_SQL "_links","flags.value='ISAC'"
    open_net.run_SQL "_nodes","flags.value='ISAC'"
    open_net.run_SQL "_subcatchments","flags.value='ISAC'"

    # Create and save selection list
    sl = parent_object.new_model_object 'Selection List', $selection_set.to_s
    puts s1 = sl.name
    open_net.save_selection sl
  end
end

# Access the current network
open_net = WSApplication.current_network

# Fetch the parent object
db = WSApplication.current_database
current_network = WSApplication.current_network
current_network_object = current_network.model_object
parent_id = current_network_object.parent_id

begin
  parent_object = db.model_object_from_type_and_id 'Model Group', parent_id
rescue
  parent_object = db.model_object_from_type_and_id 'Model Network', parent_id
  parent_id = parent_object.parent_id
  parent_object = db.model_object_from_type_and_id 'Model Group', parent_id
end

# Start a transaction and call the import_anode method
open_net.transaction_begin
import_anode(open_net, parent_object)
open_net.transaction_commit

# Print completion message
puts "\nFinished the Import of InfoSWMM Facility Manager Active Elements to ICM SWMM Selection Lists"