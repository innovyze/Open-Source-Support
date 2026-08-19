/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets = 10,25,50,100,200,500,1000,2000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_length, $buckets), $buckets) AS 'Length (meters)'