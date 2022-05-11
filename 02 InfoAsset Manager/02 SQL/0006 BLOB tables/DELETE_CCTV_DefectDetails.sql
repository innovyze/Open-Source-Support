/*Delete records from the CCTV Survey Details table where the Code is not 'ID' or 'IDJ'.
//Object Type: CCTV Survey
//Spatial Search: blank
*/
DELETE FROM [CCTV Survey].details WHERE  details.code <> 'ID' AND details.code <> 'IDJ';