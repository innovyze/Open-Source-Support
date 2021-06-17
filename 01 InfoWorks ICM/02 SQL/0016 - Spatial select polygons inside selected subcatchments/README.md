# Select polygons inside selected subcatchments
## Summary
This query finds any polygons in a network that are detected inside a particular selection of subcatchments.

Additionally  it also filters a subset of polygons by `category_id`. In this example, only polygons that have a `category_id` of `la` will be selected. To remove that functionality, remove the part that contains `AND category_id='la'`.

## Spatial keywords
This example shows an advanced version of spatial queries by using the `SPATIAL` keyword to mix spatial and non-spatial searches.

* `SPATIAL NONE` defines the start of a command block that is non-spatial
* `SPATIAL inside Network subcatchment` defines the start of a command block that is spatial which matches polygons inside subcatchments

For purely spatial queries the fields selected under the `Spatial Search` box can be used. The `SPATIAL` keywords are not needed and only the spatial command block needs to be explicit, for example `spatial.user_number_10 = 1`.

## Notes
Current functionality dictates that the user has to sacrifice a user field since the spatial queries don't yet allow variables.

The `inside` / `contains` statements use centroids as a heuristic to determine what is within the containing polygon. This means it not always selects the expected objects. The `cross` statement selects anything touching the containing polygon.

![](screenshot.png)