# Select polygons inside selected subcatchments
This query also filters a subset of polygons by `category_id`. To remove that functionality, remove the part that contains `AND category_id='la'`.
Current functionality dictates that the user has to sacrifice a user field since the spatial queries don't yet allow variables.
The `inside` / `contains` statements use centroids as a heuristic to determine what is within the containing polygon. This means it not always selects the expected objects. The `cross` statement selects anything touching the containing polygon.
![](screenshot.png)