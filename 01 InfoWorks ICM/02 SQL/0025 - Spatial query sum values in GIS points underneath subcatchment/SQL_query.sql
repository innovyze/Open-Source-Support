SPATIAL NONE;
SET $sum = 0; 
SPATIAL Contains GIS "[SHP] points";
SET $sum = $sum + spatial.value WHERE spatial.ident="A";
SPATIAL NONE;
SELECT OID,$sum;
SET user_number_10= $sum;