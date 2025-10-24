# Trace All Flow Paths to Downstream Nodes

Two scripts for automatically tracing paths from terminal upstream nodes to selected target node(s).

**IMPORTANT:** These scripts use **shortest path algorithms** (Dijkstra). They will only find ONE path between nodes, even if multiple paths exist. For networks with **loops or bifurcations**, see the **[networks with loops](./networks%20with%20loops/)** subfolder for an alternative approach that finds ALL paths.

---

## Script 1: Trace All Paths (Upstream).rb

Traces flow paths that follow the downstream direction only.

### Usage
1. Select one or more downstream nodes (e.g., outfalls)
2. Hold `Ctrl` to select multiple nodes
3. Run the script

### Key Features
- **Follows flow direction**: Only traces downstream (respects link direction)
- **Shortest path algorithm**: Uses Dijkstra - finds one optimal path
- **Automatic terminal node detection**: Finds all terminal upstream nodes
- **Best for**: Gravity drainage systems without loops

### Limitations
- Only finds the **shortest path** - will miss alternative routes in networks with loops
- For complete path coverage, use the script in the "networks with loops" subfolder

### Example Output
```
Selected 1 downstream node(s):
  - Storm_Outfall

Finding terminal upstream nodes...
Found 127 terminal upstream node(s)

Processing path 1: INLET001 -> Storm_Outfall
  Path found: 8 nodes, 7 links
  Created selection list: 'Path_INLET001_to_Storm_Outfall'
```

### Use Cases
- Autoprofiling (simple networks)
- Catchment analysis by outfall
- Flow path identification for gravity systems

---

## Script 2: Trace All Paths (Bidirectional).rb

Traces paths using bidirectional search (both upstream and downstream).

### Usage
1. Select one or more target nodes
2. Hold `Ctrl` to select multiple nodes
3. Run the script

### Key Features
- **Bidirectional search**: Finds ANY connected path, even going upstream then back downstream
- **Shortest path algorithm**: Uses Dijkstra - finds one optimal path
- **More permissive**: Useful for complex networks with pumping

### Limitations
- Only finds the **shortest path** - will miss alternative routes
- For complete path coverage, use the script in the "networks with loops" subfolder

### When to Use
- Finding any topological connection between nodes
- Networks with pumping stations
- Analyzing complex network connectivity

---

## Comparison

| Feature | Upstream Script | Bidirectional Script |
|---------|-----------------|----------------------|
| **Search Direction** | Downstream only | Both directions |
| **Path Type** | Flow-following paths | Any connected path |
| **Algorithm** | Dijkstra (shortest path) | Dijkstra (shortest path) |
| **Best For** | Gravity drainage | Complex networks |
| **Handles Loops?** | No (shortest only) | No (shortest only) |

---

## For Networks with Loops

If your network has **bifurcations that rejoin** (loops), these scripts will only find the shortest route. To find **all possible flow paths**, see:

**[networks with loops](./networks%20with%20loops/)** - Contains scripts that find ALL paths through the network

Generated using AI