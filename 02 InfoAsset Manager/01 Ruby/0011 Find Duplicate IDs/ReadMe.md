[UI-DuplicateLinkIDs.rb](./UI-DuplicateLinkIDs.rb)
It is possible to have the same ID for different types of Link object on the network (E.G. a Channel and an Orifice).  
There is no Validation rule to check for these.  
This will produce a simple output stating the ID which is in the Links table more than once and the table names where the ID is present in both.  

[UI-DuplicateAssetIDMultipleObjects.rb](./UI-DuplicateAssetIDMultipleObjects.rb)
Much like it is possible to have multiple objects with the same asset_id accross different types of link objects, this can be done accross multiple other object types.  
This script will identify objects with the same asset_id values across any chosen table.  
  