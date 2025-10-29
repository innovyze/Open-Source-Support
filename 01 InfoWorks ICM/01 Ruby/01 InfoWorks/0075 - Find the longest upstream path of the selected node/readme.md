# Find the Longest Upstream Path of the Selected Node

This script identifies and highlights the longest upstream flow path from a selected node in the network, based on conduit lengths.

## How it Works

1. **Node Selection**: The script checks for a selected node. If no node is selected or multiple nodes are selected, it provides appropriate feedback.

2. **Build Upstream Network**: Creates a map of all upstream conduits for each node in the network.

3. **Recursive Search**: Uses a recursive algorithm to traverse all upstream paths from the selected node, calculating the total length of each path.

4. **Find Maximum**: Determines which upstream path has the greatest total conduit length.

5. **Display Results**: Outputs the total length and detailed information about each link in the longest path.

6. **Highlight Path**: Automatically selects all conduits in the longest upstream path in the network for easy visualization.

## Usage

1. Select a single node in your network.
2. Run the script.
3. The script will display the longest upstream path details in the output window.
4. The conduits in the longest path will be highlighted (selected) in the network.

## Output Information

- Total length of the longest upstream path
- Number of links in the path
- Detailed list of each link including: Link ID, upstream node, downstream node, and length

---
*Generated using AI*
