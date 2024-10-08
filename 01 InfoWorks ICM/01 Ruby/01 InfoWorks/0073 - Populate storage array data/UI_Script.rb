def array_to_structure(structure, array)
    # Sanity check
    raise "Expected a WSStructure" unless structure.is_a?(WSStructure)
    raise "Expected an Array" unless array.is_a?(Array)
    raise "Expected an Array of Hashes" unless array.all? { |item| item.is_a?(Hash) }
  
    # Make the structure length match the array
    structure.length = array.length
  
    # Update the values in each row in the structure (WSStructureRow)
    array.each_with_index do |hash, i|
      struct_row = structure[i]
      # Key-value pairs (k, v) in the hash are used to update the struct_row
      hash.each { |k, v| struct_row[k] = v }
    end
  
    # Write changes - note that the WSRowObject that this WSStructure belongs to also needs to call #write
    structure.write
  end
  
  # Define the data to be stored in the storage array
  # Note: Data in level-area pairs must be updated to the desired values
  STORAGE_DATA = [
    { 'level' => 11, 'area' => 111 },
    { 'level' => 22, 'area' => 222 },
    { 'level' => 33, 'area' => 333 }
  ]
  
  begin
    # Start a transaction on the current network
    net = WSApplication.current_network
    net.transaction_begin
  
    # Fetch the row object and storage array structure
    # Note: The node ID must be updated to the desired value
    node_id = 'YourNodeIDHere'
    ro = net.row_object('hw_node', node_id)
    # Check if the row object exists
    if ro.nil?
        puts "Error: Node ID #{node_id} does not exist."
        net.transaction_rollback
        exit
    end
    storage_array_struct = ro.storage_array
  
    # Use the array_to_structure method to populate the storage array
    array_to_structure(storage_array_struct, STORAGE_DATA)
  
    # Save the changes to the row object
    ro.write
  
    # Commit the transaction
    net.transaction_commit
  
    # Output the contents of the storage array
    puts "The following data was written to the storage array for node ID #{ro.id}:"
    ro.storage_array.each do |row|
      puts "level: #{row['level']}, area: #{row['area']}"
    end
  
  rescue => e
    # Rollback transaction in case of error
    net.transaction_rollback
    puts "An error occurred: #{e.message}"
  end  