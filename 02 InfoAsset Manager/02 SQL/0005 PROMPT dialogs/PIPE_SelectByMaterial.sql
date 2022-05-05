/*Select Pipes with the pipe_material as selected in the prompt dialog, the prompt dialog is populated with the distinct pipe_material values on the Network.
//Object Type: All Links / Pipe
//Spatial Search: blank
*/

LIST $material STRING;
SELECT DISTINCT pipe_material INTO $materials;

CLEAR SELECTION;
PROMPT TITLE 'Select Pipe Material';
PROMPT LINE $material 'Material' STRING LIST $materials;
PROMPT DISPLAY;

SELECT ALL WHERE material=$material;