//Object: SWMM Options
//Spatial Search: blank

SELECT
allow_ponding,
force_main_equation,
head_tolerance,
inertial_damping,
infiltration,
max_trials,
min_slope,
min_surfarea,
normal_flow_limited,
units;

SELECT
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
units
INTO
$allow_ponding,
$force_main_equation,
$head_tolerance,
$inertial_damping,
$infiltration,
$max_trials,
$min_slope,
$min_surfarea,
$normal_flow_limited,
$otype,
$units;

LET $Blank1 = 'Ponding can be Yes, No or 1 or 0';
PROMPT TITLE 'ICM SWMM Network Options'; 
PROMPT LINE $Blank1 'Surface Ponding';
LET $Blank2 = 'Hazen-Williams Darcy-Weisbach';
PROMPT LINE $Blank2 'Force Main Equation options are';
LET $Blank3 = 'The tolerance used to determine when the SWMM solver has converged';
PROMPT LINE $Blank3 'Head Tolerance ';
LET $Blank4 = 'None Partial Full ';
PROMPT LINE $Blank4 'Inertial Damping options are ';
LET $Blank5 = 'Horton, Modified Horton, Green Ampt, Modified Green Ampt, Curve Number';
PROMPT LINE $Blank5 'Infiltration Models can be';
LET $Blank6 = 'The maximum number of trials allowed for the SWMM solver to converge';
PROMPT LINE $Blank6 'Max Trials';
LET $Blank7 = 'The minimum value allowed for a conduits slope (%)';
PROMPT LINE $Blank7 'Min Slope';
LET $Blank8 = 'The minimum surface area used for nodes when computing changes in water depth';
PROMPT LINE $Blank8 'Min Surface Area';
LET $Blank9 = 'Slope, Froude, Both';
PROMPT LINE $Blank9 'Normal Flow Limited options are';
LET $Blank10 = 'CFS, MGD, CMS, LPS, MLD';
PROMPT LINE $Blank10 'Units may be';
PROMPT DISPLAY;


