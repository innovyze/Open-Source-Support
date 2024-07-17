/* Select links connected to selected nodes
// Object Type: All Nodes
// Spatial Search: blank
*/

/* Select nodes, then run query to select links connected to selected nodes */

UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [ALL Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;
SET us_links.$link_selected = 1, ds_links.$link_selected = 1 WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;