# Ruby Script Summary

This script is used to print the result fields of each table in an InfoWorks ICM network.

## Method: `print_table_results(cn)`

This method takes an InfoWorks ICM network (`cn`) as an argument and performs the following steps:

1. Iterates over each table in the network.
2. For each table, it initializes an array (`results_array`) to store the names of result fields and a flag (`found_results`) to track if result fields have been found.
3. It checks each row object in the current table. If the row object has a 'results_fields' property and results have not been found yet, it adds the field names to `results_array`, sets `found_results` to `true`, and breaks the loop.
4. If `results_array` is not empty, it prints the table name and each of its result fields on a separate row.

## Usage

The method is called with an InfoWorks ICM network as an argument:

```ruby
cn = WSApplication.current_network
print_table_results(cn)