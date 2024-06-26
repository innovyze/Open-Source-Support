/* Update Pump Table
// Object Type: All Pumps and Links
// Spatial Search: blank
*/

/* 
  Insert new records into the 'pump' table.
  These records are based on certain conditions met in the 'link' table.
*/
INSERT INTO pump (us_node_id, ds_node_id, link_suffix, asset_id)

/* 
  Use SELECT to fetch the corresponding values from the 'link' table.
  The link_suffix is set as '2' for each new record.
*/
SELECT us_node_id, ds_node_id, '2', asset_id

/* 
  Source table for the SELECT query is 'link'.
  Filter the records where the 'user_text_10' field is 'Pump'.
*/
WHERE user_text_10 = 'Pump';

/* 
  Delete records from the 'link' table where 'user_text_10' equals 'Pump'.
  This helps to avoid duplicate or unnecessary records.
*/
DELETE WHERE user_text_10 = 'Pump';