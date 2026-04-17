/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets =  0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_length, $buckets), $buckets) AS 'Length (m)';

LIST $bucketsmm =  0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_width, $bucketsmm), $bucketsmm) AS 'Width (mm)';

LIST $bucketsinv =  1, 10, 100, 250, 500, 1000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(us_invert, $bucketsinv), $bucketsinv) AS 'US Invert (m)';

LIST $bucketscap=  0, 0.1, 0.5, 1, 2, 5, 10, 20;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(capacity, $bucketscap), $bucketscap) AS 'Capacity';

LIST $bucketsgrad =  0, 0.01, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(gradient, $bucketsgrad), $bucketsgrad) AS 'Gradient';