/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets =  75, 150,200,300,600, 900, 1000, 1200,1500,2000,2500,3000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_width, $buckets), $buckets) AS 'Diameter(ICM, mm)'