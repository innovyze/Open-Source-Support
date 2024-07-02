/* Calculate wet well hydraulics
// Object Type: All Nodes
// Spatial Search: blank
*/

SET chamber_area = 3.14159 * (chamber_area/2) * (chamber_area/2) WHERE user_text_10 = 'WW';

SET shaft_area = 3.14159 * (shaft_area/2) * (shaft_area/2) WHERE user_text_10 = 'WW';

SET ground_level = ground_level + chamber_floor WHERE user_text_10 = 'WW'