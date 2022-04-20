///Trace Upstream from 1 Node selected.
//Object Type: Node
//Spatial Search: blank


LET $n = 0;

PROMPT TITLE 'Select Number of Pipes to go Upstream';
PROMPT LINE $n 'Number of Links' DP 0;

PROMPT DISPLAY;

UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

LET $count = 0;
WHILE $count < $n;
SET us_links.$link_selected = 1 WHERE $node_selected = 1;
UPDATE [ALL Links] SET us_node.$node_selected = 1 WHERE $link_selected = 1;
LET $count = $count + 1;
WEND;

SELECT FROM [All Links] WHERE $link_selected = 1; SELECT FROM [All Nodes] WHERE $node_selected = 1;