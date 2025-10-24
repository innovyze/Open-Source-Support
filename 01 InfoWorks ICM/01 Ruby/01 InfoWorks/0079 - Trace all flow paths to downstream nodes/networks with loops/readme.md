# Finding ALL Contributing Upstream Paths in Networks with Loops

## Quick Reference

**Script:** `Trace All Contributing Upstream Paths (DFS).rb`  
**Purpose:** Identify complete contributing upstream drainage area to selected downstream points  
**Use when:** Your network has loops/bifurcations and you need ALL paths (not just shortest)

---

## Overview

This subfolder contains a script specifically designed for drainage networks with **loops, bifurcations, or multiple flow paths** where you need to identify the **complete contributing upstream area** to selected downstream points.

The parent folder scripts use Dijkstra's shortest path algorithm, which only finds **ONE optimal path**. In networks where flow bifurcates and later rejoins (forming loops), alternative upstream contributing routes will be **missed**.

This script uses **Depth-First Search (DFS)** to find **ALL possible upstream contributing paths** and combines them into a single comprehensive selection showing the complete drainage area.

---

## When to Use This Script

**Use this script when:**
- Your network has bifurcations that rejoin downstream (loops)
- You need to identify the COMPLETE contributing upstream drainage area
- Multiple upstream flow routes converge at your point of interest
- You want comprehensive coverage for drainage area analysis
- Traditional "trace upstream" misses some contributing areas

**Use the parent folder scripts when:**
- Your network is a simple tree structure (no loops)
- You only need the primary/shortest contributing path
- Performance is critical (DFS is slower than Dijkstra)

---

## Script Details

### `Trace All Contributing Upstream Paths (DFS).rb`

**Purpose:** Identify the complete contributing upstream area to selected downstream node(s)

**Algorithm:** Depth-First Search with backtracking and cycle detection

**Direction:** Traces from terminal upstream nodes → downstream to your selected points (identifies contributing area)

**Key Features:**
- Automatically finds all terminal upstream nodes (sources with no upstream links)
- Finds ALL downstream paths from each source to your selected node(s)
- Combines all found paths into ONE selection list per source-destination pair
- Shows complete contributing upstream area including all bifurcation branches
- Prevents infinite loops with cycle detection
- Safety limits to prevent exponential explosion in complex networks

**Usage:**
1. Select one or more downstream nodes (outfalls, monitoring points, etc.)
2. Run script
3. Script automatically finds all terminal upstream nodes (sources)
4. For each source, traces all possible downstream routes to your selected point
5. Creates one selection list per source-destination combination showing complete contributing area

**Safety Limits:**
```ruby
@max_depth = 256   # Maximum path length (number of nodes)
@max_paths = 16    # Maximum number of paths per source-destination pair | 3 loops = 16 paths
```

**Output:**
- One selection list per source-destination pair
- Naming format: `AllPaths_<source_id>_to_<destination_id>`
- Contains ALL nodes and links from ANY upstream contributing path (combined)
- Shows the COMPLETE contributing upstream area

---

## How It Works

### The Problem: Missed Contributing Areas

**Dijkstra (parent folder scripts):**
```
Source A → Node B → Node C → Your Selected Point E
              ↓               ↑
           Node D -------------+
           (Alternative contributing route)

Result: Only finds A→B→C→E (shortest path)
MISSES: Contributing area through D
Incomplete drainage area analysis!
```

**DFS (this script):**
```
Source A → Node B → Node C → Your Selected Point E
              ↓               ↑
           Node D -------------+
           (Alternative contributing route)

Result: Finds BOTH contributing routes
Selection includes: A, B, C, D, E, and all connecting links
COMPLETE contributing upstream area!
```

### Algorithm Steps

1. **User selects** downstream point(s) of interest (outfalls, monitoring points, etc.)
2. **Script finds** all terminal upstream sources (nodes with no upstream links)
3. **For each source→destination pair:**
   - Start DFS from the upstream source
   - Recursively explore all downstream paths toward your selected point
   - Use `visited_in_path` hash to detect cycles
   - Stop when reaching your selected downstream point
   - Backtrack and explore alternative contributing branches
   - Combine all found contributing paths into one selection
