LIST $MyRoad STRING;
SELECT DISTINCT location INTO $MyRoad;

PROMPT TITLE 'Road Selection';
PROMPT LINE $MyRoadSelection 'Enter Road Name:' STRING LIST $MyRoad;
PROMPT DISPLAY;

location = $MyRoadSelection;