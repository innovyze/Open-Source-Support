## Code Summary: Counting Tables in an ICM SWMM Network

### Purpose
This Ruby script is designed to count all the tables in an ICM SWMM (Stormwater Management Model) Network.

### Process Flow

1. **Begin Block**
   - The script starts with a `begin` block to handle any exceptions that might occur.

2. **Accessing the Current Network**
   - `net = WSApplication.current_network`: Retrieves the current network.
   - The script raises an error if no current network is found.

3. **Defining Table Names**
   - A list of table names related to the ICM SWMM network is defined. This includes tables like `sw_conduit`, `sw_node`, `sw_weir`, etc.

4. **Counting Rows in Each Table**
   - The script iterates through each table name.
   - For each table, it accesses the row objects.
   - Counts the number of rows (elements) in each table.
   - Prints the table name along with the count of its rows.

5. **Error Handling**
   - If a table is not found, an error message is raised.
   - Any other exceptions are caught and their message is printed.

### Notes
- The script is useful for getting an overview of the elements present in an ICM SWMM network.
- It provides a count of elements for each specified table, which can be essential for data analysis and network management.
- Exception handling is implemented to ensure the script does not fail silently.
