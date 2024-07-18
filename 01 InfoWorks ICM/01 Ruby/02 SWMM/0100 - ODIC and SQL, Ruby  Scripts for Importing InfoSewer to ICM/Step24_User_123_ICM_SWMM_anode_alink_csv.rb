require 'csv'
require 'pathname'

def import_anode(open_net, parent_object)
  # Prompt the user to pick a folder
  val = WSApplication.prompt("Facility for an InfoSWMM Scenario", [
    ['Pick the Scenario Folder', 'String', nil, nil, 'FOLDER', 'Scenario Folder']
  ], false)

  # Check if the user canceled the prompt
  return if val.nil?

  folder_path = val[0]
  puts "Folder path: #{folder_path}"
  puts "If the CSV File is Empty - this means all nodes or links are active in the InfoSWMM Scenario"

  # Create a hash that maps id to row object for links, nodes, and subcatchments
  id_to_link = {}
  id_to_node = {}
  id_to_subcatchment = {}

  open_net.row_objects('_links').each { |ro| id_to_link[ro.id] = ro }
  open_net.row_objects('_nodes').each { |ro| id_to_node[ro.node_id] = ro }
  open_net.row_objects('_subcatchments').each { |ro| id_to_subcatchment[ro.subcatchment_id] = ro }

  # Iterate over all subdirectories in the given folder
  Pathname.new(folder_path).children.select(&:directory?).each do |dir|
    ['anode.csv', 'alink.csv'].each do |filename|
      puts Pathname.new(dir).basename
      $selection_set = Pathname.new(dir).basename
      puts filename
      csv_path = "#{dir}/#{filename}"

      # Check if the CSV file exists in the subdirectory
      if File.exist?(csv_path)
        begin
          File.open(csv_path, 'a') {}
          puts "Found #{filename} in #{csv_path}"
        rescue IOError => e
          puts "File #{filename} is already open"
        end
      end
      # Initialize an empty array to hold the hashes
      rows = []

      # Read the CSV file
        CSV.foreach(csv_path, headers: true) do |row|
          row_hash = row.to_h
          #row_hash.delete("TYPE") # Remove the "TYPE" key-value pair
          row_hash["dir_source"] = File.basename(dir.to_s) + "_" + File.basename(filename, '.*') # Combine 'dir' and 'source'
          row_hash = row.to_h
          rows << row_hash
        end

      puts "Row count: #{rows.count}"

      rows.each do |row|
        # Update links
        ro = id_to_link[row["ID"]]
        if ro
          ro.id_flag = 'ISAC'
          ro.write
        end
    
        # Update nodes
        ro = id_to_node[row["ID"]]
        if ro
          ro.node_id_flag = 'ISAC'
          ro.write
        end
    
        # Update subcatchments
        ro = id_to_subcatchment[row["ID"]]
        if ro
          ro.subcatchment_id_flag = 'ISAC'
          ro.write
        end
      end
    end

  
    open_net.clear_selection

    open_net.run_SQL "_links","flags.value='ISAC'"
    open_net.run_SQL "_nodes","flags.value='ISAC'"
    open_net.run_SQL "_subcatchments","flags.value='ISAC'"

    sl = parent_object.new_model_object 'Selection List', $selection_set.to_s
    puts s1 = sl.name
    open_net.save_selection sl

  end

end

# Access the current open network in the application
open_net = WSApplication.current_network

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

# Call the import_anode method
open_net.transaction_begin
import_anode(open_net,parent_object)
open_net.transaction_commit

# Indicate the completion of the import process
puts "Finished the Import of InfoSWMM Facility Manager Active Elements to ICM SWMM Selection Lists" 