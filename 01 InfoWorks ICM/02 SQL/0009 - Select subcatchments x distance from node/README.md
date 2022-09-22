# Select subcatchments at x distance of a node
## Summary
This query finds any subcatchments in a network that are at a user defined distance of a selected node. The distance is user defined in the first line as map units.

## Notes
Current functionality dictates that the user has to sacrifice a user field since the spatial queries don't yet allow variables.

The `distance` statement uses subcatchment centroids as a heuristic to determine the distance to the node.

![](gif003.gif)