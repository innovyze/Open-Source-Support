# Populate conduit inverts with cross section elevations

This script is designed to update the elevation data (or 'invert' values) at the upstream (US) and downstream (DS) nodes of each conduit in a network based on matching cross-section survey data.

## How it Works

1. The script first accesses the current network of conduits.
2. It then goes through each conduit in the network.
3. For each conduit, it also iterates through each cross-section survey in the network.
4. Within each cross-section survey, it looks at each point.
5. If a point in the cross-section survey matches the location of the upstream node of the conduit, the 'us_invert' of the conduit is updated with the 'z' value of that point.
6. Similarly, if a point in the cross-section survey matches the location of the downstream node of the conduit, the 'ds_invert' of the conduit is updated with the 'z' value of that point.
7. Once all points in all cross-section surveys have been checked for a particular conduit, the changes are written to the conduit object.
8. This process is repeated for each conduit in the network.