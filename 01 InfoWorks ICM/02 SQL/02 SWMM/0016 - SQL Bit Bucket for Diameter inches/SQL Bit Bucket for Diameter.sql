/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets =  6,8,12,24,36,48,60,72,84,96,120;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_width, $buckets), $buckets) AS 'Diameter(in)'
