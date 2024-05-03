# Ruby Script for Processing SWMM Network Nodes in InfoWorks ICM

This Ruby script is used to process SWMM network nodes in the InfoWorks ICM software. Here's a summary of what it does:

- It first defines a method `print_table` to return a specific cell from a 2D array, or 1.0 if the cell is out of bounds.

- It then defines a method `find_column` to find the index of a target value in the first row of a 2D array.

- It sets up the current network (`net`) and defines an array of database fields for SWMM network nodes.

- It clears the current selection in the network and prints the current scenario.

- It prepares a hash for storing data of each field for `database_fields`.

- It collects data for each field from `sw_node` and stores it in the `fields_data` hash.

- It initializes an array to store the node IDs.

- It iterates over each row in a 2D array `data_7day` (not defined in the provided code).

- For each row, it iterates over each row object in `sw_node`.

- It calculates the sum of all user numbers for each row object.

- If the sum of all user numbers is greater than 0.0, it adds the node ID to the array.

- It then calculates a new sum of user numbers, multiplied by a specific cell from `data_7day`.

- It prints the new sum of user numbers.

- Finally, it prints all of the node IDs in one row separated by commas, and in one column.

Note: In case of any errors during the execution, the error message is printed to the console.