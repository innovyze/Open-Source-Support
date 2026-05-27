/*Create defect/observation rows in the CCTV Survey Details table, Distance=0 and Code='MH', and 'SA' with default remarks.
//Object Type: CCTV Survey
//Spatial Search: blank
*/
INSERT INTO [CCTV Survey].details (id,details.distance,details.code, details.remarks)
SELECT oid,'0.0','MH','';
INSERT INTO [CCTV Survey].details (id,details.distance,details.code, details.remarks)
SELECT oid,'0.0','SA','Customer Not Home';