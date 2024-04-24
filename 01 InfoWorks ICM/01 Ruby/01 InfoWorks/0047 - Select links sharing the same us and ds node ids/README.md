# Bifurcation Links Selection Script

This script selects all bifurcation links in an InfoWorks ICM model network. A bifurcation link is defined as a link that shares the same upstream and downstream nodes (`us_node_id` and `ds_node_id`) with at least one other link in the network.

## How it Works

1. The script first accesses the current network and clears any existing selection.

2. It creates an array to store all links in the network, where each link is represented as an array containing a unique identifier (the concatenation of the upstream and downstream node IDs) and the link ID.

3. The script groups all links by their unique identifiers.

4. It then filters the groups to include only those with more than one link and flattens the filtered groups into a list of link IDs.

5. Finally, the script iterates over each link in the network. If a link's ID is in the list, the script selects that link.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically select all bifurcation links in the network.