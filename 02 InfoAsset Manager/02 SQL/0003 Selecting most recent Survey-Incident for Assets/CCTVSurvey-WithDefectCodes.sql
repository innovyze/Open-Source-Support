///Select the most recent CCTV Survey(s) with the highest when_surveyed date with specific defect code or defect code & characterisation1 value, exclude 'Split Survey'.
//Object Type: CCTV Survey
//Spatial Search: blank


UPDATE PIPE SET cctv_surveys.$surveyselection=1 WHERE cctv_surveys.when_surveyed=MAX(cctv_surveys.when_surveyed);
SELECT FROM [CCTV Survey] WHERE (details.code='SAV' OR (details.code='LD' AND details.characterisation1='H')) AND $surveyselection=1;
