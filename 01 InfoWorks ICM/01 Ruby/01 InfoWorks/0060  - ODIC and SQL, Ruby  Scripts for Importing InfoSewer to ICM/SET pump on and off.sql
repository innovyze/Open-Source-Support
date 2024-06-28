/* Set pump on and off
// Object Type: Pump
// Spatial Search: blank
*/

/*  Convert the switch_on_level and switch_off_level from depth to delevation based on the chamber floor elevation */


SET switch_on_level = switch_on_level + spatial.chamber_floor, /*Update the switch_on_level by adding the chamber floor elevation */
    switch_off_level = switch_off_level + spatial.chamber_floor  /* Update the switch_off_level by adding the chamber floor elevation */ 