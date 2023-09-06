/* Make Subcatchments
// Object Type: All Nodes and Subcatchments
// Spatial Search: blank
*/

/* Insert new records into the 'subcatchment' table based on certain conditions in the 'node' table */

INSERT INTO subcatchment (subcatchment_id,node_id,total_area,x,y,connectivity)
SELECT node_id, node_id, 0.10, x,y,100

WHERE node_type = 'Manhole';
