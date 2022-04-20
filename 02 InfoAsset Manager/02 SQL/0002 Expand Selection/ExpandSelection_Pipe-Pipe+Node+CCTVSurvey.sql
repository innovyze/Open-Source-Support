///With Pipe(s) selected select the US/DS Nodes and CCTV Surveys
//Object Type: Pipe
//Spatial Search: blank


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