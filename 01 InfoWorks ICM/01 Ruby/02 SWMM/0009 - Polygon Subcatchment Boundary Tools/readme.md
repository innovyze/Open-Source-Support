# Ruby Code to Add Nodes to Selected Polygons and or subcatchments

## Overview
This code adds new nodes at the centroid and vertices of selected polygons in an InfoWorks network.

## Functionality
- Starts transaction to commit all changes at once
- Loops through selected polygons
  - Gets boundary coordinate array
  - Calculates centroid coordinates
  - Creates centroid node 
  - Creates node at each vertex
- Commits transaction to save changes

## Variables
- `boundary_array` - Polygon boundary coordinates
- `centroid_x/y` - Calculated centroid coords 

## Methods  
- `selected?` - Checks if selected
- `boundary_array` - Gets coordinates 
- `new_row_object()` - Creates new node
- `transaction_` - Commits changes

## Output
- New nodes created at centroid and vertices of selected polygons
- Added nodes committed to network 

![Alt text](<Network Nodes.png>)

![Alt text](diagram(4).png)