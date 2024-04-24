SELECT ALL;
LIST $drains_to STRING;
SELECT SELECTED DISTINCT node.node_id INTO $drains_to;
LET $i=1;
    WHILE $i<=LEN($drains_to);
    SELECT FROM [Node] WHERE node_id=AREF($i,$drains_to);
    LET $i=$i+1;
WEND;
DESELECT ALL;