# Set river reach section ends to bank level

This script is designed to update the elevation data (or 'Z' values) of sections within each river reach in a network. These sections are defined by specific markers along the left and right banks of the river.

## How it Works

1. The script first accesses the current network of river reaches and begins a transaction. This means that all changes made will be either fully applied or completely rolled back, ensuring data consistency.
2. It then goes through each river reach in the network.
3. For each river reach, it creates a temporary working hash (a type of data structure) to store the elevation values for each marked section along both banks.
4. It then updates the 'Z' value for each section in the river reach according to the values in the working hash. This is done for the first section, any intermediate sections, and the last section.
5. Once all sections in a river reach have been updated, the changes are written to the river reach object.
6. After every river reach has been processed, the transaction is committed, meaning all changes made during the transaction are applied to the network.