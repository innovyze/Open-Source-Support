/* Set pump on and off
// Object Type: Pump
// Spatial Search: blank
*/

/*  Convert the switch_on_level and switch_off_level from depth to elevation */

SET switch_on_level = switch_on_level + us_node.chamber_floor,
switch_off_level = switch_off_level + us_node.chamber_floor