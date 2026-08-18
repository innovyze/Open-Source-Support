# InfoWorks vs SWMM Comparison Tools

**Scripts by Bob Dickinson.**
*This readme was AI-generated based on the contents of the scripts.*

---

This folder contains scripts for comparing network data between an ICM InfoWorks network and an ICM SWMM network open simultaneously in the same ICM session. All scripts use the **current network** (InfoWorks, `hw_` tables) and the **background network** (SWMM, `sw_` tables).

---

## Scripts

### Diagnostic

#### `ICM InfoWorks vs ICM SWMM Subcatchment.rb`
A lightweight first-pass diagnostic. Prints the names of both networks, lists available tables in each, and counts/prints the first few IDs from `hw_subcatchment` (InfoWorks) and `sw_subcatchment` (SWMM). Use this to confirm both networks are open and accessible before running the deeper comparison scripts.

---

### Node Comparison

#### `Compare InfoWorks to SWMM for Nodes.rb` · `Compare InfoWorks to SWMM for Nodes.md`
Prompts the user to select one or more node attributes to compare between `hw_node` (InfoWorks) and `sw_node` (SWMM), matched by `node_id`. For each selected attribute pair:

| InfoWorks (`hw_node`) | SWMM (`sw_node`) |
|---|---|
| `ground_level` | `ground_level` |
| `chamber_floor` | `invert_elevation` |
| `flood_level` | `surcharge_depth` (+ `invert_elevation`) |
| `maximum_depth` | `maximum_depth` |
| `floodable_area` | `ponded_area` |
| `chamber_area` / `shaft_area` | `min_surfarea` (hardcoded 12.566) |

Prints per-node differences (where > 0.1%), totals for each network, the absolute difference, and the percentage of matched nodes within the 0.1% threshold.

#### `current_background_node_compare.rb`
An alternate node comparison with a different attribute set (X/Y coordinates, ground level, flooding discharge coefficient, chamber floor vs invert elevation). Uses the same current/background network pattern and ID-based matching. Complements the above for spatial and geometry checks.

---

### Conduit/Link Comparison

#### `Compare InfoWorks to SWMM for Links.rb` · `Compare InfoWorks to SWMM for Links.md`
Prompts the user to select conduit attributes to compare between `hw_conduit` (InfoWorks) and `sw_conduit` (SWMM), matched by `asset_id`. Attribute pairs:

| InfoWorks (`hw_conduit`) | SWMM (`sw_conduit`) |
|---|---|
| `conduit_length` | `length` |
| `conduit_height` | `conduit_height` |
| `conduit_width` | `conduit_width` |
| `number_of_barrels` | `number_of_barrels` |
| `us_invert` / `ds_invert` | `us_invert` / `ds_invert` |
| `us_headloss_coeff` / `ds_headloss_coeff` | same |
| `bottom_roughness_N` / `top_roughness_N` | `Mannings_N` |

Prints per-conduit differences (where > 0.1%), totals, and the match rate within 0.1%.

#### `current_background_conduit_compare.rb`
An alternate conduit comparison script. Covers a similar attribute set using the same pattern as its node counterpart above. Useful as a cross-check or alternative prompt layout.

---

### Subcatchment & Inflow Comparison

#### `Compare InfoWorks to SWMM for Subcatchment and Node Inflows.rb` · `Compare InfoWorks to SWMM for Subcatchment and Node Inflows.md`
Compares `hw_subcatchment` (InfoWorks) flow fields to `sw_node` (SWMM) inflow fields, matched by ID. The user selects which cross-network field pairs to compare, including population, trade_flow, base_flow, and additional_foul_flow against sw_node `base_flow`, `inflow_baseline`, and `additional_dwf`. Prints matched values and differences.

#### `Compare ICM trade flow to SWMM Base Flow.rb`
Compares `hw_subcatchment.trade_flow` (InfoWorks) to `sw_node.base_flow` (SWMM) for all matched IDs, and also reports totals for `base_flow`, `additional_foul_flow`, `population`, and `population_flow` from the InfoWorks subcatchments.

Has two optional actions via prompt:
- **Set trade_flow to base_flow** — writes `sw_node.base_flow` back into `hw_subcatchment.trade_flow` in the InfoWorks network (commits a transaction).
- **Make ICM Subcatchments from ICM SWMM Nodes** — creates new `hw_subcatchment` objects in the InfoWorks network from SWMM Junction nodes, copying `node_id`, `trade_flow` (from `base_flow`), and XY coordinates. Sets `total_area = 1.0` as a placeholder.

---

### Full Parameter Comparison

#### `Model_Evaluation_Logic.rb`
The comprehensive v2.2 master comparison script. Structured into 12 sections covering InfoWorks subcatchment grid, land use hierarchy, runoff surface grid, SWMM physical properties, infiltration parameters, infiltration model detection, advanced parameter tracing (with `surface_type`-based pervious/impervious matching), area distribution analysis, extended parameter comparison, parameter mapping reference, mismatch summary, and CSV export.

**Key v2.2 fix:** uses `hw_runoff_surface.surface_type` keyword patterns to correctly identify pervious/impervious surfaces rather than assuming slot order.

**Configuration constants at the top of the file:**

| Constant | Default | Description |
|---|---|---|
| `PAGE_WIDTH` | `180` | Output line width |
| `TOLERANCE` | `0.001` | Mismatch threshold |
| `EXPORT_CSV` | `true` | Set `false` to disable CSV |
| `CSV_PATH` | `C:/Temp/ICM_Comparison_Report.csv` | Output path — **change before running** |

---

### Network Geometry & Spatial Utilities

#### `sonnet_exchange_centroid_bn_cn_networks.rb` · `sonnet_exchange_centroid_bn_cn_networks.md`
A multi-function cross-network utility operating on the current (InfoWorks, `hw_node`) and background (SWMM, `sw_node`) networks. Provides four capabilities:

- **`compare_nodes`** — iterates `hw_node` in the current network, finds the matching `sw_node` in the background by ID, and prints any ground level differences or IDs that exist in only one network.
- **`copy_node_data`** — copies a specified field from `sw_node` (background) to `hw_node` (current) for all matched IDs, wrapped in a transaction.
- **`find_unique_objects`** — reports IDs present in one network but not the other, for any two named tables.
- **`find_centroid_and_farthest_distance`** / **`find_nearby_objects`** — calculates the geometric centroid of all nodes in a given table and the maximum distance to any node, then uses those values to do a spatial proximity search across both networks.

The script runs all four operations in sequence as a demonstration. Edit the method calls at the bottom to use selectively.

---

## Usage

1. Open both an InfoWorks network (as current) and a SWMM network (as background) in ICM.
2. Run `ICM InfoWorks vs ICM SWMM Subcatchment.rb` to verify both networks are accessible.
3. Use the `Compare...` scripts for interactive attribute-by-attribute comparisons of nodes, conduits, or subcatchment inflows.
4. Run `Model_Evaluation_Logic.rb` for the full subcatchment parameter comparison with CSV export.
