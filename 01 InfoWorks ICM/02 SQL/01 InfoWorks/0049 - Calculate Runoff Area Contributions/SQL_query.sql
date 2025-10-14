//Object: Subcatchment
//Spatial Search: blank

// Calculate runoff area contributions by checking area_measurement_type
// If "Percent": multiplies area_percent_X by contributing_area
// If "Absolute": uses area_absolute_X directly
// Groups by system_type into a single summary table

SELECT
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_1 / 100.0) * contributing_area, area_absolute_1)) AS Runoff_Area_1,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_2 / 100.0) * contributing_area, area_absolute_2)) AS Runoff_Area_2,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_3 / 100.0) * contributing_area, area_absolute_3)) AS Runoff_Area_3,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_4 / 100.0) * contributing_area, area_absolute_4)) AS Runoff_Area_4,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_5 / 100.0) * contributing_area, area_absolute_5)) AS Runoff_Area_5,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_6 / 100.0) * contributing_area, area_absolute_6)) AS Runoff_Area_6,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_7 / 100.0) * contributing_area, area_absolute_7)) AS Runoff_Area_7,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_8 / 100.0) * contributing_area, area_absolute_8)) AS Runoff_Area_8,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_9 / 100.0) * contributing_area, area_absolute_9)) AS Runoff_Area_9,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_10 / 100.0) * contributing_area, area_absolute_10)) AS Runoff_Area_10,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_11 / 100.0) * contributing_area, area_absolute_11)) AS Runoff_Area_11,
  SUM(IIF(area_measurement_type = 'Percent', (area_percent_12 / 100.0) * contributing_area, area_absolute_12)) AS Runoff_Area_12

GROUP BY SYSTEM_TYPE AS 'SUBCATCHMENT_RUNOFF_SUMMARY';
