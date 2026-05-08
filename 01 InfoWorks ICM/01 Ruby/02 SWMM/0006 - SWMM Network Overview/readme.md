# SWMM Network Overview

**Script by Bob Dickinson.**
*This readme was AI-generated based on the contents of the script.*

---

This script produces a statistical overview of the key elements in an ICM SWMM network, printing formatted results to the ICM output window.

## What It Reports

### Nodes (`sw_node`)
- Total count, broken down by type: Junction, Storage, Outfall
- DWF counts: nodes with additional DWF baseline > 0, base flow > 0, inflow baseline > 0, inflow scaling > 0
- Mean / max / min for: invert elevation, ground level, full depth, initial depth, surcharge depth, ponded area

### Conduits (`sw_conduit`)
- Total count and total network length
- Mean / max / min for: conduit height, conduit width, Manning's n, upstream invert, downstream invert, number of barrels

### Subcatchments (`sw_subcatchment`)
- Total count and total catchment area
- Mean / max / min for: imperviousness (%), slope, width

### Other elements
- Count of pumps (`sw_pump`)
- Count of weirs (`sw_weir`)
- Count of orifices (`sw_orifice`)
- Count of outlets (`sw_outlet`)

## Usage

1. Open a SWMM network in ICM.
2. Run the script from the ICM UI. No selection is required.
3. Results are printed to the output window.

## Notes

- This script is specific to SWMM networks. All tables use the `sw_` prefix and will not work on InfoWorks networks.
- Original source attribution: https://github.com/chaitanyalakeshri/ruby_scripts
