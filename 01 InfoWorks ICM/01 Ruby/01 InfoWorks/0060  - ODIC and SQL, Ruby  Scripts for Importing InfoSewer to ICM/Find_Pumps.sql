/* Find_Pumps.sql
// Object Type: All Links
// Spatial Search: blank
*/

/*
//This SQL selects Conduits tagged as 'Pump', deletes their existing records from the Conduit table, and reinserts them into the Pump table
*/

LIST $asset_id String;
SELECT DISTINCT asset_id INTO $asset_id WHERE user_text_10 = 'Pump';
LET $i = 1;
WHILE $i <= LEN($asset_id);
SELECT us_node_id INTO $us_node_id WHERE asset_id =AREF($i, $asset_id);
SELECT ds_node_id INTO $ds_node_id WHERE asset_id =AREF($i, $asset_id);
SELECT link_suffix into $link_suffix WHERE asset_id =AREF($i, $asset_id); 
DELETE WHERE asset_id =AREF($i, $asset_id);
INSERT INTO pump (us_node_id, ds_node_id, link_suffix, asset_id)
VALUES($us_node_id, $ds_node_id, $link_suffix, AREF($i, $asset_id));
LET $i = $i+1;
WEND;