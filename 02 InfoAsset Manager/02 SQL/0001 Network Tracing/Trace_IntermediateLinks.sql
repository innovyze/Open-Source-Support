/*With some Links selected, select the intermediate Links
//Object Type: All Links
//Spatial Search: blank
*/


UPDATE [All Links] SET $link_selected = 0;

UPDATE SELECTED [All Links] SET $link_selected = 1;

SELECT FROM [All Links] WHERE all_us_links.$link_selected=1 AND all_ds_links.$link_selected=1 