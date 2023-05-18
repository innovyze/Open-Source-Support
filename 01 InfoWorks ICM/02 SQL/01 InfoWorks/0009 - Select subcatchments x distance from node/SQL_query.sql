LET $dist = 10;
SPATIAL NONE;
DESELECT FROM subcatchment;
UPDATE all node SET user_number_10=0;
UPDATE selected node SET user_number_10=1;
SPATIAL distance Network node $dist;
spatial.user_number_10 = 1;
SPATIAL NONE;
UPDATE all node SET user_number_10="";