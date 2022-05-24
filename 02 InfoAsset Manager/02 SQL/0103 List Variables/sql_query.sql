LIST $z STRING;
LIST $y STRING;
SELECT DISTINCT system_type INTO $y FROM [All Links] ORDER BY system_type ASC;
LIST $x = 'Zero','One','Two','Three','Four','Five';
LOAD $z FROM FILE "C:\TEMP\Variable.txt";

PROMPT LINE $z1 'Listz' LIST $z;
PROMPT LINE $y1 'Listy' LIST $y;
PROMPT LINE $x1 'Listx' LIST $x;
PROMPT DISPLAY;

SAVE $z,$x1,$y,$y1,$x,$x1 TO FILE 'C:\TEMP\output.txt';