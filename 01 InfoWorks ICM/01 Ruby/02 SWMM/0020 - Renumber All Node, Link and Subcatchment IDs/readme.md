# Renumber All Node, Link and Subcatchment IDs (SWMM)

**Script adapted for ICM SWMM by Bob Dickinson.**
*This readme was AI-generated based on the contents of the script.*

Original source: https://github.com/chaitanyalakeshri/ruby_scripts

---

This script renumbers all nodes, links, and subcatchments in an ICM SWMM network with sequential IDs using a consistent prefix format (`N_1`, `N_2`, ... for nodes; `L_1`, `L_2`, ... for links; `S_1`, `S_2`, ... for subcatchments).

## How it Works

1. Retrieves all nodes, links, and subcatchments from the current SWMM network.
2. Iterates through each object collection and assigns a new sequential ID with the appropriate prefix.
3. All changes are wrapped in a transaction — if any error occurs the changes are not committed.

## Usage

1. Open a SWMM network in ICM.
2. Run the script. All objects will be renumbered immediately.
3. The number of IDs changed for each object type is printed to the output window.

## Notes

- This is the **SWMM-specific** version. It renumbers **nodes, links, and subcatchments**.
- The equivalent InfoWorks version is in `01 InfoWorks\0068 - Change All Node, Subs and Link IDs\hw_change All Node, Link and Subs ID.rb`. That version has the link renumbering **commented out** — this SWMM version renumbers links as well.
- Use with caution — this will permanently change all object IDs in the network. Ensure the network is backed up before running.
