# Scenario_Link_Data.rb

This Ruby script is used to manipulate scenarios in an ICM InfoWorks network.

## Overview

1. **Setup**: The script starts by defining an array of factors and a parameter 'bottom_roughness_N'.

2. **Scenario Generation**: It generates scenario names by combining the parameter and each factor.

3. **Scenario Deletion**: The script deletes all scenarios in the network except for the 'Base' scenario.

4. **Scenario Addition and Parameter Modification**: For each scenario and corresponding factor, the script performs the following operations:
   - Adds the scenario to the network.
   - Sets the current scenario to the newly added scenario.
   - Begins a transaction.
   - For each 'hw_conduit' row object in the network, it multiplies the `bottom_roughness_N` by `1 + factor` and writes the row object back to the network.
   - Commits the transaction.

5. **Completion Message**: Finally, the script prints a completion message indicating the number of scenarios added and a thank you message.

## Usage

This script allows you to create scenarios with different `bottom_roughness_N` values and analyze the impact of these changes on your network.

The script is originally sourced from [ICM_Tools123](https://github.com/ngerdts7/ICM_Tools123) and has been edited by RED + CoPilot.