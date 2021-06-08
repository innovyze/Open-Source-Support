UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [ALL Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;
UPDATE [ALL Nodes] SET $chainage = 0;
LET $total_length = 0;
LET $count = 0;
UPDATE [ALL Links] SET $mark = 0;
WHILE $count < 20;
  SET ds_links.$link_selected = 1 WHERE $node_selected = 1;
  SET ds_links.$mark = 1 WHERE $node_selected = 1;
  UPDATE [ALL Links] SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
  UPDATE [ALL Links] SET us_node.$node_selected = 0 WHERE $link_selected = 1;
  SELECT NVL(length, NVL(conduit_length,0)) INTO $length  FROM [All Links] WHERE $link_selected = 1;
  LET $total_length = $total_length + NVL($length,0);
  UPDATE [All Nodes] SET $chainage = $total_length WHERE $node_selected = 1;
  UPDATE [ALL Links] SET $link_selected = 0 WHERE $link_selected = 1;
  LET $count = $count + 1;
WEND;
SELECT us_node.oid, ds_node.oid, oid, NVL(length, NVL(conduit_length,0)) AS length,link_type, ds_node.$chainage AS chainage FROM [All Links]
  WHERE $mark = 1
  ORDER BY ds_node.$chainage;