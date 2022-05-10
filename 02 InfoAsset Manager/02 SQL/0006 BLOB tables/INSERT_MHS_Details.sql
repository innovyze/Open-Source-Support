/*Create records in the Manhole Survey Details table, Distance=0 and Code='MHS', where the count of details records=0 (no details on the survey currently).
//Object Type: Manhole Survey
//Spatial Search: blank
*/
INSERT INTO [Manhole Survey].details (id,details.distance,details.code)
SELECT oid,'0.0','MHS' WHERE count(details.code)=0