/* Assign R Values
// Object Type: RTK hydrograph
// Spatial Search: blank
*/

/*  Calculate R1, R2, and R3 values from implicit tri-triangle values from InfoSewer*/
SET R1 = (user_number_2/100)*(user_number_1/100),
R2 = (user_number_3/100)*(user_number_1/100),
R3 = ((100 - user_number_2 - user_number_3)/100)*(user_number_1/100)