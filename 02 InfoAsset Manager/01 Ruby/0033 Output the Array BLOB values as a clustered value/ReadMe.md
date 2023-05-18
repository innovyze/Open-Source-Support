# Introduction
On all objects there are BLOB (binary large object) fields, which are an array/table on the object in a one-to-many relationship.  
If you were to export these values alongside the other object fields to a format such as CSV, the principal object fields would be duplicated per-row of the BLOB values.  
These scripts will produce an output clustering the values from the BLOB field into a single value.  

## [UI-Manhole-Hyperlinks.rb](./UI-Manhole-Hyperlinks.rb)
Output the manhole ID (node_id) with all of the Hyperlinks.URL values separated by a comma.  

## [UI-PipeClean-Pipes.rb](./UI-PipeClean-Pipes.rb)
Output the Pipe Clean ID with all of the referenced pipes (pipes.us_node_id, pipes.ds_node_id, pipes.link_suffix) values joined by a full-stop separated by a comma.  
