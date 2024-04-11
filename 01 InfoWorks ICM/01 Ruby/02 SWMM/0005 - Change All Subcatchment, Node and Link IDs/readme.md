# Node and Link ID Change Script for InfoWorks ICM

This script changes all node and link IDs in an InfoWorks ICM model network.

## How it Works

1. The script first accesses the current network.

2. It then begins a transaction to make changes to the network.

3. The script retrieves all nodes and links in the network.

4. It then iterates over each node, changing its ID to a new format ("N" followed by a number) and writing the changes to the network.

5. The script does the same for each link, changing its ID to a new format ("L" followed by a number).

6. After all IDs have been changed, the script commits the transaction, applying the changes to the network.

7. Finally, the script prints the number of node and link IDs that were changed.

                            Node IDs Changed
                            12
                            Link IDs Changed
                            10
                            Subcatchment IDs Changed
                            7

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM InfoWorks or SWMM Network. The script will automatically change all node and link IDs in the network and print the number of IDs that were changed.