# Summary of sw_UI_Script.rb

This script performs several operations on a network of conduits in the `WSApplication`.

## Steps

1. **Initialize the network and clear selection**: The script first gets the current network and clears any existing selection.

2. **Calculate link lengths**: The script then iterates over each conduit in the network. For each conduit, it calculates its length and stores these values in an array.

3. **Sort link lengths**: The array of link lengths is sorted.

4. **Define percentiles**: A set of percentiles is defined.

5. **Calculate threshold lengths**: The script calculates the threshold lengths for each percentile. These are the lengths at which the given percentage of links are shorter.

6. **Initialize arrays for selected links**: Arrays are initialized to store the links that are below each threshold.

7. **Select links below thresholds**: The script iterates over each conduit in the network again. For each conduit, it checks if its length is below each threshold. If it is, it adds the conduit to the corresponding array and selects it in the network.

8. **Calculate total length**: The total length of all links is calculated.

9. **Calculate total number of links**: The total number of conduits in the network is calculated.

10. **Print results**: The script prints the minimum and maximum link lengths, the threshold lengths for each percentile, the number of links below each threshold, the total length of all links, and the total number of links.

11. **Handle no selection**: If no links were selected (i.e., all links are above all thresholds), the script prints a message saying "No links were selected."