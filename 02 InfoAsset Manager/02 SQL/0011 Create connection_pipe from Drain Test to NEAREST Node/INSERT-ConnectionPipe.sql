/*Create a connection_pipe object from a drain_test to the Nearest node
//Object Type: Drain Test
//Spatial Search: NEAREST+dist / Network Layer / Node
//Image: ./img001.png
*/


SELECT id INTO $dtid;
SELECT x INTO $dtx;
SELECT y INTO $dty;

SET $spatialid=spatial.node_id;
SELECT $spatialid INTO $nodeid;
SET $spatialx = spatial.x;
SELECT $spatialx INTO $nodex;
SET $spatialy = spatial.y;
SELECT $spatialy INTO $nodey;


SELECT $dtid,$nodeid,$dtx,$dty,$nodex,$nodey;

INSERT INTO [connection pipe] (id,ds_node_id,x_start,y_start,x_end,y_end) VALUES ($dtid,$nodeid,$dtx,$dty,$nodex,$nodey)