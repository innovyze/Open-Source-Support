/*Select a Node with the Node ID entered into the prompt
//Object Type: All Nodes
//Spatial Search: blank
*/

CLEAR SELECTION;
PROMPT TITLE 'Select Manhole';
PROMPT LINE $Mh 'Manhole ID' STRING;
PROMPT DISPLAY;

SELECT ALL WHERE node_id = $Mh;