# Ruby Script: Transfer Properties from ICM InfoWorks to ICM SWMM

This script is used to transfer the `capacity` and `gradient` properties from conduits in an ICM InfoWorks network to conduits in an ICM SWMM network.

## Steps

1. The script initializes the background network (`bn`) as the ICM InfoWorks network and the current network (`cn`) as the ICM SWMM network.

2. It clears any existing selection in both networks.

3. The script initializes a hash (`link_properties`) to store the `capacity` and `gradient` for each `asset_id` in the ICM InfoWorks network.

4. It loops through each conduit in the ICM InfoWorks network. If a conduit has a `capacity` and `gradient`, the script adds them to the `link_properties` hash with the `asset_id` as the key.

5. The script initializes a counter (`rows_written`) to keep track of the number of rows written to the ICM SWMM network.

6. It starts a transaction in the ICM SWMM network and loops through each conduit. For each conduit, the script gets the properties for the current `asset_id` from the `link_properties` hash. If properties exist for the current `asset_id`, the script assigns them to `user_number_9` and `user_number_10`, writes the changes to the conduit, and increments the `rows_written` counter.

7. The script commits the transaction in the ICM SWMM network.

8. Finally, the script prints the number of rows written to the console.

## Ruby Code

```ruby
// ... (code omitted for brevity)

// Loop through each conduit in the ICM SWMM network
cn.transaction_begin
cn.row_objects('sw_conduit').each do |rosw|
  // Get the properties for the current asset_id
  properties = link_properties[rosw.id]

  // If properties exist, assign them to user_number_9 and user_number_10
  if properties
    rosw.user_number_9 = properties[:gradient]
    rosw.user_number_10 = properties[:capacity]
    rosw.write

    // Increment the counter
    rows_written += 1
  end
end
cn.transaction_commit

// Print the number of rows written
puts "Number of rows written to ICM SWMM: #{rows_written}"