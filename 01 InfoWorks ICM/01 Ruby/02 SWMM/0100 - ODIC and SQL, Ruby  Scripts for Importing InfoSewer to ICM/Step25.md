# Summary of Step25_User_123_ICM_Scenario_csv.rb

This script imports a CSV file containing scenarios for an InfoSewer or InfoSWMM network, deletes all existing scenarios in the current network (except the 'Base' scenario), and adds the scenarios from the CSV file to the network.

## Steps

1. **Prompt for folder**: The script prompts the user to select a folder containing the CSV file.

2. **Read CSV file**: The script reads the CSV file named 'scenario.csv' in the selected folder. It excludes certain headers and stores each row as a hash in an array.

3. **Delete existing scenarios**: The script deletes all scenarios in the current network, except for the 'Base' scenario.

4. **Add new scenarios**: The script iterates over the array of hashes (each representing a row in the CSV file). For each hash, it checks if the 'ID' value is not 'BASE'. If it's not, it adds a new scenario to the network with the 'ID' value as the scenario name.

5. **Print results**: The script prints the total number of scenarios added to the network.

This script is useful for updating the scenarios in an InfoSewer or InfoSWMM network based on a CSV file. It allows for easy bulk addition of scenarios.