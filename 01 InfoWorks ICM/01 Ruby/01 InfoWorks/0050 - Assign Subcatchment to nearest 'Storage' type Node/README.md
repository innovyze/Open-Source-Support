# Ruby Script for Connecting Subcatchments to the Nearest Storage Node in InfoWorks ICM

This Ruby script is used to connect each subcatchment to the nearest storage node in the InfoWorks ICM software. Here's a summary of what it does:

- It first sets up the current network (`net`) and begins a transaction.

- It then iterates over each subcatchment in the network.

- For each subcatchment, it checks if the `node_id` field is blank.

- If the `node_id` field is blank, it retrieves the X and Y coordinates of the subcatchment and sets a default distance (`di`) to a large number.

- It then iterates over each node in the network.

- For each node, it checks if the node type is "storage".

- If the node type is "storage", it calculates the distance from the subcatchment to the node.

- If the calculated distance is less than the current smallest distance (`di`), it updates the smallest distance and the ID of the nearest node (`dischargeNode`).

- After iterating over all nodes, it prints the ID of the subcatchment and the ID of the nearest node.

- It then sets the `node_id` field of the subcatchment to the ID of the nearest node and writes the changes to the subcatchment.

- After iterating over all subcatchments, it commits the transaction.