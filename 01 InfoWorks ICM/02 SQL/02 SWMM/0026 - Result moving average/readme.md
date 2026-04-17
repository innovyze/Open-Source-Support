# Moving Average Calculation Script for InfoWorks ICM

This SQL script calculates a moving average of the `tsr.depth` field over a specified period and then finds the maximum moving average for each link in an InfoWorks ICM model network.

## How it Works

The script operates in several steps:

1. **Variable Initialization**: The script initializes several variables, including `$n` (the number of timesteps to investigate), `$period` (the period of the moving average), `$AVG` (the maximum moving average), and `$i` (a loop counter).

2. **Moving Average Calculation Loop**: The script enters a loop where it calculates a moving average of the `tsr.depth` field for each timestep within the specified period. It then updates `$AVG` if the current moving average is greater than the current maximum.

3. **Maximum Moving Average Selection**: After the loop, the script selects the object ID (`OID`) and the maximum moving average (`$AVG`) for each link.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically calculate a moving average of the `tsr.depth` field over the specified period and find the maximum moving average for each link.