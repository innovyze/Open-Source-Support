//Object: Subcatchment
//Spatial Search: blank

LIST $Surface = "All", "Surface 1", "Surface 2", "Surface 3";
List $Out = "Outlet", "Pervious", "Impervious";

PROMPT LINE  $SS 'suds_controls.suds_structure' STRING LIST $Type;
PROMPT LINE  $SID 'suds_controls.id' STRING;
PROMPT LINE  $A 'suds_controls.area %age';
PROMPT LINE  $NU 'suds_controls.num_units';
PROMPT LINE  $IAT 'suds_controls.impervious_area_treated_pct';
PROMPT LINE  $PAT 'suds_controls.pervious_area_treated_pct';
PROMPT LINE  $O 'suds_controls.outflow_to' LIST $Out;
PROMPT LINE  $SU 'suds_controls.surface' LIST $Surface;

PROMPT DISPLAY;

INSERT INTO subcatchment.suds_controls (
  subcatchment_id,
  suds_controls.suds_structure,
  suds_controls.id,
  suds_controls.area,
  suds_controls.num_units,
  suds_controls.impervious_area_treated_pct,
  suds_controls.pervious_area_treated_pct,
  suds_controls.outflow_to,
  suds_controls.surface
)
SELECT
  oid,
  $SS,
  $SID,
  contributing_area * $A * 100,
  $NU,
  $IAT,
  $PAT,
  $O,
  $SU
FROM Subcatchment
