/* All Pumps
// Object Type: All Pumps and Nodes
// Spatial Search: Yes
*/

/*  Update the switch_on_level and switch_off_level based on the chamber floor elevation
-- We're adding the chamber_floor value from the 'spatial' table to both switch levels */
SET switch_on_level = switch_on_level + spatial.chamber_floor, /*Update the switch_on_level by adding the chamber floor elevation */
    switch_off_level = switch_off_level + spatial.chamber_floor  /* Update the switch_off_level by adding the chamber floor elevation */

