# InfoWorks SWMM Networks and the Length of Links

These Ruby scripts are intended to work with the InfoWorks SWMM network and InfoWorks Networks

##SW is SWMM
##HW is ICM or its grandfather HydroWorks

The given code snippet is designed to identify and select the smallest 10 percent of link lengths within a network, presumably in a hydraulic modeling application. Here's a summary of its functionality:

Initialize Network and Variables: The current network is accessed, and the selection is cleared. An empty array link_lengths is initialized to store the lengths of the links.

Collect Link Lengths: The code iterates through all objects in 'sw_conduit' (presumably stormwater conduits), collecting their lengths and storing them in the link_lengths array.

Calculate Threshold Length: The threshold length for the lowest 10 percent of links is calculated. It is determined by finding the range of link lengths (maximum - minimum) and taking 10 percent of that range, added to the minimum length.

Select Links Below Threshold: The code again iterates through the 'sw_conduit' objects, selecting those whose lengths are below the calculated threshold. The selected links are stored in the selected_links array.

Print Results or Message: If any links are selected, the code prints out the following information:

Minimum link length
Maximum link length
Threshold length for the lowest 10 percent
Number of links below the threshold
Total number of links
If no links were selected, a message stating "No links were selected." is printed.
In essence, the code is a utility for analyzing the distribution of link lengths within a network, specifically focusing on the shortest 10 percent of links. It could be useful for identifying areas of the network that may have specific design characteristics or performance implications.