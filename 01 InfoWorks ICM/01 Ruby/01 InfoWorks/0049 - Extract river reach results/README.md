# Ruby Script for Fetching River Reach Results in InfoWorks ICM

This Ruby script is used to fetch river reach results from a specific simulation in the InfoWorks ICM software. Here's a summary of what it does:

- It first opens the database and retrieves a specific simulation model object using a hardcoded ID.

- It then sets the current timestep of the simulation to 10 (this is also hardcoded in this example).

- It iterates over each row object in the 'hw_river_reach' table of the simulation.

- For each row object (each river reach), it builds an array of section IDs.

- It also builds an array of results for each section using the 'rr_flow' result field.

- It then builds a 2D array matching the section IDs with their corresponding results.

- Finally, it prints the ID of the river reach and the matching section IDs and results.

Note: In case of any errors during the execution, the error message is printed to the console.