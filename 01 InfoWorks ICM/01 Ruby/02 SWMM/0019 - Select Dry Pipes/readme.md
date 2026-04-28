# Select Dry Pipes (SWMM)

**Script adapted for ICM SWMM by Bob Dickinson.**
*This readme was AI-generated based on the contents of the script.*

Original source: https://github.com/chaitanyalakeshri/ruby_scripts

---

This script selects all "dry pipes" in an ICM SWMM network — links that do not receive flow from any subcatchment, either directly or via a connected path downstream of a subcatchment outlet.

## How it Works

1. Collects the outlet node IDs (`outlet_id`) from all subcatchments in the network.
2. Starting from each outlet node, performs a downstream graph walk — marking every link and node visited as "seen".
3. After the walk, any link that was **not** marked as seen has no upstream subcatchment contributing to it and is selected, along with its upstream node.

## Usage

1. Open a SWMM network in ICM.
2. Run the script. No selection is required beforehand.
3. All dry pipes and their upstream nodes will be selected in the network view.

## Notes

- This is the **SWMM-specific** version of this script. It uses `sw_node` and the `outlet_id` field from subcatchments, which are specific to SWMM networks.
- The equivalent InfoWorks version is in `01 InfoWorks\0059 - Select dry pipes\hw_dry pipes.rb`, which uses `hw_node` and the `node_id` field instead.
