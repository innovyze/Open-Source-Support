// Object: All Links
// Spatial Search: blank
// Units: US customary only (ft, cfs)

// Calculates pipe gradient (slope) from invert levels and pipe length, stored in user_number_9.
// A minimum slope of 0.0001 is applied to prevent division by zero in the full flow calculation.
SET user_number_9 = abs(us_invert - ds_invert) / length;
SET user_number_9 = 0.0001 WHERE user_number_9 = 0.0;

// Calculates Manning's full flow capacity (cfs) for a circular pipe, stored in user_number_10.
// conduit_height is divided by 12 to convert from inches to feet.
// Manning's equation for full circular pipe: Q = (1.4859/n) * A * R^(2/3) * S^(1/2)
//   Q = flow rate (cfs)
//   n = Manning's roughness coefficient
//   A = cross-sectional area = π(D/2)² = πD²/4
//   R = hydraulic radius = D/4 (for full circular pipe)
//   S = pipe gradient (calculated above)
SET user_number_10 = 1.4859 / Mannings_N * (3.14159 * (conduit_height/12) * (conduit_height/12) / 4) * ((conduit_height/12) / 4)^0.6667 * (user_number_9)^0.5;