// The following query will take a selection of conduits and for each selected conduit, create a dummy node 2m downstream of the conduit downstream node (witht he suffix _COL) and connect via an orifice link with the orifice invert level set to the conduit downstream invert.

LIST $ConduitID STRING;
SELECT SELECTED DISTINCT us_node_id INTO $ConduitID;

DESELECT ALL;

LET $i=1;
WHILE $i<=LEN($ConduitID);
SELECT FROM [Conduit] WHERE us_node.node_id=AREF($i,$conduitID);

SELECT SELECTED ds_node.node_id INTO $US;
SELECT SELECTED ds_node.node_id+'_COL'INTO $A;
SELECT SELECTED ds_node.X +1.41 INTO $X;
SELECT SELECTED ds_node.y +1.41 INTO $Y;

SELECT SELECTED ds_invert INTO$ Invert;
INSERT INTO node (node_id, x, y) VALUES ($A, $X, $Y);
INSERT INTO orifice (us_node_id,ds_node_id, link_suffix, invert) VALUES ($US, $A, 2, $invert);
DESELECT ALL;

LET $i=$i+1;
WEND;