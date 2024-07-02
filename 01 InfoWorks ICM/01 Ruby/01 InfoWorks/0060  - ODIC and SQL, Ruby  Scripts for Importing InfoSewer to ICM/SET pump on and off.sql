/* Set pump on and off
// Object Type: Pump
// Spatial Search: Nearest
// Distance: 10
// Layer Type: Network layer
// Layer: Node
*/

/*  Convert the switch_on_level and switch_off_level from depth to elevation based on the chamber floor elevation */


SET switch_on_level = switch_on_level + spatial.chamber_floor,
switch_off_level = switch_off_level + spatial.chamber_floor