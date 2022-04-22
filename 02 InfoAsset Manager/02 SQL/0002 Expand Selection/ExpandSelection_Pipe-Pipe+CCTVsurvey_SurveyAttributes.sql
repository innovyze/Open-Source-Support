/*Expand selection from Pipes to CCTV, then only select certain CCTV Surveys, then select their related pipes.
//Object Type: All Links
//Spatial Search: blank
*/


UPDATE [All Links] SET $link_selected = 0;
UPDATE [CCTV Survey] SET $cctv_selected = 0;
UPDATE SELECTED Pipe SET $link_selected = 1;
UPDATE Pipe SET cctv_surveys.$cctv_selected = 1 WHERE $link_selected = 1;
SELECT FROM [CCTV Survey] WHERE $cctv_selected = 1;

LIST $codes='ID','IR','IG';
UPDATE SELECTED [CCTV Survey] SET $sel = 1, pipe.$cctv_sel = 1, pipe.$cctv_id = id, pipe.$cctv_date = when_surveyed WHERE current = 1 AND MEMBER(LEFT(details.code,2),$codes); 
CLEAR SELECTION;

SELECT ALL FROM [CCTV Survey] WHERE $sel = 1;
SELECT ALL FROM Pipe WHERE $cctv_sel = 1;

SELECT SELECTED OID AS 'Pipe ID',  $cctv_id AS 'CCTV Survey', $cctv_date AS "Survey Date" FROM pipe;