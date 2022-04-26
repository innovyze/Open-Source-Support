/*With Node(s) selected select the associated Manhole Survey(s) with the highest survey_date date.
//Object Type: Manhole Survey
//Spatial Search: blank
*/


UPDATE SELECTED NODE SET manhole_surveys.$surveyselection=1 WHERE manhole_surveys.survey_date=MAX(manhole_surveys.survey_date);
SELECT FROM [Manhole Survey] WHERE $surveyselection=1;
