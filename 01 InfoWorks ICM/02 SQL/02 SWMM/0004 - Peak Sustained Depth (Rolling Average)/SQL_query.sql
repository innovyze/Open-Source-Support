//Object: All links
//Spatial Search: blank

// Returns the peak sustained depth for each link — the highest average depth
// found across any rolling window of consecutive timesteps in the simulation.
// Works with both metric and US customary unit models.

LET $n = 90;      // Total number of timesteps in the simulation result
LET $period = 3;  // Window size (effective window = $period + 1 timesteps due to inclusive bounds)
SET $AVG = 0;     // Tracks the highest rolling average found so far

LET $i=1; // Sliding window start index
WHILE $i<=$n-$period;

  // Average depth over the current window [$i, $i+$period] (inclusive)
  SET $AVG2 = AVG(tsr.depth) WHEN tsr.timestep_no >= $i AND tsr.timestep_no <= $i+$period;

  // Retain this window's average if it exceeds the current peak
  SET $AVG = IIF($AVG2 > $AVG,$AVG2,$AVG);

  LET $i=$i+1; // Advance window by one timestep
WEND;

SELECT OID as [Link ID], $AVG AS [Peak Sustained Depth]