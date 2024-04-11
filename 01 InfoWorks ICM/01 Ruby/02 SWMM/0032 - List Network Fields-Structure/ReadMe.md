# InfoWorks ICM Network Field List Printer applies to SWMM and Infoworks Networks

This Ruby script prints the names of all fields for each table in an InfoWorks ICM model network.

## How it Works

The script operates in several steps:

1. **Table Iteration**: The script iterates over each table in the network.

2. **Field Collection and Printing**: For each table, the script iterates over each field. It prints the field name, and if the field's data type is 'WSStructure', it also prints the names of the subfields.

3. **Error Handling**: If a 'WSStructure' field does not have any subfields (i.e., `j.fields` is `nil`), the script prints "***badger***" to indicate a potential issue.

## Usage

To use this script, you need to have an active network in InfoWorks ICM. The script will automatically print the names of all fields for each table in the network.

```ruby
# Usage example
net = WSApplication.current_network
print_table_fields(net)

