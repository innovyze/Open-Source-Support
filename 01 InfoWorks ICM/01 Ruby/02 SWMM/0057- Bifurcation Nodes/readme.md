# Bifurcation Nodes Selection Script

This script selects all bifurcation nodes in an InfoWorks ICM model network. A bifurcation node is defined as a node that is used as the upstream node (`us_node_id`) for more than one link in the network.

## How it Works

1. The script first clears any existing selection in the network.

2. It initializes a hash to store the count of occurrences for each upstream node ID (`us_node_id`).

3. It iterates over each link in the network, incrementing the count for the upstream node ID of each link in the hash.

4. Finally, it iterates over each entry in the hash. If the count for a node ID is greater than 1 (indicating that the node is a bifurcation node), it selects that node in the network and prints a message indicating the node ID and the number of occurrences in the links.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically select all bifurcation nodes in the network.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks