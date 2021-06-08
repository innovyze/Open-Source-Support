// Selects GIS points contained in a subcatchment and saves the count as a user_number_6

SPATIAL NONE;
SET $number=0;
SPATIAL Contains GIS "[TAB] test";
SET $number=$number+1;
SPATIAL NONE;
SET user_number_6 = $number;
