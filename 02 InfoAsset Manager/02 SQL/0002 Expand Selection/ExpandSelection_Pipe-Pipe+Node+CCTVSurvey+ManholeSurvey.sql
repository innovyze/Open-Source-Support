/*With Pipe(s) selected select the US/DS Nodes, CCTV Surveys, and Manhole Surveys
//Object Type: Pipe
//Spatial Search: blank
*/


UPDATE [All Nodes] SET $node_selected = 0;
UPDATE [ALL Links] SET $link_selected = 0;
UPDATE [CCTV Survey] SET $cctv_selected = 0;
UPDATE [Manhole Survey] SET $mhs_selected = 0;
UPDATE SELECTED [Pipe] SET $link_selected = 1;
UPDATE SELECTED [Node] SET $node_selected = 1;

UPDATE Pipe SET us_node.$node_selected = 1 WHERE $link_selected = 1;
UPDATE Pipe SET ds_node.$node_selected = 1 WHERE $link_selected = 1;
UPDATE Pipe SET cctv_surveys.$cctv_selected = 1 WHERE $link_selected = 1;
UPDATE Node SET manhole_surveys.$mhs_selected = 1 WHERE $node_selected = 1;

SELECT FROM [All Nodes] WHERE $node_selected = 1;
SELECT FROM [All Links] WHERE $link_selected = 1;
SELECT FROM [CCTV Survey] WHERE $cctv_selected = 1;
SELECT FROM [Manhole Survey] WHERE $mhs_selected = 1;