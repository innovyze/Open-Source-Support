/* 7 - Network Travel Time Tracer
	Object Type: All Nodes
	Description: Trace upstream specified number of segments from selected node(s)
	Travel time through each link is aproximated using the average velocity over a user-defined time window.
	Important: Open the model network first and then drag the simulation object onto the opened network
	*/

LET $n_hours = 24;    // Total number of hours in the simulation;
LET $iterations = 200;   // Number of iterations to trace upstream.
LET $min_speed = 0.01;    // Assumed minimum average travel velocity in pipes.

LET $start = 0;
LET $end = $n_hours ;

PROMPT TITLE "Define Parameters";
PROMPT LINE $iterations "Number of iterations upstream" DP 3;
PROMPT LINE $min_speed "Minimum assumed average velocity" DP 3;
PROMPT LINE $start "Start hour (0-24)" DP 3;
PROMPT LINE $end "End hour (0-24)" DP 3;
PROMPT DISPLAY;

UPDATE [All Links] SET $left = $start*MAX(tsr.timesteps)/$n_hours,
					$right = $end*MAX(tsr.timesteps)/$n_hours;
UPDATE [All Links] SET $speed = AVG(IIF((tsr.timestep_no > $left) AND (tsr.timestep_no < $right),tsr.us_vel,NULL));
UPDATE [All Links] SET $speed = $min_speed WHERE $speed<$min_speed;
UPDATE [All Links] SET $travel_time = IIF(conduit_length IS NOT NULL,conduit_length,1) / $speed / 60,
					$link_selected = 0,
					user_number_4 = '',
					user_number_5 = '',
					user_number_6 = $speed;
UPDATE [All Nodes] SET $node_selected = 0,
					user_number_5 = '';
UPDATE SELECTED SET ds_links.user_number_5 = 0,
					$node_selected = 1;

LET $count = 0;
WHILE $count < $iterations;
	UPDATE [All Nodes] SET user_number_5 = MIN(ds_links.user_number_5)   // Assume water prefers shortest path
		WHERE $node_selected = 1;
	UPDATE [All Nodes] SET us_links.$link_selected = 1,
		$node_selected = 0                             // Clear tracks as we work
		WHERE $node_selected = 1;
	UPDATE [ALL Links] SET us_node.$node_selected = 1,
		user_number_4 = ds_node.user_number_5,
		user_number_5 = ds_node.user_number_5 + $travel_time,
		$link_selected = 0
		WHERE $link_selected = 1;
   LET $count = $count + 1;
WEND;

UPDATE Subcatchment SET user_number_5 = node.user_number_5;

SELECT FROM Subcatchment WHERE user_number_5 > 0;
SELECT SELECTED subcatchment_id AS [Subcatchment], 
    sim.max_qcatch AS [Peak Flow],
    user_number_5 AS [Travel Time (minutes)]
    FROM Subcatchment 