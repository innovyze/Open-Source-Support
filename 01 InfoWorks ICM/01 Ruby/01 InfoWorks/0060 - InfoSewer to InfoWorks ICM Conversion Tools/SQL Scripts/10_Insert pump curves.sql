/* Insert pump curves
// Object Type: Pump
// Spatial Search: blank
*/

/* Set single point and three point pumps to rotodynamic */ 
SET link_type = 'ROTPMP' WHERE user_text_1 = 1 OR user_text_1 = 2;
 
/* Insert head discharge tables using Pump Asset IDs */
INSERT INTO [Head Discharge] (head_discharge_id) SELECT asset_id FROM Pump;
 
/* Assign head discharge to pump as pump asset id */
SET head_discharge_id = asset_id;
 
/* Clear any existing contents from HDP tables */
DELETE ALL FROM [Head discharge].HDP_table;
 
/* Insert single point pump curves */
INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, 1.33 * user_number_3, 0 FROM Pump WHERE user_text_1 = 1;
 
INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_3, user_number_4  FROM Pump WHERE user_text_1 = 1;
 
INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, 0, 2 * user_number_4  FROM Pump WHERE user_text_1 = 1;
 
/* Insert three point pump curves */
INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_2, 0 FROM Pump WHERE user_text_1 = 2;
 
INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_3, user_number_4  FROM Pump WHERE user_text_1 = 2;
 
INSERT INTO [Head discharge].HDP_table (head_discharge_id, HDP_table.head, HDP_table.discharge) SELECT asset_id, user_number_5, user_number_6  FROM Pump WHERE user_text_1 = 2;