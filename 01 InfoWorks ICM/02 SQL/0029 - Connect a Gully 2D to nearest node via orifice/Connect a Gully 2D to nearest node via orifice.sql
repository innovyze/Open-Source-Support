//Object: All Nodes
//Spatial Search: Nearest, Network layer, All Nodes, 1500

LIST $NodeID STRING;
SET user_text_1 =spatial.node_id;

SELECT DISTINCT oid INTO $NodeID FROM [All Nodes] WHERE flood_type = "Gully 2d";

DESELECT ALL;

LET $i=1;
WHILE $i<=LEN($NodeID);
SELECT WHERE oid=AREF($i,$NodeID);

SELECT SELECTED node_id INTO $US;
SELECT SELECTED user_text_1 INTO $DS;

INSERT INTO orifice (us_node_id, ds_node_id, link_suffix) VALUES ($US, $DS, "X");

DESELECT ALL;

LET $i=$i+1;
WEND;