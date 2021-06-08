UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [ALL Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;
LET $count = 0;
WHILE $count < 3;
  SET us_links.$link_selected = 1
    WHERE $node_selected = 1;
  UPDATE [ALL Links]
    SET us_node.$node_selected = 1
  WHERE $link_selected = 1;
  SET ds_links.$link_selected = 1
    WHERE $node_selected = 1;
  UPDATE [ALL Links]
    SET ds_node.$node_selected = 1
  WHERE $link_selected = 1;
  LET $count = $count + 1;
WEND;
SELECT FROM [All Links] WHERE $link_selected = 1;