# Getting results from all timesteps
The script in this example returns `depnod` results of selected nodes for all simulation timesteps. This can be expanded to include other tables or results fields, but that is outside the scope of the example.

![](gif001.gif)

## Technical note
The two main methods in this script are `list_timesteps`/`list_gauge_timesteps` and `results`/`gauge_results`. The script matches the simulation timesteps array with results array. In case the simulation contains "gauged" results, the script returns the results at the gauged timestep.

### Known limitation — results timestep multiplier of 0
If the simulation was run with a **results timestep multiplier of 0**, the `gauge_results` method will return no results and the script will fail, even when gauge results are visible in the UI graph.

To use this script, re-run the simulation with a results timestep multiplier greater than 0.

![](png001.png)