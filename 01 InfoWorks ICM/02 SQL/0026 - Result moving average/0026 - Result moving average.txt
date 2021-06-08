//All Links

LET $n = 90; //number of timesteps to investigate
LET $period = 3; //period of moving average
SET $AVG = 0;

LET $i=1; //loop
WHILE $i<=$n-$period;

SET $AVG2 = AVG(tsr.ds_depth) WHEN tsr.timestep_no >= $i AND tsr.timestep_no <= $i+$period; //Moving average calculation

SET $AVG = IIF($AVG2 > $AVG,$AVG2,$AVG); //Max calculation

LET $i=$i+1;
WEND;

SELECT OID, $AVG AS 'Moving Average'