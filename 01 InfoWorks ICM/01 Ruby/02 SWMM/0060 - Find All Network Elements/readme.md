# Network Elements Identifier Script

This script identifies all network elements in an InfoWorks ICM model network. It accesses all nodes, links, subcatchments, weirs, orifices, and pumps in the network.

## How it Works

1. The script first accesses the current network.

2. It then defines a method `process_row_objects` that takes a network and a type of row object as arguments. This method does the following:
   - Gets the row objects of the specified type from the network.
   - Creates a hash map where the key is the object ID and the value is an array of IDs of objects with that ID.
   - Prints the names of the objects.

3. The `process_row_objects` method is then called for nodes, links, subcatchments, weirs, orifices, and pumps.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically print the names of all nodes, links, subcatchments, weirs, orifices, and pumps in the network.

## Error Handling

The script includes error handling to catch and print error messages if the current network is not found or if the row objects of a specified type are not found.

## Source

This script is originally sourced from [here](https://github.com/chaitanyalakeshri/ruby_scripts).

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks