SET user_text_4 = "";
LIST $nodes STRING;
SELECT SELECTED DISTINCT oid INTO $nodes;
LET $i = 1;
WHILE $i <= LEN($nodes);
  LET $node = AREF($i, $nodes);
  LIST $outfalls STRING;
  SELECT DISTINCT oid INTO $outfalls 
    WHERE node_type = "outfall" 
    AND all_us_links.us_node_id = $node;
  LET $j = 1;
  WHILE $j <= LEN($outfalls);
    LET $outfall = AREF($j, $outfalls);
    SET user_text_4 = user_text_4 + IIF(LEN(user_text_4)=0,'',',') + $outfall 
      WHERE oid = $node;
    LET $j = $j + 1;
  WEND;  
  LET $i = $i + 1;
WEND;