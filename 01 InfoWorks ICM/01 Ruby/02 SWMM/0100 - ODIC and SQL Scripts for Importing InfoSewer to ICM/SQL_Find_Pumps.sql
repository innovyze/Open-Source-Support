/* Update Pump Table
// Object Type: All Pumps and Links
// Spatial Search: blank
*/

/* Insert new records into the 'pump' table based on certain conditions in the 'link' table */
INSERT INTO pump (us_node_id, ds_node_id, link_suffix, asset_id)
SELECT us_node_id, ds_node_id, '2', asset_id

/* FROM link  -- Source table for the SELECT */
WHERE user_text_10 = 'Pump'; /* Condition to filter records in the source table */

/* Delete records from the link table where user_text_10 equals 'Pump' */
DELETE WHERE user_text_10 = 'Pump';