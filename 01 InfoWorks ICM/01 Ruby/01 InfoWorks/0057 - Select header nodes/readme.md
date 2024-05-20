# Header Nodes Selection Script

This script selects all header nodes in an InfoWorks ICM model network. A header node is defined as a node that is not used as the downstream node (`ds_node_id`) for any link in the network.

## How it Works

1. The script first checks if there is a network open in the WSApplication. If not, it prints an error message and exits.

2. It then gets the current network and clears any existing selection.

3. The script creates an array to store node IDs and populates it with the IDs of all nodes in the network.

4. It also creates an array to store downstream node IDs and populates it with the IDs of the downstream nodes of all links in the network.

5. Finally, the script iterates over each node ID. If a node ID is not in the downstream node IDs array, the script selects the corresponding node in the network and prints a message indicating the node ID.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically select all header nodes in the network.

## Error Handling

The script includes error handling to catch and print error messages if there is no open network in the WSApplication, or if the nodes or links object collections are empty.

## Source

This script is originally sourced from [here](https://github.com/chaitanyalakeshri/ruby_scripts) and has been edited for use with ChatGPT.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks