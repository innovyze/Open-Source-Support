# Connect Subcatchment to Nearest Node
This script is used to find the nearest node (a point in a network) for each selected subcatchment (a specific area in the network) based on system type.

## How it Works
1. Collects all selected nodes and their information.
2. Begins a transaction (a set of changes).
3. For each selected subcatchment, it finds the nearest node of each system type (like storm, foul, sanitary, etc.).
4. Assigns the ID of the nearest node to the subcatchment.
5. Writes the changes to each subcatchment.
6. Commits the transaction, finalizing all changes.