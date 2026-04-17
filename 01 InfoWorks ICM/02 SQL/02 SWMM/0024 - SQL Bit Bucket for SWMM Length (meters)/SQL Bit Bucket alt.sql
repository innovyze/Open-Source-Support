/* 
// Object Type: All Links
// Spatial Search: blank
*/

LIST $buckets =  0, 100, 200, 225, 250, 275, 300, 325, 350, 375, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_length, $buckets), $buckets) AS 'Length (m)';

LIST $bucketswidth = 0, 100, 200, 225, 250, 275, 300, 325, 350, 375, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(conduit_width, $bucketsmm), $bucketsmm) AS 'Width (mm)';

LIST $bucketsinv =  0, 100, 200, 225, 250, 275, 300, 325, 350, 375, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(us_invert, $bucketsinv), $bucketsinv) AS 'US Invert (m)';

LIST $bucketscap=  0, 100, 200, 225, 250, 275, 300, 325, 350, 375, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(capacity, $bucketscap), $bucketscap) AS 'Capacity';

LIST $bucketsgrad =  0, 100, 200, 225, 250, 275, 300, 325, 350, 375, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000;
SELECT count(*) AS 'Count' GROUP BY TITLE(RINDEX(gradient, $bucketsgrad), $bucketsgrad) AS 'Gradient';