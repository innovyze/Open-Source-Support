# Subcatchment Duplication Script for InfoWorks ICM

This script duplicates selected subcatchments in an InfoWorks ICM model network and appends a specified suffix to the ID of each new subcatchment.

## How it Works

1. The script first sets a list of suffixes that will be appended to the IDs of the new subcatchments.

2. It then accesses the current network and initializes counters for the number of original selected subcatchments and the number of new subcatchments added.

3. The script loops through all subcatchments in the network. For each subcatchment that is selected, it increments the counter for original selected subcatchments.

4. For each suffix in the list of suffixes, the script begins a transaction, creates a new subcatchment object, and sets its ID to the ID of the original subcatchment with the suffix appended.

5. The script then loops through each field in the new subcatchment object. For each field that is not the subcatchment ID, it copies the value from the original subcatchment.

6. After all fields have been copied, the script increments the counter for new subcatchments added, writes the changes to the new subcatchment object, and commits the transaction.

7. After all selected subcatchments have been processed, the script prints the number of original selected subcatchments and the number of new subcatchments added.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM with some subcatchments selected. The script will automatically duplicate each selected subcatchment for each suffix in the list, append the suffix to the ID of each new subcatchment, and print the number of original selected subcatchments and new subcatchments added.

![Alt text](diagram(2).png)