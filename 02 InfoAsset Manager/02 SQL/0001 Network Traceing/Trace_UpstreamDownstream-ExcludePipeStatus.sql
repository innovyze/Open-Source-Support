/*Trace Upstream/Downstream from multiple/1 Node selected specifying the maximum number of links to select from each Node, excluding Pipes which have the selected Status field value.
//Object Type: All Nodes
//Spatial Search: blank
*/


LIST $notstatus STRING;
SELECT DISTINCT status INTO $notstatus  from [All Links];

LIST $direction = 'Upstream', 'Downstream';
LET $n = 0;

PROMPT TITLE 'Select Pipes Upstream/Downstream to Grade Selected';
PROMPT LINE $DirectionSelected 'Select Direction: ' STRING LIST $direction;
PROMPT LINE $notstatusselected 'Select Pipes without Status: ' STRING LIST $notstatus;
PROMPT LINE $n 'Number of Maximum Number Links' DP 0;

PROMPT DISPLAY;

IF $DirectionSelected = 'Upstream';

UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

LET $count = 0;
WHILE $count < $n;
SET us_links.$link_selected = 1 WHERE $node_selected = 1  AND us_links.status<>$notstatusselected;
UPDATE [ALL Links] SET us_node.$node_selected = 1 WHERE $link_selected = 1;
LET $count = $count + 1;
WEND;

SELECT FROM [All Links] WHERE $link_selected = 1; SELECT FROM [All Nodes] WHERE $node_selected = 1;

ELSEIF $DirectionSelected = 'Downstream';

UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $node_selected = 1;

LET $count = 0;
WHILE $count < $n;
SET ds_links.$link_selected = 1 WHERE $node_selected = 1  AND us_links.status<>$notstatusselected;
UPDATE [ALL Links] SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
LET $count = $count + 1;
WEND;

SELECT FROM [All Links] WHERE $link_selected = 1; SELECT FROM [All Nodes] WHERE $node_selected = 1;

ENDIF;