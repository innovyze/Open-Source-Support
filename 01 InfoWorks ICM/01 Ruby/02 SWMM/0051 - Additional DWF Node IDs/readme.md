# Nearest Storage Node Assignment Script for InfoWorks ICM

This script assigns each subcatchment in an InfoWorks ICM model network to the nearest storage node based on the centroid of the subcatchment.

## How it Works

1. The script first accesses the current network and begins a transaction to make changes to the network.

2. It then loops through each subcatchment in the network. For each subcatchment that does not have a node ID, it calculates the centroid of the subcatchment and sets a default distance of 9999999999.

3. The script then loops through each node in the network. For each node that is of type "storage", it calculates the distance from the centroid of the subcatchment to the node.

4. If the calculated distance is less than the current smallest distance, the script updates the smallest distance and the ID of the nearest storage node.

5. After all nodes have been processed, the script assigns the ID of the nearest storage node to the subcatchment and writes the changes to the subcatchment.

6. After all subcatchments have been processed, the script commits the transaction, applying the changes to the network.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically assign each subcatchment to the nearest storage node and print the ID of the subcatchment and the ID of the assigned node.