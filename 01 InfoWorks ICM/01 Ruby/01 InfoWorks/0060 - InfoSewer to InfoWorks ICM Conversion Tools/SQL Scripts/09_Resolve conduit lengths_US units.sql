/* Resolve conduit lengths - US units
// Object Type: Conduit
// Spatial Search: blank
*/

/*Resolves conduit lengths which are too short for ICM*/

SET conduit_length = 3.3 WHERE conduit_length < 3.3;

/*SET conduit_length = 16404 WHERE conduit_length > 16404*/