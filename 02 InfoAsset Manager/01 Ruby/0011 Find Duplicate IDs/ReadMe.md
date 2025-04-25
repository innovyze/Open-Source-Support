[UI-DuplicateLinkIDs.rb](./UI-DuplicateLinkIDs.rb)
It is possible to have the same ID for different types of Link object on the network (E.G. a Channel and an Orifice).  
There is no Validation rule to check for these.  
This will produce a simple output stating the ID which is in the Links table more than once and the table names where the ID is present in both.  

[UI-DuplicateAssetIDMultipleObjects.rb](./UI-DuplicateAssetIDMultipleObjects.rb)
Much like it is possible to have multiple objects with the same id accross different types of link objects, objects in different tables can have the same asset_id value.  
This script will output objects with the same asset_id values across the chosen tables.  
  