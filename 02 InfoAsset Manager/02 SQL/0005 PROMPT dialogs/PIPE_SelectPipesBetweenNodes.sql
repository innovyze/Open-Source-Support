/*Select Pipes between the two Nodes as entered into the prompt - a follow up prompt will state the selected Pipe count or state no pipes selected if there is no link between the Nodes.
//Object Type: All Links
//Spatial Search: blank
*/

CLEAR SELECTION;
PROMPT TITLE 'Pipes by Manholes';
PROMPT LINE $USMH 'Upstream Manhole' STRING;
PROMPT LINE $DSMH 'Downstream Manhole' STRING;
PROMPT DISPLAY;


SELECT FROM [All Links] WHERE 
(all_us_links.us_node_id=$USMH OR us_node_id=$USMH)
AND
(all_ds_links.ds_node_id=$DSMH OR ds_node_id=$DSMH);


SELECT SELECTED COUNT(*) INTO $count FROM [All Links]; 
IF $count>0;
PROMPT TITLE 'Pipes Selected';
PROMPT LINE $count 'Number of Pipe selected';
PROMPT DISPLAY READONLY;
ELSE;
PROMPT TITLE 'No Pipes Selected';
PROMPT LINE $count 'No connection between US & DS Nodes found';
PROMPT DISPLAY READONLY;
ENDIF;