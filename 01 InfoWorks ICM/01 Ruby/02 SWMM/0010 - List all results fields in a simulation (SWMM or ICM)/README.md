# InfoWorks ICM Table Results Printer

This Ruby script prints the names of the result fields for each table in an InfoWorks ICM model network.

## How it Works

The script operates in several steps:

1. **Table Iteration**: The script iterates over each table in the network.

2. **Result Field Collection**: For each table, the script checks each row object. If the row object has a 'results_fields' property and results have not been found yet, it adds the field names to a results array.

3. **Result Printing**: After collecting the result fields, the script prints the table name and its result fields, but only if there are result fields.

## Usage

To use this script, you need to have an active network in InfoWorks ICM. The script will automatically print the names of the result fields for each table in the network.

```ruby
# Usage example
net = WSApplication.current_network
print_table_results(net)

![](png001.png)