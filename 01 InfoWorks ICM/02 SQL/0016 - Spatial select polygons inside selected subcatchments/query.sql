SPATIAL NONE;
DESELECT FROM polygon;
UPDATE all subcatchment SET user_number_10=0;
UPDATE selected subcatchment SET user_number_10=1;
SPATIAL inside Network subcatchment;
spatial.user_number_10 = 1 AND category_id='la';
SPATIAL NONE;
UPDATE selected subcatchment SET user_number_10="";

// This query also filters a subset of polygons by category_id (line 6). To remove that functionality, remove the part that contains < AND category_id='la' >
// Current functionality dictates that the user has to sacrifice a user field since the spatial queries don't yet allow variables.
// The 'inside'/'contains' statemenst use centroids as a heuristic to determine what is within the containing polygon. This means it not always selects the expected objects. The 'cross' statement selects anything touching the containing polygon.