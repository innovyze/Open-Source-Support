# Upstream Subcatchment Identification Script for InfoWorks ICM

This script identifies all upstream subcatchments connected to a selected node in an InfoWorks ICM model network.

## How it Works

1. The script first accesses the current network and retrieves all nodes and subcatchments.

2. It then creates a hash map where the keys are node IDs and the values are arrays of subcatchments connected to each node.

3. For each subcatchment, if it has a node ID, the subcatchment is added to the array of the corresponding node in the hash map. If it doesn't have a node ID, the subcatchment is added to the arrays of all nodes connected to the subcatchment's lateral links.

4. The script then retrieves all selected nodes and initializes an array of unprocessed links.

5. For each selected node, it adds all upstream links to the array of unprocessed links.

6. While there are unprocessed links, the script takes the first link in the array, selects it, and retrieves its upstream node. If the upstream node exists and hasn't been processed before, the script selects it and adds all its upstream links to the array of unprocessed links. It also selects all subcatchments connected to the upstream node and prints their IDs.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM with some nodes selected. The script will automatically identify all upstream subcatchments connected to the selected nodes, select them, and print their IDs.