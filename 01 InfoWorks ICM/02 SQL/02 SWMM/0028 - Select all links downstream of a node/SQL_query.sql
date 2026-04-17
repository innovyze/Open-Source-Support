UPDATE SELECTED SET $node_selected = 1;
SET all_ds_links.$link_selected = 1
  WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;