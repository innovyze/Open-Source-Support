// ICM SWMM Links
// No spatial query

// Set user_number_9 to the absolute value of the difference between us_invert and ds_invert, divided by length
// conduit_height is in inches, so divide by 12 to convert to feet
// if SI units are being used in ICM SWMM then devide by 1000 to convert to meters and change 1.4859 to 1.0
Set user_number_9 = abs (us_invert - ds_invert) / length;
Set user_number_9 = 0.0001 where user_number_9 = 0.0;

// Set user_number_10 to the full flow calculated using Mannings equation for a circular pipe 
Set user_number_10 = 1.4859/Mannings_N * (3.14159 * conduit_height/12 *conduit_height/12 / 4) * (conduit_height/12 / 4)^0.6667 * (user_number_9)^0.5;

// The Mannings equation for full flow in a circular pipe is Q = (1/n) * A * R^(2/3) * S^(1/2), where:

// Q is the flow rate in cfs
// n is the Mannings roughness coefficient
// A is the cross-sectional area of flow
// R is the hydraulic radius
// S is the slope of the energy line (head loss per length of pipe)
// For a full circular pipe, the cross-sectional area A = πD²/4 and the hydraulic radius R = D/4.