//Object: Polygon
//Spatial Search: Contains, Network layer, All Nodes

SET $sum=0;
SET $count=0;

//sum the user_number_1 field
SET $sum= $sum + spatial.user_number_1;
//create a count of nodes inside the polygons
SET $count=$count + 1;
//calculate the average
SET $avg=$sum/$count;
//table select
SELECT OID,$sum,$count,$avg;