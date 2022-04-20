/*With Pipe(s) selected select the associated CCTV Survey(s) with the highest when_surveyed date.
//Object Type: CCTV Survey
//Spatial Search: blank
*/


UPDATE SELECTED PIPE SET cctv_surveys.$surveyselection=1 WHERE cctv_surveys.when_surveyed=MAX(cctv_surveys.when_surveyed);
SELECT FROM [CCTV Survey] WHERE $surveyselection=1;
