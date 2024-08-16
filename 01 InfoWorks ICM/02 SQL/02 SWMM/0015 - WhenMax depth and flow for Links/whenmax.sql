//Object: Conduit
//Spatial Search: blank

SELECT oid, WHENMAX (tsr.us_depth), WHENMAX (tsr.us_flow);
SELECT oid, WHENMAX (tsr.ds_depth), WHENMAX (tsr.ds_flow);
SELECT oid, WHENMIN (tsr.us_depth), WHENMIN  (tsr.us_flow);
SELECT oid, WHENMIN  (tsr.ds_depth), WHENMIN  (tsr.ds_flow);
SELECT oid, MAX (tsr.us_depth), MAX (tsr.us_flow);
SELECT oid, MAX (tsr.ds_depth), MAX (tsr.ds_flow);
SELECT oid, MIN (tsr.us_depth), MIN (tsr.us_flow);
SELECT oid, MIN (tsr.ds_depth), MIN (tsr.ds_flow);
SELECT oid, COUNT(tsr.us_flow), SUM(tsr.us_flow);
SELECT oid, COUNT(tsr.us_depth), SUM(tsr.us_depth); 
SELECT oid, COUNT(tsr.us_depth), SUM(tsr.us_flow); 
SELECT oid, COUNT(tsr.ds_depth), SUM(tsr.ds_depth);
SELECT oid, MIN (tsr.us_froude), MAX (tsr.us_froude);
SELECT oid, MIN (tsr.ds_froude), MAX (tsr.ds_froude);
SELECT oid, MIN (tsr.us_vel), MAX (tsr.us_vel);
SELECT oid, MIN (tsr.ds_vel), MAX (tsr.ds_vel);
