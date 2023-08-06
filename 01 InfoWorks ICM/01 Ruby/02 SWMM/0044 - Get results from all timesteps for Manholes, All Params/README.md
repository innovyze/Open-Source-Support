# Getting results from all timesteps
The script in this example returns all results of selected nodes for all simulation timesteps. This can be expanded to include other tables or results fields, but that is outside the scope of the example.

![](gif001.gif)

## Technical note
The two main methods in this script are `list_timesteps`/`list_gauge_timesteps` and `results`/`gauge_results`. The script matches the simulation timesteps array with results array. In case the simulation contains "gauged" results, the script returns the results at the gauged timestep.

# Summary:

# Library and Environment Setup:

The script imports the 'date' library to work with dates.
It retrieves the current network object from InfoWorks using the WSApplication.current_network method.
Time Step Information:

The script fetches the count and the list of time steps available in the network.

# Result Fields:

A list of result field names is defined, which indicates the kinds of data (like depth, volume, flow rates, etc.) that the script will fetch for each node.

# Processing Selected Objects:

The script iterates over each selected object in the network. For each selected object:
It attempts to get its corresponding row object assuming it's a node.
If the selected object isn't a node, an error is raised.
For each result field name:
It checks if the count of results for that field matches the count of time steps.
If they match, the script calculates various statistics like total, total integrated over time, mean, max, min values, and count for the results.
Based on the result field's name, the script prints either the sum or the end value, along with the other statistics.

# Error Handling:

The script has built-in error handling using rescue blocks to gracefully handle potential issues like:
A selected object not being a node.
A particular result field not existing for a node.
Error messages are commented out, which means they won't be printed if an error occurs.

Overall, the primary objective of the script is be the extraction and statistical analysis of various data fields for selected nodes within an ICM InfoWorks network model.