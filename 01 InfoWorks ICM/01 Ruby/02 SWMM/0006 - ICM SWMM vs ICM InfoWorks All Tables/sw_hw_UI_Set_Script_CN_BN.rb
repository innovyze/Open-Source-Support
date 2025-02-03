# Initialize the background network - it should be ICM InfoWorks
bn = WSApplication.background_network

# Initialize the current network - it should be ICM SWMM
cn = WSApplication.current_network

# Clear any existing selection
bn.clear_selection
cn.clear_selection

# Initialize a hash to store capacity and gradient for each asset_id
link_properties = {}

# Loop through each subcatchment in the network
bn.row_objects('hw_conduit').each do |rohw|
  # Add the gradient and capacity of the link to the hash with asset_id as the key
  link_properties[rohw.asset_id] = { capacity: rohw.capacity, gradient: rohw.gradient } if rohw.capacity && rohw.gradient
end

# Initialize a counter for the number of rows written
rows_written = 0

# Loop through each conduit in the network
cn.transaction_begin
cn.row_objects('sw_conduit').each do |rosw|
  # Get the properties for the current asset_id
  properties = link_properties[rosw.id]

  # If properties exist, assign them to user_number_9 and user_number_10
  if properties
    rosw.user_number_9 = properties[:gradient]
    rosw.user_number_10 = properties[:capacity]
    rosw.write

    # Increment the counter
    rows_written += 1
  end
end
cn.transaction_commit

# Print the number of rows written
puts "Number of rows written to ICM SWMM: #{rows_written}"