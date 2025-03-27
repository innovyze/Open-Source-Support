/*With Node(s) selected, expand the selection to include the US Links
//Object Type: Node
//Spatial Search: blank
*/

//Set a 0 value variable on all objects to be used
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE [All Links] SET $link_selected = 0;

//Update pre-selected objects variable to 1
UPDATE SELECTED Node SET $node_selected = 1;

//Update related objects from objects with the variable set as 1
UPDATE Node SET us_links.$link_selected = 1 WHERE $node_selected = 1;

//Select objects with variable set as 1
SELECT FROM [All Nodes] WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;
