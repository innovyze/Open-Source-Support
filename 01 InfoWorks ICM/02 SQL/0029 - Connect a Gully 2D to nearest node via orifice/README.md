# Connect a Gully 2D flood type node, to the nearest none Gully 2D node via an orifice
This SQL demonstrates how we can use a spatial join on an object to find its nearest one. We need to do this for the node explicity at the start of the SQL to ensure that its the nearest relative to that node. The SQL then generates a new orifice link and populates the object data necessary for the connection.

This SQL could be extended to populate the size and invert level of the orifice depending on your own requirement.

## SQL Dialog
![](img001.png)
