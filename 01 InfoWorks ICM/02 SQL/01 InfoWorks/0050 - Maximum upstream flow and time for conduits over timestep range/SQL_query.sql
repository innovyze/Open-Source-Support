//Object: Conduit
//Spatial Search: blank

LET $start_step = 97;
LET $end_step = 169;

SELECT us_node_id,
       ds_node_id,
       link_suffix,
       MAX(tsr.us_flow) DP 3 AS [Maximum Flow],
       WHENMAX(tsr.us_flow) AS [Time of Maximum]
WHEN tsr.timestep_no >= $start_step
  AND tsr.timestep_no <= $end_step
ORDER BY MAX(tsr.us_flow) DESC;
