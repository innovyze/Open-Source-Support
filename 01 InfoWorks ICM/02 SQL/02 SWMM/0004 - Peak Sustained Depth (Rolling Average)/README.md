# Peak Sustained Depth

This SQL script identifies the **peak sustained depth** for each link in an InfoWorks ICM (SWMM) simulation. Rather than returning the single highest instantaneous depth, it finds the rolling window of consecutive timesteps with the highest average depth — making it useful for identifying links that experience prolonged high-water conditions, not just brief spikes.

## Use Case and Value

Instantaneous peak depth can be caused by numerical noise or a single anomalous timestep. This script is more useful when you want to identify links that are **consistently under stress** over several consecutive timesteps — a better indicator of real hydraulic significance.

Typical applications include:

- Prioritising links for capacity improvement by identifying those with the worst sustained surcharge or flooding conditions
- Filtering out transient spikes that may not represent genuine hydraulic problems
- Comparing simulation scenarios based on sustained peak behaviour rather than instantaneous peaks

## How it Works

1. **Variable Initialization**: Set `$n` to match the total number of simulation timesteps, and `$period` to define the rolling window size (number of consecutive timesteps to average over).

2. **Rolling Window Loop**: The script slides a window of `$period + 1` consecutive timesteps across the simulation, calculating the average `tsr.depth` within each window.

3. **Peak Selection**: The highest rolling average found across all windows is retained and reported as the output value for each link.

## Parameters

| Variable | Description | Default |
|---|---|---|
| `$n` | Total number of timesteps to scan | `90` |
| `$period` | Rolling window size (in timesteps) | `3` |

> **Note:** The window is inclusive on both ends (`>= $i AND <= $i + $period`), so the effective window size is `$period + 1` timesteps. With the default `$period = 3`, each window covers 4 timesteps.

## Usage

Run the script against an open network with simulation results loaded in InfoWorks ICM. Update `$n` to match your simulation's timestep count before running. The output column `Moving Average` represents the peak sustained average depth for each link, in whichever unit system (metric or US customary) the model is configured to use.
