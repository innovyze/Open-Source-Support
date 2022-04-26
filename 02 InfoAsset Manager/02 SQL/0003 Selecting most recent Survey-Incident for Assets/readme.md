# Selecting the most recent Surveys, Incidents, or Repairs related to an Asset
## [CCTVSurvey_FromPipe.sql](./CCTVSurvey_FromPipe.sql)
With Pipe(s) selected select the associated CCTV Survey(s) with the highest when_surveyed date.  

## [ManholeSurvey_FromNode.sql](./ManholeSurvey_FromNode.sql)
With Node(s) selected select the associated Manhole Survey(s) with the highest survey_date date. 

## [CCTVSurvey-ByGrade.sql](./CCTVSurvey-ByGrade.sql)
Select the most recent CCTV Survey(s) with the highest when_surveyed date, with hard_wired_structural_grade=5 or 4, exclude 'Split Survey'.  

## [CCTVSurvey-ByGrade-WithinDates.sql](./CCTVSurvey-ByGrade-WithinDates.sql)
Select the most recent CCTV Survey(s) with the highest when_surveyed date within a specified date range (via prompt dialog), with hard_wired_structural_grade=5 or 4, exclude 'Split Survey'.  

## [CCTVSurvey-WithDefectCodes.sql](./CCTVSurvey-WithDefectCodes.sql)
Select the most recent CCTV Survey(s) with the highest when_surveyed date with specific defect code or defect code & characterisation1 value, exclude 'Split Survey'.  
