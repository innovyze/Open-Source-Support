/* Resolve conduit lengths - Metric
// Object Type: Conduit
// Spatial Search: blank
*/

/*Resolves conduit lengths which are too short or too long for ICM*/

SET conduit_length = 1 WHERE conduit_length < 1;
SET conduit_length = 5000 WHERE conduit_length > 5000