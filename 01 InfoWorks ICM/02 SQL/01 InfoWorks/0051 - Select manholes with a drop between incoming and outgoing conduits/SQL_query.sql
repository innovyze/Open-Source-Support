//Object: All Nodes
//Spatial Search: blank

LET $threshold = 0.30;

PROMPT TITLE 'Manhole conduit drop height check';
PROMPT LINE $threshold 'Max incoming invert spread (m)' DP 3;
PROMPT DISPLAY;

SET $max_inv = MAX(us_links.ds_invert);
SET $min_inv = MIN(ds_links.us_invert);
SET $spread = ABS($max_inv - $min_inv);

SET user_number_2 = $spread;
SET user_number_1 = IIF(node_type = 'manhole' AND user_number_2 > $threshold, 1, 0);

SELECT WHERE user_number_1 = 1;
