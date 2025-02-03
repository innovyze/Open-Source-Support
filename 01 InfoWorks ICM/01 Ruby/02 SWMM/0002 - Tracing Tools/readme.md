# Total Area Calculation Script for Selected Subcatchments in InfoWorks ICM SWMM

This script calculates the total area of all selected subcatchments in an InfoWorks ICM SWMM model network.

## How it Works

1. The script first accesses the current network.

2. It then initializes a total area counter and a subcatchment count to zero.

3. The script retrieves all subcatchments in the network and iterates over each one.

4. If a subcatchment is selected, its area is added to the total area and the subcatchment count is incremented.

5. After all subcatchments have been processed, the script prints the total area of all selected subcatchments (formatted to three decimal places) and the number of selected subcatchments.

6. If the total area is zero, the script prints a message indicating that no subcatchments were selected or that none of the selected subcatchments have a non-zero area.

                                Total Area: 3107.387
                                Number of selected subcatchments: 168
                                Thank you for using Ruby in ICM SWMM

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM SWMM with some subcatchments selected. The script will automatically calculate the total area of all selected subcatchments and print the total area, the number of selected subcatchments, and a thank you message.
