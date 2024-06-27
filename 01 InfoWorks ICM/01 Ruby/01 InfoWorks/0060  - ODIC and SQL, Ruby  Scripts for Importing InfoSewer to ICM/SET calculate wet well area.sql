/* Set Node Area for wet Wells from InfoSewer
// Object Type: All Nodes and Subcatchments
// Spatial Search: blank
*/

SET chamber_area = 3.14159 *  ( chamber_area/2) *  ( chamber_area/2);
Select
WHERE user_text_10 = 'WW';

SET shaft_area = 3.14159 *  ( shaft_area/2) *  (shaft_area/2);
Select
WHERE user_text_10 = 'WW';

SET chamber_roof = chamber_floor + chamber_roof;
SET ground_level = ground_level + chamber_floor;
SET flood_level = flood_level + chamber_floor;