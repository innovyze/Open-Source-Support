//Object: All nodes
//Spatial Search: blank

//Can only have one pipe selected
UPDATE SELECTED [ALL LINKS] SET $selected = 1;

//Finds US and DS node details from selected pipe
SELECT node_id INTO $linkid WHERE ds_links.$selected = 1;
SELECT node_id INTO $dslinkid WHERE us_links.$selected = 1;

//Inserts X & Y coordinates into variables
SELECT x INTO $x_us WHERE node_id=$linkid;
SELECT y INTO $y_us WHERE node_id=$linkid;
SELECT x INTO $x_ds WHERE node_id=$dslinkid;
SELECT y INTO $y_ds WHERE node_id=$dslinkid;

//Pipe vector coordinates
LET $v_x = $x_ds - $x_us;
LET $v_y = $y_ds - $y_us;

//updates associated parameters into variables
SELECT ground_level INTO $gl WHERE node_id=$linkid;
SELECT system_type INTO $sys WHERE node_id=$linkid;
SELECT ds_links.shape INTO $shp WHERE node_id = $linkid;
SELECT ds_links.width INTO $width WHERE node_id = $linkid;
SELECT ds_links.height INTO $height WHERE node_id = $linkid;

//calculates the length of the pipe based on X1,Y1 vs X2,Y2. Preferable to using #D parameter in case changed in model
LET $length = ($v_x^2 + $v_y^2)^0.5;
LET $us_nodeid = $linkid;
//Defines chainage distance of new nodes in pipe
LET $distance = 50;
LET $chainage = $distance;

//Normalise vector for projection
LET $v_x_norm = $v_x / $length;
LET $v_y_norm = $v_y / $length;
LET $x_chain = $v_x_norm * $distance;
LET $y_chain = $v_y_norm * $distance;

//Identifies the new node projection (currently set to fixed gradient - x shift 2m, y shift 2m - needs fixing)
LET $new_x = $x_us + $x_chain;
LET $new_y = $y_us + $y_chain;

//Loop to produce number of new nodes until length is exceeded
WHILE $chainage < $length;
	//Inserts new node
	INSERT INTO node (node_id, x, y,system_type,ground_level,flood_type) VALUES ($us_nodeid+"_"+ $chainage, $new_x, $new_y,$sys,$gl,"sealed");

	//Updates X,Y projection for next node in the loop
	LET $new_x = $new_x + $x_chain;
	LET $new_y = $new_y + $y_chain;

	LET $chainage = $chainage + $distance;
WEND;

//Reprojects pipe from original US->DS so that new pipes installed in between (still need to automatically infer US/DS Inverts based on original length)
LET $chainage = $distance;
WHILE $chainage < $length;
	IF $chainage = $distance;
		UPDATE [ALL LINKS] SET ds_node_id = ($us_nodeid + "_" + $chainage) WHERE $selected = 1;

		INSERT INTO conduit (us_node_id, ds_node_id,link_suffix,system_type,shape, conduit_width, conduit_height) VALUES ($us_nodeid+"_"+$chainage , $us_nodeid+"_"+($chainage + $distance), 1, $sys, $shp, $width, $height);

		ELSEIF ($chainage + $distance) < $length;
		INSERT INTO conduit (us_node_id, ds_node_id,link_suffix,system_type,shape, conduit_width, conduit_height) VALUES ($us_nodeid+"_"+$chainage , $us_nodeid+"_"+($chainage + $distance), 1, $sys, $shp, $width, $height);

		ELSE;
		INSERT INTO conduit (us_node_id, ds_node_id,link_suffix,system_type,shape, conduit_width, conduit_height) VALUES ($us_nodeid+"_"+$chainage, $dslinkid, 1, $sys, $shp, $width, $height);
	ENDIF;

	LET $chainage= $chainage + $distance;
WEND;