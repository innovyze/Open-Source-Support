LIST $USNode STRING;
SELECT DISTINCT us_node.oid INTO $USNode;

PROMPT TITLE"River reach";
PROMPT LINE $sel1 'US node' LIST $USNode;
PROMPT DISPLAY;

LIST $DSNode STRING;
SELECT DISTINCT ds_node.oid INTO $DSNode WHERE us_node.oid = $sel1;

PROMPT TITLE"River reach";
PROMPT LINE $sel2 'DS node' LIST $DSNode;
PROMPT DISPLAY;

SELECT FROM [Cross section line]
  WHERE (spatial.us_node_id = $sel1 and spatial.ds_node_id = $sel2);