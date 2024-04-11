require 'csv'
require 'pathname'

def import_anode(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt("Facilty for an InfoSewer Scenario", [
    ['Pick the Scenario Folder', 'String', nil, nil, 'FOLDER', 'Scenario Folder']
  ], false)

  # Check if the user canceled the prompt
  return if val.nil?

  folder_path = val[0]
  puts "Folder path: #{folder_path}"
  puts "If the CSV File is Empty - this means all nodes or links are active in the InfoSewer Scenario"

  # Initialize an empty array to hold the hashes
  rows = []

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

        # Read the CSV file
        CSV.foreach(csv_path, headers: true) do |row|
          row_hash = row.to_h
          puts row.to_h
          row_hash.delete("TYPE") # Remove the "TYPE" key-value pair
          row_hash["dir_source"] = File.basename(dir.to_s) + "_" + File.basename(filename, '.*') # Combine 'dir' and 'source'
          rows.each do |row|
            row_hash = row.to_h
            rows << row_hash
            puts row_hash
          end
        end
      else
        raise "No #{filename} file found in #{dir}"
      end
    end

  rows.each do |row|
    open_net.row_objects('hw_conduit').each do |ro|
      if ro.asset_id == row["ID"] then
         ro.asset_id_flag = 'ISAC'  # Set the 'flag' field of the row object
         ro.write  # Write the changes to the database
      end
    end
  end

  rows.each do |row|
    open_net.row_objects('hw_node').each do |ro|
      if ro.node_id == row["ID"] then
         ro.node_id_flag = 'ISAC'  # Set the 'flag' field of the row object
         ro.write  # Write the changes to the database
      end
    end
  end

  rows.each do |row|
    open_net.row_objects('hw_subcatchment').each do |ro|
      if ro.subcatchment_id == row["ID"] then
         ro.subcatchment_id_flag = 'ISAC'  # Set the 'flag' field of the row object
         ro.write  # Write the changes to the database
      end
    end
  end
    db=WSApplication.current_database
    open_net.clear_selection
    group=db.find_root_model_object 'Model Group','DanaHDR'   # Find the model group - has to be created before use
    open_net.run_SQL "_links","flags.value='ISAC''"
    open_net.run_SQL "_nodes","flags.value='ISAC''"
    open_net.run_SQL "_subcatchments","flags.value='ISAC''"
    sl=group.new_model_object 'Selection List',$selection_set.to_s
    puts s1=sl.name
    open_net.save_selection sl
end

end

# Access the current open network in the application
open_net = WSApplication.current_network

# Call the import_anode method
open_net.transaction_begin
import_anode(open_net)
open_net.transaction_commit

# Indicate the completion of the import process
puts "Finished Import of InfoSewer Facility Manager to ICM InfoWorks" 