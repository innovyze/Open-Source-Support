# Sum values in GIS based on criteria
This SQL sums values found in a `value` column in a SHP points file which are contained in each subcatchment if the value on their `ident` column matches the value `A`.
It displays the sum and also updates the `user_number_10` column of the Subcatchments table with the respective result.
The GIS layer has to be loaded in the model network.

Network snapshot file and `points.shp` file included.
## ICM query and results
![](img001.png)
## GIS view
![](img002.png)
