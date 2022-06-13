//Object: Conduit
//Spatial Search: None

//set a variable against the selection of pipes
SET $pipes = 1;
//set the total length of the run - calc slope
LET $length = 0;
SELECT (SUM(conduit_length)) INTO $length;
//calc the distance from the us_invert
SET user_number_2 = conduit_length WHERE $pipes = 1;
SET user_number_2 = user_number_2 + SUM (all_us_links.conduit_length) WHERE all_us_links.$pipes = 1 AND $pipes=1;
//create variables used for calc slope
LET $us = 0;
LET $usheight =0;
LET $ds = 0;
LET $dsheight = 0;
//populate variables with inverts and heights
SELECT MAX(us_invert) INTO $us;
SELECT (conduit_height / 1000) INTO $usheight WHERE $us = us_invert;
SELECT MIN(ds_invert) INTO $ds;
SELECT (conduit_height / 1000) INTO $dsheight WHERE $ds = ds_invert;
//calculate slopes
SET $BottomSlope = ($us - $ds) / $length;
SET $TopSlope = (($us + $usheight) - ($ds + $dsheight)) / $length;
//set the ds_invert based on the $topslope
SET ds_invert = (($us + $usheight) - ($TopSlope * user_number_2) - (conduit_height / 1000)) WHERE ds_invert = null;
