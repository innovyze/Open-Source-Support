# Data Collection from 'sw_node' in InfoWorks ICM Network

This Ruby script segment collects data for each specified field from each 'sw_node' row object in an InfoWorks ICM network.

## How it Works

The script operates in several steps:

1. **Row Iteration**: The script iterates over each row object of type 'sw_node' in the network.

2. **Field Data Collection**: For each 'sw_node' row object, the script iterates over each specified database field. If the field value in the row object is not `nil`, it is added to the corresponding array in the `fields_data` hash.

3. **Row Counting**: The script also keeps track of the total number of 'sw_node' row objects processed, incrementing a `row_count` variable for each row object.

## Usage

This script segment is designed to be part of a larger script for processing InfoWorks ICM networks. It assumes that the `net`, `database_fields`, `fields_data`, and `row_count` variables have been previously defined.

```ruby
# Example usage in context
net = WSApplication.current_network
database_fields = ["field1", "field2", "field3"]
fields_data = {}
database_fields.each { |field| fields_data[field] = [] }
row_count = 0

# The provided script segment
net.row_objects('sw_node').each do |ro|
  row_count += 1
  database_fields.each do |field|
    fields_data[field] << ro[field] if ro[field]
  end
end