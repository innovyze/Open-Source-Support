/*Select Pipes between the Upstream Node as selected/entered into the first prompt (which contains all Node IDs on the Network) and the Downstream Node selected/entered into the second prompt (which contains all Node IDs on the Network downstream of the selected US Node), then expand the selection to include the Nodes connected to the selected Links.
//Object Type: All Nodes
//Spatial Search: blank
*/

LIST $Nodes STRING;
SELECT DISTINCT node_id INTO $Nodes FROM [All Nodes];

CLEAR SELECTION;
PROMPT TITLE 'Select/Enter Upstream Node';
PROMPT LINE $us 'Upstream Node' STRING LIST $Nodes;
PROMPT DISPLAY;

SELECT ALL FROM [All Nodes] WHERE node_id=$us;


LIST $DSNodes STRING;
SELECT DISTINCT ds_node_id INTO $DSNodes FROM [All Links] WHERE all_us_links.us_node_id=$us;

PROMPT TITLE 'Select/Enter Downstream Node';
PROMPT LINE $ds 'Downstream Node' STRING LIST $DSNodes;
PROMPT DISPLAY;

SELECT ALL FROM [All Links] WHERE (all_us_links.us_node_id=$us OR us_node_id=$us) AND (all_ds_links.ds_node_id=$ds OR ds_node_id=$ds);
UPDATE SELECTED [All Links] SET $selected=1;
SELECT ALL FROM [All Nodes] WHERE us_links.$selected=1 OR ds_links.$selected=1;