/* Node Ground Level
// Object Type: All Nodes 
// Spatial Search: blank
*/

/* 
  Update 'ground_level' to be one unit above 'chamber_roof' where 'ground_level' is either 0.0 or NULL.
  This ensures a meaningful value for 'ground_level' where it's missing or zero.
*/
SET ground_level = chamber_roof + 1
WHERE ground_level = 0.0 OR ground_level IS NULL;

/* 
  Update 'ground_level' to be one unit above 'chamber_roof' where 'ground_level' is less than 'chamber_roof'.
  This ensures that 'ground_level' is always above the 'chamber_roof'.
*/
SET ground_level = chamber_roof + 1
WHERE ground_level < chamber_roof;

/* 
  Update 'flood_level' to be one unit above 'chamber_roof' where 'flood_level' is less than 'chamber_roof'.
  This ensures that 'flood_level' is always above the 'chamber_roof'.
*/
SET flood_level = chamber_roof + 1
WHERE flood_level < chamber_roof;

/* 
  Update 'chamber_roof' by adding 'chamber_floor' where 'chamber_roof' is less than 'chamber_floor'.
  This ensures that 'chamber_roof' is always above the 'chamber_floor'.
*/
SET chamber_roof = chamber_roof + chamber_floor
WHERE chamber_roof < chamber_floor;