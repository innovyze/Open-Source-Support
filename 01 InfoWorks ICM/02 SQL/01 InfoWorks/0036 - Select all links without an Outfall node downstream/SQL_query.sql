//Object: All nodes
//Spatial Search: blank

SELECT WHERE node_type = "Outfall";
UPDATE SELECTED SET $node_selected = 1;
SET all_us_links.$link_selected = 1
  WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected <> 1;
DESELECT WHERE node_type = "Outfall";