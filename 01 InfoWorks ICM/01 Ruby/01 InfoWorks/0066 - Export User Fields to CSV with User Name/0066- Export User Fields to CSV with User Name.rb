require 'csv'
require 'date'

start_time = Time.now
cn = WSApplication.current_network
network_name = cn.network_model_object.name

export_tables = ["hw_node", "hw_conduit", "hw_subcatchment"]

val = WSApplication.prompt "Folder for the Export of ICM InfoWorks or ICM SWMM User Fields", 
[
  ['Pick the Folder', 'String', nil, nil, 'FOLDER', 'Folder'],
  ['Hydroworks export_tables = ', 'String'],
  ['["hw_node", "hw_conduit", "hw_subcatchment"]', 'String'],
  ['This script exports the user fields of the specified tables', 'String'],
  ['From an InfoWorks network model to CSV files.', 'String'],
  ['The user is prompted to select a folder where', 'String'],
  ['The CSV files will be saved.', 'String'],
  ['Opional User Description', 'String']
], false
folder_path = val[0]
puts "Folder path: #{folder_path}"
puts val[7]

export_tables.each do |table_name|
  # Define the file path for the CSV, including val[7] in the file name
  file_path = "#{folder_path}/#{network_name}_#{table_name}_#{val[7]}.csv"

  # Determine the ID field name based on the table name before opening the CSV
  id_field_name = case table_name
  when "hw_node"
    "node_id"
  when "hw_conduit"
    "asset_id"
  when "hw_subcatchment"
    "subcatchment_id"
  else
    "id"  # Default ID field name
  end

  # Open a new CSV file for writing
  CSV.open(file_path, "wb") do |csv|
    # Define headers with the dynamic ID field and user fields
    headers = [id_field_name]  # Use the determined ID field name for the first column header
    (1..10).each { |i| headers << "user_number_#{i}" }
    (1..10).each { |i| headers << "user_text_#{i}" }
    csv << headers  # Write headers to the CSV

    # Initialize a hash to store totals for each user_number field
    totals = Hash.new(0)

    # Iterate over rows in the table
    cn.row_object_collection(table_name).each do |row|
      # Collect row data starting with the ID
      row_data = [row[id_field_name]]
      # Append user_number and user_text values
      (1..10).each do |i|
        row_data << row["user_number_#{i}"]
        totals["user_number_#{i}"] += row["user_number_#{i}"].to_f  # Update totals, converting to float for addition
        row_data << row["user_text_#{i}"]
      end
      csv << row_data  # Write the collected row data to the CSV
    end

    # Output the total for each user_number field with the table name
    totals.each do |field, total|
      puts "#{table_name} - Total for #{field}: #{total}"
    end
  end
  puts "Data for table '#{table_name}' has been written to #{file_path}"
end

end_time = Time.now
net_time = end_time - start_time
puts
puts "Script Runtime: #{format('%.2f', net_time)} sec"