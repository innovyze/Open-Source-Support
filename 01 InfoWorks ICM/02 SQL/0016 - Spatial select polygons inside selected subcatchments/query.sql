SPATIAL NONE;
DESELECT FROM polygon;
UPDATE all subcatchment SET user_number_10=0;
UPDATE selected subcatchment SET user_number_10=1;
SPATIAL inside Network subcatchment;
spatial.user_number_10 = 1 AND category_id='la';
SPATIAL NONE;
UPDATE selected subcatchment SET user_number_10="";