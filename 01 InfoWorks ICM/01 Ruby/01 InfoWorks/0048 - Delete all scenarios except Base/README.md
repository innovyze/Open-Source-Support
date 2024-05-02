# Ruby Script for Deleting All Scenarios Except Base in InfoWorks ICM

This Ruby script is used to delete all scenarios except the base scenario in the InfoWorks ICM software. Here's a summary of what it does:

- It first sets up the current network (`net`).

- It then iterates over each scenario in the network.

- For each scenario, it checks if the scenario name is not 'Base'.

- If the scenario name is not 'Base', it deletes the scenario.

- After all scenarios except the base scenario have been deleted, it prints 'All scenarios deleted'.