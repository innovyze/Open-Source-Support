/* Node Ground Level
// Object Type: All Nodes 
// Spatial Search: blank
*/

/* 
  This script updates the 'ground_level', 'flood_level', and 'chamber_roof' fields of all nodes in the network.
  It ensures that 'ground_level' and 'flood_level' are always above the 'chamber_roof', and that 'chamber_roof' is always above the 'chamber_floor'.
*/

/* 
  The first query updates the 'ground_level' field to be one unit above the 'chamber_roof' for all nodes where 'ground_level' is either 0.0 or NULL.
  This is done to ensure that 'ground_level' has a meaningful value where it's currently missing or zero.
*/
SET ground_level = chamber_roof + 1
WHERE ground_level = 0.0 OR ground_level IS NULL;

/* 
  The second query updates the 'ground_level' field to be one unit above the 'chamber_roof' for all nodes where 'ground_level' is currently less than 'chamber_roof'.
  This is done to ensure that 'ground_level' is always above the 'chamber_roof'.
*/
SET ground_level = chamber_roof + 1
WHERE ground_level < chamber_roof;

/* 
  The third query updates the 'flood_level' field to be one unit above the 'chamber_roof' for all nodes where 'flood_level' is currently less than 'chamber_roof'.
  This is done to ensure that 'flood_level' is always above the 'chamber_roof'.
*/
SET flood_level = chamber_roof + 1
WHERE flood_level < chamber_roof;

/* 
  The fourth query updates the 'chamber_roof' field by adding the 'chamber_floor' to it for all nodes where 'chamber_roof' is currently less than 'chamber_floor'.
  This is done to ensure that 'chamber_roof' is always above the 'chamber_floor'.
*/
SET chamber_roof = chamber_roof + chamber_floor
WHERE chamber_roof < chamber_floor;