# Dry Pipes

This Ruby script selects all dry pipes in an ICM model network. It starts by clearing any previous selections in the network and creates an array to store the drainage node IDs of the subcatchments. Then, it collects all the subcatchments' drainage node IDs and proceeds to find unprocessed links using a depth-first search algorithm.

The script iterates through each drainage node ID, following the downstream links, and marking them as seen to avoid duplication. It continues the search until all downstream nodes are processed. Finally, it selects all the dry pipes by iterating through all links in the network that have not been processed during the depth-first search. It selects both the link and its upstream node and displays a message indicating the selected node. The script helps identify and work with dry pipes in the ICM model network.

# Dry Pipes Selection Script

This script selects all dry pipes in an InfoWorks ICM model network. A dry pipe is defined as a pipe that is not connected to any subcatchment.

## How it Works

1. The script first clears any existing selection in the network.

2. It initializes an array to store the drainage node IDs of subcatchments.

3. It iterates over each subcatchment in the network, adding the node ID of each subcatchment to the array.

4. For each node ID in the array, it selects the corresponding node in the network and adds all downstream links from that node to a list of unprocessed links.

5. It then enters a loop that continues until all links have been processed. In each iteration of the loop, it removes a link from the list of unprocessed links, marks it as seen, and if the downstream node of the link has not been seen and is not nil, it marks that node as seen and adds all downstream links from that node to the list of unprocessed links.

6. Finally, it iterates over each link in the network. If a link has not been seen (indicating that it is a dry pipe), it selects that link and its upstream node in the network and prints a message indicating the node ID.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically select all dry pipes and their upstream nodes in the network.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks