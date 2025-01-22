# Trace Upstream of Selected Nodes

The script automates the process of identifying and selecting all subcatchments that are upstream of a given set of selected nodes within a network. This helps in understanding the drainage patterns and the areas contributing to the flow at specific nodes. 

1. Network Analysis Initialization:
The script starts by initializing the current network and fetching all subcatchments and nodes within that network.
2. Mapping Subcatchments to Nodes:
It creates a mapping between nodes and their corresponding subcatchments, ensuring that each node is associated with the subcatchments that drain into it.
3. Node Selection and Validation:
The script retrieves the nodes that the user has selected. If no nodes are selected, it displays an error message and stops further execution.
4. Upstream Link Processing:
For each selected node, the script processes upstream links and nodes to identify and select all subcatchments that are upstream of the selected nodes.
5. Result Output:
Finally, it outputs a list of the nodes for which upstream subcatchments were selected, as well as the total count of selected subcatchments.