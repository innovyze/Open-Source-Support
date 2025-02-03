## sonnet_exchange_centroid_bn_cn_networks.md
This Ruby script is designed to interact with two network datasets: a current network and a background network. It performs various operations to compare, copy, and analyze data between these networks.

First, the script attempts to retrieve the current and background networks using WSApplication.current_network and WSApplication.background_network. If no background network is loaded, it prints a message and exits. Otherwise, it confirms that the background network is loaded.

The compare_nodes method compares nodes between the current and background networks. It iterates through nodes in the current network and checks if corresponding nodes exist in the background network. If a node exists in both networks but has different ground levels, it prints the differences. If a node exists only in the current network, it notes this as well.

The copy_node_data method copies specific data fields from nodes in the background network to corresponding nodes in the current network. It begins a transaction, iterates through nodes, and updates the specified field if there is a difference. After making the updates, it commits the transaction.

The find_unique_objects method identifies objects that are unique to each network. It retrieves objects from both networks, converts their IDs to sets, and calculates the differences. It then prints the IDs of objects unique to each network.

The find_nearby_objects method searches for objects within a specified distance from a given point (x, y) in both networks. It prints the number of objects found in each network within the specified distance.

The distance method calculates the Euclidean distance between two points (x1, y1) and (x2, y2).

The find_centroid_and_farthest_distance method calculates the centroid of nodes in a given table and finds the farthest distance from this centroid to any node. It sums the coordinates of all nodes to find the centroid and then calculates the maximum distance from the centroid to any node.

Finally, the script demonstrates the usage of these methods. It compares nodes, copies ground level data, finds unique objects, calculates the centroid and farthest distance, and finds nearby objects based on the centroid and farthest distance.