/*Select surveys where the value entered into the prompt matches part of the surveyed_by field - so entering 'Steve' will select surveys with 'Steve', 'Steve Baker', 'Mr Steve' etc. in the surveyed_by field.
//Object Type: Manhole/CCTV Survey
//Spatial Search: blank
*/

PROMPT LINE $SurveyedBy "Surveyed by" STRING;
PROMPT TITLE "Enter Surveyor's name";
PROMPT DISPLAY;

WHERE surveyed_by MATCHES  ".*"+$SurveyedBy+".*" 