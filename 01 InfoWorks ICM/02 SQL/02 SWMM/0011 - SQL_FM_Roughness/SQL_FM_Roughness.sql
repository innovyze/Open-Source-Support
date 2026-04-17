/* Make Subcatchments
// Object Type: All Nodes and Subcatchments
// Spatial Search: blank
*/

/*  Update 'user_text_9' to 'FM' if 'bottom_roughness_Manning' is greater than 1 */
SET user_text_9 = 'FM'
WHERE bottom_roughness_N > 1;

/*  Update 'user_number_9' to the value of 'bottom_roughness_Manning' if it is greater than 1*/
SET user_number_9 = bottom_roughness_Manning
WHERE bottom_roughness_N > 1;

/*  Update 'bottom_roughness_Manning' to 0.014 if its current value is greater than 1*/
SET bottom_roughness_N = 0.014
WHERE bottom_roughness_N > 1;
SET top_roughness_N= 0.014
WHERE top_roughness_N > 1;