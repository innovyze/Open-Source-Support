# Ruby Code for Generating Polygon Boundaries in InfoWorks ICM

This Ruby script is used to generate the boundaries for polygons with a specified number of sides in the InfoWorks ICM software. Here's a summary of what it does:

1. **Get the current network object**: The script starts by getting the current network object using `WSApplication.current_network`.

2. **Begin a transaction**: It then begins a transaction using `net.transaction_begin`. This allows all changes to be committed at once at the end of the script.

3. **Define a function to generate the boundary for a polygon**: The `generate_polygon_boundary` function is defined. This function takes a boundary array and a number of sides as arguments. It calculates the minimum and maximum x and y coordinates, the width and height, and then generates the points of the polygon. It returns the polygon boundary.

4. **Iterate over each type of polygon**: The script then iterates over each type of polygon. For each type, it iterates over all polygon objects of that type in the network.

5. **Check if the polygon is selected**: For each polygon, it checks if the polygon is selected. If it is, it gets the boundary array of the polygon, generates a new boundary array with a specified number of sides, and then sets the new boundary array.

6. **Commit the transaction**: Finally, the script commits the transaction using `net.transaction_commit`, making all changes permanent.

7. **List of all InfoWorks ICM Polygon Types**: The script includes a list of all InfoWorks ICM polygon types that can be reshaped. This includes 'hw_2d_infiltration_zone', 'hw_2d_permeable_zone', 'hw_mesh_zone', 'hw_roughness_zone', 'hw_porous_polygon', and 'hw_polygon'. For each type, a comment indicates whether it can be used for polygon reshaping.

This script is useful for modifying the shape of selected polygons in an InfoWorks ICM network. It can be used with various types of polygons, including 'hw_2d_infiltration_zone', 'hw_2d_permeable_zone', 'hw_mesh_zone', 'hw_roughness_zone', 'hw_porous_polygon', and 'hw_polygon'.
![alt text](image.png)