4. **Create selection list** showing complete contributing area with all nodes/links
5. **Save** to parent Model Group

### Cycle Detection

To prevent infinite loops in circular networks:
- Maintains `visited_in_path` hash during each recursive call
- Marks nodes as visited when entering
- Removes from visited when backtracking
- This allows nodes to be visited in different paths, but prevents loops within a single path

---

## Usage Example

1. **Select downstream point(s):**
   - Click one node (e.g., outfall), or hold Ctrl to select multiple
   - These are the points where you want to know the complete contributing upstream area

2. **Run the script:**
   - Script automatically finds all upstream sources (terminal nodes)
   - Traces all possible downstream routes from each source to your selected point(s)
   - Shows progress for each source→destination combination

3. **Review results:**
   - Refresh the database tree
   - Selection lists appear in the parent Model Group
   - Each list shows the COMPLETE contributing upstream area for that source

---

## Example Output

```
Selected 1 downstream node(s):
  - Outfall_Main

Finding terminal upstream nodes...
Found 5 terminal upstream node(s)

Safety limits: max_depth=256, max_paths=16

Processing: Source_101 -> Outfall_Main
  Found 3 path(s)
  Combined selection: 15 nodes, 14 links
  Created selection list: 'AllPaths_Source_101_to_Outfall_Main'

Processing: Source_102 -> Outfall_Main
  Found 2 path(s)
  Combined selection: 8 nodes, 7 links
  Created selection list: 'AllPaths_Source_102_to_Outfall_Main'

Processing: Source_103 -> Outfall_Main
  Found 1 path(s)
  Combined selection: 5 nodes, 4 links
  Created selection list: 'AllPaths_Source_103_to_Outfall_Main'

...

============================================================
SUMMARY
============================================================
Terminal upstream nodes: 5
Selected downstream nodes: 1
Total combinations processed: 5
Total individual paths found: 12
Combinations hitting path limit: 0
Successfully created selection lists: 5

Refresh the database tree to view the new selection lists.
============================================================
```

**Result:** You now have 5 selection lists, each showing the complete contributing area from each upstream source to your outfall, including all bifurcation branches!

---

## Performance Considerations

**Time Complexity:** O(V! × E) in worst case - exponential in highly connected networks. Safety limits prevent runaway execution.

**Memory Usage:** Each path stores node/link references. With defaults (max_paths=16, max_depth=256), approximately 4096 node references per source-destination pair.

**Adjusting Safety Limits:**

| Scenario | Action | Typical Values |
|----------|--------|----------------|
| Long drainage networks (>256 nodes per path) | Increase `@max_depth` | 256-1024 |
| Highly interconnected networks needing all paths | Increase `@max_paths` | 16-64 |
| Script too slow or high memory usage | Decrease both limits | 8-128 |

**Note:** Doubling `@max_paths` can increase execution time 10x in complex networks.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **"No path found" warnings** | Verify downstream path exists from source to selected point; check ds_links connectivity |
| **Script hits max_paths limit** | Network is highly interconnected; increase `@max_paths` to 32 or 64 for complete coverage |
| **Script runs very slowly** | Reduce `@max_paths` for faster execution, or run overnight for comprehensive analysis |
| **Memory errors** | Reduce `@max_paths` or `@max_depth`; process fewer downstream nodes at once |
| **No terminal nodes found** | Check network has source nodes (no upstream links); verify topology |

---

## Limitations

1. **Exponential Complexity:** Number of possible paths can explode in densely connected networks
2. **Safety Limits:** May not find all paths if network exceeds max_depth or max_paths
3. **Memory Usage:** Storing many long paths can consume significant memory
4. **Flow Direction:** Traces downstream from sources to selected points (identifies contributing area)

---

## Script Customization

To modify safety limits, edit the script:

```ruby
def initialize
  @net = WSApplication.current_network
  @db = WSApplication.current_database
  @max_depth = 512   # Increase for longer paths
  @max_paths = 32    # Increase for more paths
end
```

Generated using AI