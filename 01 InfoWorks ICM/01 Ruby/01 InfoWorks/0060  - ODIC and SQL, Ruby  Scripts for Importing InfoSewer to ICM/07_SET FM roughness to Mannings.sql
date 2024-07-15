/* Set FM Roughness
// Object Type: All Links
// Spatial Search: blank
*/

/*  Update 'bottom_roughness_Manning' to 0.014 if its current value is greater than 1*/
SET bottom_roughness_N = 0.014 WHERE bottom_roughness_N > 1;
SET top_roughness_N= 0.014 WHERE top_roughness_N > 1