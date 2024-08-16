# ICM Infoworks and SWMM Network Comparison Tool for Conduits

## Overview
This Ruby script compares selected attributes between InfoWorks HW Conduits and SWMM SW Conduits in ICM networks.

## Key Components

1. **Network Setup**
   - `cn`: Current network (ICM Infoworks Network)
   - `bn`: Background network (ICM SWMM Network)

2. **Conduit Collections**
   - `cn_conduits`: HW conduits from current network
   - `bn_conduits`: SW conduits from background network

3. **User Interface**
   - Prompts user to select attributes for comparison
   - Displays informational messages about the tool's functionality

4. **Attribute Pairs for Comparison**
   - conduit_length vs. length
   - conduit_height
   - conduit_width
   - number_of_barrels
   - us_invert
   - ds_invert
   - us_headloss_coeff
   - ds_headloss_coeff
   - bottom_roughness_N vs. Mannings_N
   - top_roughness_N vs. Mannings_N

5. **Comparison Process**
   - Loops through selected attributes
   - Creates a hash map of SW attributes by conduit_id
   - Compares HW attributes to SW attributes using conduit_id
   - Calculates and displays differences

6. **Output**
   - Displays conduits with difference percentage > 0.1%
   - Shows totals for each network and the difference
   - Provides statistics on comparisons:
     - Number of comparisons below 0.1%
     - Total number of comparisons
     - Percentage of comparisons below 0.1%

## Note
The script reminds users that "CN is the ICM Infoworks Network and BN is the ICM SWMM Network" at the beginning and end of execution.