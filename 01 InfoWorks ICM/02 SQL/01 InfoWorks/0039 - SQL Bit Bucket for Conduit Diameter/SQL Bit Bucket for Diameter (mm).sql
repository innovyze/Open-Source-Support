/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets = 100,150,225,300,375,450,600,750,900,1200,1500,1800,2400;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_width, $buckets), $buckets) AS 'Diameter(mm)'