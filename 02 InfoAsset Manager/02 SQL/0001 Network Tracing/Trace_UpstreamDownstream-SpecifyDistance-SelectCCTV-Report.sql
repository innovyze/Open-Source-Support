/*Trace Upstream/Downstream from multiple/1 Links selected specifying the maximum number of links to select, expand selection to include CCTV Surveys, output a SQL Results Grid of CCTV Survey object values.
//Object Type: All Links
//Spatial Search: blank
*/


//TRACE-Up/Down_SpecifyDistance
LIST $direction = 'Upstream', 'Downstream';
LET $n = 0;
 
PROMPT TITLE 'Select Pipes Upstream/Downstream to Grade Selected';
PROMPT LINE $DirectionSelected 'Select Direction: ' STRING LIST $direction;
PROMPT LINE $n 'Number of Maximum Number Links' DP 0;
PROMPT DISPLAY;
 
IF $DirectionSelected = 'Upstream';
 
UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $link_selected = 1;
 
LET $count = 0;
WHILE $count < $n;
SET us_node.$node_selected = 1 WHERE $link_selected = 1;
UPDATE [ALL Nodes] SET us_links.$link_selected = 1 WHERE $node_selected = 1;
LET $count = $count + 1;
WEND;
 
SELECT FROM [All Links] WHERE $link_selected = 1; SELECT FROM [All Nodes] WHERE $node_selected = 1;
 
ELSEIF $DirectionSelected = 'Downstream';
 
UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE SELECTED SET $link_selected = 1;
 
LET $count = 0;
WHILE $count < $n;
SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
UPDATE [ALL Nodes] SET ds_links.$link_selected = 1 WHERE $node_selected = 1;
LET $count = $count + 1;
WEND;
 
SELECT FROM [All Links] WHERE $link_selected = 1; SELECT FROM [All Nodes] WHERE $node_selected = 1;

ENDIF;


// NOW select surveys
//Set a 0 value variable on all objects to be used
UPDATE [All Nodes] SET $node_selected = 0;
UPDATE [All Links] SET $link_selected = 0;
UPDATE [CCTV Survey] SET $cctv_selected = 0;
 
//Update pre-selected objects variable to 1
UPDATE SELECTED Pipe SET $link_selected = 1;
 
//Update related objects from objects with the variable set as 1
UPDATE Pipe SET us_node.$node_selected = 1 WHERE $link_selected = 1;
UPDATE Pipe SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
UPDATE Pipe SET cctv_surveys.$cctv_selected = 1 WHERE $link_selected = 1;
 
//Select objects with variable set as 1
SELECT FROM [All Nodes] WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;
SELECT FROM [CCTV Survey] WHERE $cctv_selected = 1;
SELECT SELECTED COUNT(*) AS 'CCTV Surveys',
SUM(surveyed_length) AS 'CCTV Survey Length (ft)',
SUM(surveyed_length/5280) AS 'CCTV Survey Length (mi)',
SUM(joined.length) AS 'Pipe Length (ft)',
SUM(joined.length/5280) AS 'Pipe Length (mi)' FROM [CCTV Survey] 
GROUP BY
size_1 AS "Height",
size_2 AS "Width",
material AS "Material",
pacp_overall_quick_rating AS 'Quick Rating',
pacp_struct_quick_rating AS 'Structural QUICK Rating',
pacp_oandm_quick_rating AS "OandM Quick Rating",
YEARPART(when_surveyed) AS "Year Surveyed",
network.name AS "Network" ORDER BY pacp_overall_quick_rating DESC;


// Deselect Nodes & Pipes
DESELECT ALL FROM [Pipe];
DESELECT ALL FROM [Node];