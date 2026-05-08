# DWF Statistics for SWMM Nodes

**Scripts by Bob Dickinson.**
*This readme was AI-generated based on the contents of the scripts.*

---

These two companion scripts calculate statistics for Dry Weather Flow (DWF) data on SWMM nodes. Both iterate over `sw_node` objects in the current network and report min, max, mean, standard deviation, and total for the collected values.

## Scripts

### `sw_UI_Script_additional_dwf_nodes_icm_swmm.rb`

The more complete of the two scripts. Collects both `base_flow` and `additional_dwf.baseline` values from every node and reports statistics for three datasets:

- **base_flow** — the constant dry weather base flow assigned directly to each node
- **additional_baseline** — the baseline value from each node's additional DWF entries
- **Combined** — both datasets concatenated together

All values are reported in MGD.

### `sw_UI_Script_Calculate statistics for baseline data.rb`

Focuses solely on `additional_dwf.baseline` values. Also prints the node ID and `bf_pattern_1` field for each node as it is processed, which can help with spot-checking individual values. Reports statistics in both **MGD and GPM**.

## Usage

1. Open a SWMM network in ICM with DWF data populated on nodes.
2. Run either script from the ICM UI. Results are printed to the output window.
3. No selection is required — both scripts process all nodes in the network.

## Notes

- The two scripts complement each other: use `sw_UI_Script_additional_dwf_nodes_icm_swmm.rb` for a combined `base_flow` + `additional_dwf` overview, and `sw_UI_Script_Calculate statistics for baseline data.rb` when you need GPM output or per-node diagnostic printing.
- Both scripts are specific to SWMM networks (`sw_node`). They will not work on InfoWorks networks without substituting the appropriate table name.
