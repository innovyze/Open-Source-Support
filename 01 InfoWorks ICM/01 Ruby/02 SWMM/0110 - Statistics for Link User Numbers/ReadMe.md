Ruby Script: Statistical Analysis of SWMM Network Nodes
This script is designed to perform a statistical analysis on a set of fields related to SWMM network nodes in the InfoWorks ICM application.

The script begins by defining a list of database fields for SWMM network nodes. These fields include various user-defined numbers and physical properties of the nodes such as 'us_invert', 'ds_invert', 'length', 'conduit_height', 'conduit_width', and 'number_of_barrels'.

The script then clears any current selection in the network and prints the current scenario.

Next, it prepares a hash to store the data for each field. It initializes the count of processed rows and the total expected value.

The script then iterates over each object in the 'sw_conduit' table of the network. For each object, it collects the data for each field and stores it in the hash.

After collecting the data, the script calculates and prints the minimum, maximum, mean, standard deviation, total, and row count for each field. If a field has no data, it skips the calculations for that field.

Finally, the script is run on the current network, performing the statistical analysis and printing the results.

This script provides a useful tool for analyzing the properties of SWMM network nodes in an InfoWorks ICM network.