# InfoWorks ICM Scenarios Creation Script

This script creates multiple scenarios in an InfoWorks ICM model network.

## How it Works

1. The script first accesses the current network.

2. It then defines an array of scenario names. Each scenario name represents a different modeling scenario to be added to the network.

3. The script iterates over each scenario name in the array. For each scenario name, it adds a new scenario to the network with that name. The description and folder for the new scenario are left empty.

4. After all scenarios have been added, the script prints a thank you message.

Scenario SF484_IA_10mm has been added successfully.
Scenario S456__IA_10mm has been added successfully.
Scenario SF284_IA_10mm has been added successfully.
Scenario SF484_IA_10mm_100ImPerv has been added successfully.
Scenario S456__IA_10mm_100ImPerv has been added successfully.
Scenario SF284__IA_10mm_100ImPerv has been added successfully.
Thank you for using Ruby in ICM InfoWorks

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically create the defined scenarios in the network and print a confirmation message for each scenario. After all scenarios have been created, it will print a thank you message.