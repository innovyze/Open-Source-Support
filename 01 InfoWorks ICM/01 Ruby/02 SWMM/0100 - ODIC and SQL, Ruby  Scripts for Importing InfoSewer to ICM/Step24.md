# Ruby Script: Import Active Elements from InfoSewer/InfoSWMM to ICM InfoWorks

This script is used to import active elements from InfoSewer/InfoSWMM Facility Manager to ICM InfoWorks as selection sets.

## Steps

1. The script prompts the user to pick a folder containing the InfoSWMM Scenario.

2. It initializes three hashes (`id_to_link`, `id_to_node`, `id_to_subcatchment`) to map `id` to row objects for links, nodes, and subcatchments in the ICM InfoWorks network.

3. The script iterates over all subdirectories in the given folder. For each subdirectory, it looks for two files: `anode.csv` and `alink.csv`.

4. If a CSV file exists in the subdirectory, the script reads the file and stores each row as a hash in an array (`rows`). The `dir_source` key-value pair is added to each hash.

5. The script then iterates over each row in `rows`. For each row, it gets the corresponding row object from the appropriate hash (`id_to_link`, `id_to_node`, `id_to_subcatchment`) and updates it.

6. After updating all row objects, the script clears the current selection in the ICM InfoWorks network and runs SQL queries to select the updated objects.

7. The script saves the current selection as a new selection list in the ICM InfoWorks network.

8. Finally, the script prints a message indicating the completion of the import process.

## Ruby Code

```ruby
// ... (code omitted for brevity)

// Loop through each row in rows
rows.each do |row|
  // Update links
  ro = id_to_link[row["ID"]]
  if ro
    ro.asset_id_flag = 'ISAC'
    ro.write
  end

  // Update nodes
  ro = id_to_node[row["ID"]]
  if ro
    ro.node_id_flag = 'ISAC'
    ro.write
  end

  // Update subcatchments
  ro = id_to_subcatchment[row["ID"]]
  if ro
    ro.subcatchment_id_flag = 'ISAC'
    ro.write
  end
end

// ... (code omitted for brevity)