///Select the most recent CCTV Survey(s) with the highest when_surveyed date, with hard_wired_structural_grade=5 or 4, exclude 'Split Survey'.
//Object Type: CCTV Survey
//Spatial Search: blank


UPDATE PIPE SET cctv_surveys.$surveyselection=1 WHERE cctv_surveys.when_surveyed=MAX(cctv_surveys.when_surveyed);
SELECT FROM [CCTV Survey] WHERE (hard_wired_structural_grade=5 OR hard_wired_structural_grade=4) AND splitsurvey=0 AND $surveyselection=1;
