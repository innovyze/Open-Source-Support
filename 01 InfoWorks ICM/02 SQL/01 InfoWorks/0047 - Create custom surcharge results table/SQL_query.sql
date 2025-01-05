/* Create custom surcharge results table
// Object Type: Conduit
// Spatial Search: blank
*/

/* Load simulation results onto the GeoPlan prior to running the query */

/* Define picklist of surcharge values */
LIST $Surcharge = 0.0, 0.3, 0.5, 0.7, 0.75, 0.8, 0.95, 0.99, 1.01;

/* Define picklist of diameters (inches) */
LIST $Dia = 0, 6, 8, 10, 15, 18, 21, 24, 27, 30, 36, 42, 48;

/* Prompt setup to select a surcharge value and diameter value from the defined lists */
PROMPT TITLE 'Interactive d/D and Surcharge Summary by Pipe';

PROMPT LINE $SurchargeSelection 'd/D >=:' LIST $Surcharge;

PROMPT LINE $DiaSelection 'Diameter (in) >=:' LIST $Dia;

PROMPT DISPLAY;

/* Display a SQL table with conduits meeting the defined criteria */
SELECT us_node_id, ds_node_id, link_suffix, conduit_width, sim.max_Surcharge WHERE (sim.max_Surcharge >= $SurchargeSelection AND conduit_width >= $DiaSelection)
