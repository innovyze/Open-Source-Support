/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets =  6,8,12,16,20,24,36,48,60,72,84,96,120,250,500,1000,2500,5000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_length, $buckets), $buckets) AS 'Length (feet)'