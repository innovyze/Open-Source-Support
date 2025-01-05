# 0140 - List all results fields in a simulation (ICM) and Show Node Results

This Ruby script is used to analyze data from a network in the InfoWorks ICM software. Here's a summary of what it does:

- It first sets up the current network (`cn`) and retrieves the count and list of timesteps.

- It then defines a function `print_table_results(cn)` which iterates over each table in the network, and for each table, it checks each row object to see if it has a 'results_fields' property. If it does, it adds the field names to a results array and prints them.

- The script then calls `print_table_results(cn)` to print the tables and their result fields in the current network.

- It calculates the time interval in seconds assuming the time steps are evenly spaced and prints the time interval in seconds and minutes.

- It defines an array `result_field_names` with the names of the result fields to fetch the results for all selected nodes.

- It iterates over each selected object in the network. For each object, it tries to get the row object for the current node. If the row object is not `nil`, it iterates over each result field name.

- For each result field name, it checks if the count of results matches the count of timesteps. If it does, it initializes variables to keep track of statistics and iterates over the results to calculate the total, total integrated over time, min, max, and count.

- It then calculates the mean value if the count is greater than 0 and prints the total, total integrated over time, mean, max, min values, and count.

- If an error occurs while processing a node or a field does not exist for a node, it handles the error and continues with the next node or field.