/* Make Subcatchments
// Object Type: All Nodes and Subcatchments
// Spatial Search: blank
*/

/* 
  Begin the process of populating the 'subcatchment' table with new records.
  The new records are based on certain conditions met in the 'node' table.
*/

/* 
  Use INSERT INTO to add new records to 'subcatchment' table.
  The fields to be populated are: subcatchment_id, node_id, total_area, x, y, and connectivity.
*/
INSERT INTO subcatchment (subcatchment_id, node_id, total_area, x, y, connectivity)

/* 
  Use SELECT to fetch the corresponding values from the 'node' table.
  The total_area is set as 0.10 and connectivity as 100 for each new record.
*/
SELECT node_id, node_id, 0.10, x, y, 100

/* 
  Filter the records from the 'node' table where the node_type is 'Manhole'.
  Only records that meet this condition will be inserted into the 'subcatchment' table.
*/
WHERE node_type = 'Manhole';
