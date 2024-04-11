//Object: SWMM Options
//Spatial Search: blank

Select
allow_ponding,
force_main_equation,
head_tolerance,  
inertial_damping,
infiltration,
max_trials,
min_slope,
min_surfarea,
normal_flow_limited,
otype,
units;

LIST $Surface = "All", "Surface 1", "Surface 2", "Surface 3";
List $Out = "Outlet", "Pervious", "Impervious";

PROMPT LINE  $PAT 'suds_controls.pervious_area_treated_pct';
PROMPT LINE  $O 'suds_controls.outflow_to' LIST $Out;
PROMPT LINE  $SU 'suds_controls.surface' LIST $Surface;
PROMPT DISPLAY;