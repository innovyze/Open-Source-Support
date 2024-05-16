require 'csv'
require 'pathname'

def import_anode(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt("Facilty for an InfoSWMM Scenario", [
    ['Pick the Scenario Folder', 'String', nil, nil, 'FOLDER', 'Scenario Folder']
  ], false)

  # Check if the user canceled the prompt
  return if val.nil?

  folder_path = val[0]
  puts "Folder path: #{folder_path}"
  puts "If the CSV File is Empty - this means all nodes or links are active in the InfoSWMM Scenario"

  open_net.transaction_begin

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
        open_net.row_objects('_links').each do |ro|
          if ro.id == row["ID"] then
            ro.id_flag = 'ISAC'  # Set the 'flag' field of the row object
            ro.write  # Write the changes to the database
          end
        end
      end

      rows.each do |row|
        open_net.row_objects('_nodes').each do |ro|
          if ro.node_id == row["ID"] then
            ro.node_id_flag = 'ISAC'  # Set the 'flag' field of the row object
            ro.write  # Write the changes to the database
          end
        end
      end

      rows.each do |row|
        open_net.row_objects('_subcatchments').each do |ro|
          if ro.subcatchment_id == row["ID"] then
            ro.subcatchment_id_flag = 'ISAC'  # Set the 'flag' field of the row object
            ro.write  # Write the changes to the database
          end
        end
      end

    end

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

    open_net.clear_selection

    open_net.run_SQL "_links","flags.value='ISAC'"
    open_net.run_SQL "_nodes","flags.value='ISAC'"
    open_net.run_SQL "_subcatchments","flags.value='ISAC'"

    sl = parent_object.new_model_object 'Selection List', $selection_set.to_s
    puts s1 = sl.name
    open_net.save_selection sl
  end
  open_net.transaction_commit
end

# Access the current open network in the application
open_net = WSApplication.current_network

# Call the import_anode method
import_anode(open_net)


# Indicate the completion of the import process
puts "Finished Import of InfoSewer Facility Manager to ICM InfoWorks" 