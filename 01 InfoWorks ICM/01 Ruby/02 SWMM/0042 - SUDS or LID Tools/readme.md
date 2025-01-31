# Clear SUDS Control Data Script for InfoWorks ICM

This script clears Sustainable Urban Drainage Systems (SUDS) control data from all subcatchments in an InfoWorks ICM model network.

## How it Works

1. The script first accesses the current network and records the start time.

2. It then begins a transaction to make changes to the network.

3. The script retrieves all subcatchments in the network.

4. For each subcatchment, it sets the size of the `suds_controls` field to 0, effectively clearing the SUDS control data. It then writes the changes to the subcatchment.

5. After all subcatchments have been processed, the script commits the transaction, applying the changes to the network.

6. Finally, it records the end time and calculates the net time taken to run the script. It prints this time to the console.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically clear the SUDS control data from all subcatchments in the network and print the time taken to run the script.

![Alt text](<Network Modification Script.png>)