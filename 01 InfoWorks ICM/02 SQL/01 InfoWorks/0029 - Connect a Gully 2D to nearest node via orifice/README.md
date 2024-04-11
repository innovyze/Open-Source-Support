# Orifice Creation Script for InfoWorks ICM

This SQL script creates new orifices in an InfoWorks ICM model network. The orifices are created between nodes that are within a certain distance of each other and have a specific flood type.

## How it Works

The script operates in several steps:

1. **Node Selection**: The script selects all nodes where the flood type is "Gully 2d" and stores their object IDs (`oid`) in a list (`$NodeID`).

2. **Orifice Creation Loop**: The script enters a loop where it selects each node in the `$NodeID` list one by one. For each selected node, it retrieves the node ID (`node_id`) and the ID of the nearest node (`user_text_1`). It then inserts a new record into the 'orifice' table with these two IDs as the upstream and downstream node IDs (`us_node_id` and `ds_node_id`), and "X" as the link suffix.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically create new orifices between nodes that are within a certain distance of each other and have a flood type of "Gully 2d".

## SQL Dialog
![](img001.png)
