# ICM Infoworks and SWMM Network Comparison Tool for Nodes

## Overview
This script compares selected attributes between InfoWorks HW Nodes and SWMM SW Nodes in ICM networks.

## Key Components

1. **Network Setup**
   - `cn`: Current network (ICM Infoworks Network)
   - `bn`: Background network (ICM SWMM Network)

2. **Node Collections**
   - `cn_nodes`: HW nodes from current network
   - `bn_nodes`: SW nodes from background network

3. **User Interface**
   - Prompts user to select attributes for comparison
   - Displays informational messages about the tool's functionality

4. **Attribute Pairs for Comparison**
   - ground_level
   - chamber_floor vs. invert_elevation
   - flood_level vs. surcharge_depth
   - maximum_depth
   - floodable_area vs. ponded_area
   - chamber_area vs. min_surfarea
   - shaft_area vs. min_surfarea

5. **Comparison Process**
   - Loops through selected attributes
   - Creates a hash map of SW attributes by node_id
   - Compares HW attributes to SW attributes using node_id
   - Calculates and displays differences

6. **Output**
   - Displays nodes with difference percentage > 0.1%
   - Shows totals for each network and the difference
   - Provides statistics on comparisons:
     - Number of comparisons below 0.1%
     - Total number of comparisons
     - Percentage of comparisons below 0.1%

## Special Handling
- Handles 'min_surfarea' with a fixed value of 12.566
- Calculates 'surcharge_depth' based on conditions
- Computes 'maximum_depth' for HW nodes

## Note
The script reminds users that "CN is the ICM Infoworks Network and BN is the ICM SWMM Network" at the beginning and end of execution.