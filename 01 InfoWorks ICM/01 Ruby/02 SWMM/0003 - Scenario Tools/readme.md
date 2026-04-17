# Scenario Deletion Script for InfoWorks ICM

This script deletes all scenarios in an InfoWorks ICM model network, except for the base scenario.

## How it Works

1. The script first accesses the current network.

2. It then loops through each scenario in the network. For each scenario that is not the base scenario, it deletes the scenario.

3. After all scenarios have been processed, the script prints a confirmation message to the console.

![Alt text](<Scenario Deletion Script for InfoWorks ICM.png>)

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically delete all scenarios except for the base scenario and print a confirmation message.