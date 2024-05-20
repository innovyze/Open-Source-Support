require 'csv'
require 'pathname'

def import_dwf(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt "Folder for an InfoSWMM DWF", [
    ['Pick the ISDB Folder','String',nil,nil,'FOLDER','ISDB Folder']], false
  folder_path = val[0]
  puts "Folder path: #{folder_path}"

  # Check if folder path is given
  return unless folder_path

  # Initialize an empty array to hold the hashes
  rows = []
  # Initialize a variable to store the total flow for all rows
  total_flow_all_rows = 0.0
  # Initialize a hash to store the count for each ID
  id_counts = Hash.new(0)

  scenario_csv = "#{folder_path}/dwf.csv"
  puts "Scenario CSV: #{scenario_csv}"

  # Headers to exclude
  exclude_headers = ["ALLOC_CODE","ITEM"]

  # Initialize a hash to store total and count for flow by id
  flow_stats = Hash.new { |h, k| h[k] = { total: 0, count: 0 } }

    # Create a hash that maps id to row object for links, nodes, and subcatchments
    id_to_node = {}
    open_net.row_objects('_nodes').each { |ro| id_to_node[ro.node_id] = ro }

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

      # Update the count for the current ID
      id = row['ID']
      id_counts[id] += 1
      flow = row['VALUE'].to_f
      flow_stats[id][:total] += flow
      flow_stats[id][:count] += 1      
      # Update the total flow for all rows
      total_flow_all_rows += flow
      
      # Update nodes
        ro = id_to_node[row["ID"]]
          if ro
            puts "Updating node #{ro.node_id}, Count: #{id_counts[ro.node_id]}"
            if(id_counts[id]==1) then ro.base_flow = row["VALUE"].to_f end
              ro.additional_dwf.each do |additional_dwf|
                additional_dwf.baseline = 0.0
              end
            ro.write
            end
    end
  end

  # Print the total and count for flow by id
  flow_stats.each do |id, stats|
    #puts "ID: #{id}, Total Flow: #{stats[:total].to_f}, Count: #{stats[:count]}"
  end
  # Print the total flow for all rows and the count of all rows
  puts "Total Flow for All Rows: #{total_flow_all_rows}, Count: #{rows.size}"
  # Return the rows
  rows
end

# Access the current open network in the application
cn = WSApplication.current_network

# Call the import_dwf method
cn.transaction_begin
rows = import_dwf(cn)
cn.transaction_commit