# Dijkstra's Shortest Path Algorithm for InfoWorks ICM

This script implements Dijkstra's algorithm to find the shortest path between two selected nodes in an InfoWorks ICM model network.

## How it Works

1. The script first defines the `dijkstra` function, which implements Dijkstra's algorithm. This function takes a start node and a target node ID as arguments.

2. It initializes two arrays and two hashes to keep track of the working set of nodes and the set of calculated nodes.

3. The function then sets the value of the start node to 0 and its from node and link to `nil`.

4. It adds the start node to the working set and begins a loop that continues until the working set is empty.

5. In each iteration of the loop, the function finds the node in the working set with the smallest value, removes it from the working set, and adds it to the calculated set.

6. If this node is the target node, the function returns it.

7. Otherwise, the function loops through each link connected to the current node. For each link, it calculates the new value for the connected node and updates its value, from node, and link if the new value is smaller.

8. After defining the `dijkstra` function, the script accesses the current network and retrieves the selected nodes. It raises an error if exactly two nodes are not selected.

9. The script then calls the `dijkstra` function with the two selected nodes as arguments.

10. Finally, it selects the nodes and links in the shortest path found by the `dijkstra` function.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM with two nodes selected. The script will automatically find and select the shortest path between the two nodes.