/* All Links if missing inverts
// Object Type: All Nodes
// Spatial Search: blank
*/

-- Convert user_number_2 from meters to feet by multiplying it by 3.28084
Set user_number_2 = 3.28084 * user_number_2;

-- Convert user_number_3 from meters to feet by multiplying it by 3.28084
Set user_number_3 = 3.28084 * user_number_3;

-- Update the us_invert (Upstream Invert) by adding the value of user_number_2
Set us_invert = us_invert + user_number_2;

-- Update the ds_invert (Downstream Invert) by adding the value of user_number_3
Set ds_invert = ds_invert + user_number_3;
