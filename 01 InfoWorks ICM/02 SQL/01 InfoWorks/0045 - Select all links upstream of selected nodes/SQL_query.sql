/* Select all links upstream of selected nodes
// Object Type: All Nodes
// Spatial Search: blank
*/

/* Select nodes, then run query to select all upstream links */

UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [ALL Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;
SET all_us_links.$link_selected = 1 WHERE $node_selected = 1;
UPDATE [ALL Links] SET us_node.$node_selected = 1 WHERE $link_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;