# QuickTrace Script for InfoWorks ICM Networks

This script performs a trace between two selected nodes in an InfoWorks ICM model network, selecting all nodes and links along the path.

## How it Works

1. The script first initializes the current network.

2. It then defines a method `process_node` that performs a trace from a given node to a destination node. This method uses Dijkstra's algorithm to find the shortest path, considering each conduit link as a path with a cost equal to its length and each non-conduit link as a path with a fixed cost.

3. The `doit` method checks if exactly two nodes are selected in the network. If not, it prints a message asking the user to select two nodes. If two nodes are selected, it performs a trace from the first selected node to the second selected node using the `process_node` method, and selects all nodes and links along the path.

4. Finally, the script creates a new instance of the `QuickTrace` class and calls the `doit` method.

![Alt text](image.png)

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM with exactly two nodes selected. The script will automatically perform a trace from the first selected node to the second selected node, select all nodes and links along the path, and print the total number of nodes and links found and the total length of the links.

# Additional Information:

The code seems to have been sourced from a GitHub repository and is specifically tailored for ICM InfoWorks Networks.
The script uses a basic Dijkstra-like approach to find the shortest path between two nodes based on link lengths or a default value.