/*Select CCTV Surveys where at least one observation code (details.code) is within a list of codes.
//Object Type: CCTV Survey
//Spatial Search: blank
*/


//Define the list of codes
LIST $Mylist = 'CC','CCJ','CL','CLJ','CM','CMJ';
//Select where the details.code is in the list
SELECT WHERE MEMBER(details.code,$Mylist);