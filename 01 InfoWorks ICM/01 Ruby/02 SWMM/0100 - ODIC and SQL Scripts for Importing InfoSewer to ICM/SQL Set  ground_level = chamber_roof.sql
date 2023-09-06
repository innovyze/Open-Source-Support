/* Node Ground Level
// Object Type: All Nodes 
// Spatial Search: blank
*/

SET ground_level = chamber_roof + 1
WHERE ground_level = 0.0 OR ground_level IS NULL;

SET ground_level = chamber_roof + 1
WHERE ground_level < chamber_roof; 

SET flood_level = chamber_roof + 1
WHERE flood_level < chamber_roof; 

SET chamber_roof = chamber_roof + chamber_floor
WHERE chamber_roof< chamber_floor; 